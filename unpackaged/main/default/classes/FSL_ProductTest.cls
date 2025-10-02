@IsTest
public class FSL_ProductTest {
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_Dao_NotNull() {

        Test.startTest();
        FSL_Product.IProductDAO dao = new FSL_Product.ProductDAO();
        Test.stopTest();

        System.assertNotEquals( null, dao );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
        List<Product2> products = FSL_DataFactory.createProducts();
        for(Product2 p:products){
            p.Name='TW - TOW MILEAGE';
        }
        update products;
    }

    @IsTest
    public static void testProductDAO_FetchProductsByProductName_DatabaseReturnsRecords_CorrectNumberOfRecordsReturned() {
        createDaoData();
    	FSL_Product.IProductDAO dao = new FSL_Product.ProductDAO();
        String productName = 'TW - TOW MILEAGE';
        String productCode = 'TW' ; 

        List<Product2>getProducts=dao.fetchProductsByProductName( new Set<String> { productName } );

        List<Product2>getProductsByCode=dao.fetchProductsByProductCode( new Set<String> { productCode } );

        System.assertEquals( false, getProducts.isEmpty() );
        System.assertEquals( productName, getProducts[0].Name );

        System.assertEquals( false, getProductsByCode.isEmpty() );
        System.assertEquals( productCode, getProductsByCode[0].PRODUCTCODE );
    }

    @IsTest
    public static void testProductDAO_FetchProductsByProductName_DatabaseReturnsNoRecords_InCorrectNumberOfRecordsReturned() {
        createDaoData();
    	FSL_Product.IProductDAO dao = new FSL_Product.ProductDAO();
        String productName = 'Non-existent product name';

        List<Product2>getProducts = dao.fetchProductsByProductName( new Set<String> { productName } );

        System.assert( getProducts.isEmpty() );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testProductService_GetProduct_DaoReturnsItems_FirstItemReturned() {
        ProductDAOMock dao = new ProductDAOMock();
        FSL_Product.IProductService service = new FSL_Product.ProductService( dao );

        String productName = 'Product Name 2';
        String productCode = 'PN2';
        Product2 prod1 = new Product2( Id = dao.Builder.getMockId(), Name = 'Product Name 1' );
        Product2 prod2 = new Product2( Id = dao.Builder.getMockId(), Name = productName ,PRODUCTCODE = productCode  );
        Product2 prod3 = new Product2( Id = dao.Builder.getMockId(), Name = 'Product Name 3' );
        dao.products.put( prod1.Id, prod1 );
        dao.products.put( prod2.Id, prod2 );
        dao.products.put( prod3.Id, prod3 );

        Test.startTest();
        Product2 actual = service.getProduct( productName );
        Product2 actualByCode = service.getProductByCode( productCode );
        Test.stopTest();

        System.assertEquals( prod2, actual );
        System.assertEquals( productCode, actualByCode.ProductCode );
    }

    @IsTest
    public static void testProductService_GetProduct_DaoReturnsNoRecords_Null() {
        ProductDAOMock dao = new ProductDAOMock();
        FSL_Product.IProductService service = new FSL_Product.ProductService( dao );

        String productName = 'Different Product Name';
        Product2 prod1 = new Product2( Id = dao.Builder.getMockId(), Name = 'Product Name 1' );
        Product2 prod2 = new Product2( Id = dao.Builder.getMockId(), Name = 'Product Name 2' );
        Product2 prod3 = new Product2( Id = dao.Builder.getMockId(), Name = 'Product Name 3' );
        dao.products.put( prod1.Id, prod1 );
        dao.products.put( prod2.Id, prod2 );
        dao.products.put( prod3.Id, prod3 );

        Test.startTest();
        Product2 actual = service.getProduct( productName );
        Test.stopTest();

        System.assertEquals( null, actual );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType PRODUCT_TYPE = Product2.getSObjectType();
    public class ProductDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Product.IProductDAO {
        public Map<Id, Product2> products;
        public Boolean isSuccess = true;
        
        public ProductDAOMock() {
            super( new Map<Id, Product2>(), PRODUCT_TYPE );
            this.products = (Map<Id, Product2>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ProductDAOMock' );
            }
        }

        public List<Product2> fetchProductsByProductName( Set<String> productNames ) {
            isQueryException();
            List<Product2> result = new List<Product2>();
            for( Product2 product : products.values() ) {
                if( productNames.contains( product.Name ) ) {
                    result.add( product );
                }
            }
            return result;
        }

        public List<Product2> fetchProductsByProductCode( Set<String> productCodes ) {
            isQueryException();
            List<Product2> result = new List<Product2>();
            for( Product2 product : products.values() ) {
                if( productCodes.contains( product.ProductCode ) ) {
                    result.add( product );
                }
            }
            return result;
        }
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ProductServiceMock implements FSL_Product.IProductService {
        public Boolean throwsException = false;
        
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ProductServiceMock' );
            }
        }

        public Integer getProductCallCount = 0;
        public Product2 getProductReturnValue = null;
        public Product2 getProduct( String productName ) {
            getProductCallCount++;
            throwExceptionIfConfigured();
            return getProductReturnValue;
        }
        public Integer getProductByCodeCallCount = 0;
        public Product2 getProductByCodeReturnValue = null;
        public Product2 getProductByCode( String productName ) {
            getProductByCodeCallCount++;
            throwExceptionIfConfigured();
            return getProductByCodeReturnValue;
        }
    }

    @isTest
    public static void testProductServiceMock_GetProduct_NoException_CorrectValueReturnedAndCallCountIncremented() {
        ProductServiceMock service = new ProductServiceMock();
        Product2 expectedDefaultValue = null;
        Product2 expectedUpdatedValue = new Product2();

        System.assertEquals( 0, service.getProductCallCount );

        Test.startTest();        
        Product2 actualDefaultValue = service.getProduct( null );
        Integer callCount1 = service.getProductCallCount;

        service.getProductReturnValue = expectedUpdatedValue;
        Product2 actualUpdatedValue = service.getProduct( null );
        Integer callCount2 = service.getProductCallCount;
        Test.stopTest();

        System.assertEquals( expectedDefaultValue, actualDefaultValue );
        System.assertEquals( expectedUpdatedValue, actualUpdatedValue );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @isTest
    public static void testProductServiceMock_GetProduct_Exception_CallCountIncrementedAndExceptionThrown() {
        ProductServiceMock service = new ProductServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.getProductCallCount );

        Test.startTest();
        try {
            service.getProduct( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.getProductCallCount );
        System.assertNotEquals( null, ex );
    }
}