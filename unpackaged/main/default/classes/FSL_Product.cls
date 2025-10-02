/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 07-02-2022
 * @last modified by  : Clement Shiu
**/
public class FSL_Product {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IProductService createService();
    }

    public class Factory implements IFactory {
        public IProductService createService() {
            IProductDAO dao = createDAO();
            return new ProductService( dao );
        }

        private IProductDAO createDAO() {
            return new ProductDAO();
        }
    }
    
    // *********************************************
    // * DAO
    // *********************************************
    public interface IProductDAO extends FSL_DAO.DmlInterface {
        List<Product2> fetchProductsByProductName( Set<String> productNames );
        List<Product2> fetchProductsByProductCode( Set<String> productCodes );
    }
    
    public class ProductDAO extends FSL_DAO.DmlBase implements IProductDAO{
        public List<Product2> fetchProductsByProductName( Set<String> productNames ) {
            return [SELECT id,Name 
                    FROM Product2 
                    WHERE name IN :productNames];
        }
        public List<Product2> fetchProductsByProductCode( Set<String> productCodes ) {
            return [SELECT id,Name, ProductCode 
                    FROM Product2 
                    WHERE ProductCode IN :productCodes];
        }
    }
    
    // *********************************************
    // * Service
    // *********************************************
    public interface IProductService {
        Product2 getProduct( String productName );
        Product2 getProductByCode( String productCode );
    }

    public class ProductService implements IProductService {
        private IProductDAO dao;

        public ProductService( IProductDAO dao ) {
            this.dao = dao;
        }

        public Product2 getProduct( String productName ) {
            Product2 result = null;
            List<Product2> products = dao.fetchProductsByProductName( new Set<String>{ productName } );
            if (!products.isEmpty()) {
                 result = products[0];
            }
            return result;
        }

        public Product2 getProductByCode( String productCode ) {
            Product2 result = null;
            List<Product2> products = dao.fetchProductsByProductCode( new Set<String>{ productCode } );
            if (!products.isEmpty()) {
                result = products[0];
           }
           return result;
        }
    }
}