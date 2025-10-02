@isTest
public class FSL_ServiceLineItemTest {
     // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_ServiceLineItem.IFactory factory = new FSL_ServiceLineItem.Factory();

        Test.startTest();
        FSL_ServiceLineItem.IServiceLineItemService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
        Integer recordCount = 1;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
         List<Product2> products = FSL_DataFactory.createProducts();
        for(Product2 p:products){
            p.Name='TW - TOW MILEAGE';
            p.ProductCode = 'TW';
        }
        update products;

        List<FSL_Service_Line_Item__c> serviceLineItems = new List<FSL_Service_Line_Item__c>();
        for( Integer i = 0; i < recordCount; ++i ) {
            serviceLineItems.add( new FSL_Service_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id ));
            serviceLineItems.add( new FSL_Service_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id));
            serviceLineItems.add( new FSL_Service_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id));
        }
        insert serviceLineItems;
    }

    @IsTest
    public static void testServiceLineItemDAO_fetchServiceLineItemForWorkOrders_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_ServiceLineItem.IServiceLineItemDAO dao = new FSL_ServiceLineItem.ServiceLineItemDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];

        System.assertEquals( 1, insertedWorkOrders.size() );
        Set<Id> workOrderIds = new Set<Id>{ insertedWorkOrders[0].Id, insertedWorkOrders[0].Id };
        
        Test.startTest();
        List<FSL_Service_Line_Item__c> serviceLineItems = dao.fetchServiceLineItemForWorkOrders( workOrderIds );
        Test.stopTest();

        System.assertEquals( 3, serviceLineItems.size() );
        System.assertEquals( insertedWorkOrders[0].Id, serviceLineItems[0].Work_Order__c );
        System.assertEquals( insertedWorkOrders[0].Id, serviceLineItems[1].Work_Order__c );
     
    }

    @IsTest
    public static void testServiceLineItemDAO_fetchServiceLineItemForWorkOrderAndProductCode_CorrectNumberOfRecordsReturned() {
        createDaoData();

        Test.startTest();
        FSL_ServiceLineItem.IServiceLineItemDAO dao = new FSL_ServiceLineItem.ServiceLineItemDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];
        List<FSL_Service_Line_Item__c> serviceLineItems = dao.fetchServiceLineItemForWorkOrderAndProductCode( insertedWorkOrders[0].Id, 'TW' );
        Test.stopTest();

        System.assertEquals( 3, serviceLineItems.size(), 'There should be 3 Service Line Items with product code of TW' );
    }    

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testServiceLineItemService_createServiceLineItem_ProductServiceReturnProduct_Created() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );
        
        Product2 product = new Product2( Id = dao.Builder.getMockId( Schema.Product2.getSObjectType() ) );
        productService.getProductReturnValue = product;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createServiceLineItem( workOrderId, unit, 'TW - TOW MILEAGE' );
        Test.stopTest();

        System.assertEquals( 1, dao.serviceLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
        FSL_Service_Line_Item__c sli = dao.serviceLineItems.values()[0];
        System.assertEquals( unit, sli.Unit__c );
        System.assertEquals( workOrderId, sli.Work_Order__c );
        System.assertEquals( product.Id, sli.Product__c );
    }
    
    
    @IsTest
    public static void testServiceLineItemService_doesServiceLineItemForWorkOrderAndProductCodeExist_returnsTrue() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();
        
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'TW');
        FSL_Service_Line_Item__c sliValid =  new FSL_Service_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = workOrderId);
        sliValid.Product__r = productx;
        Map<Id, FSL_Service_Line_Item__c> mapSLI = new  Map<Id, FSL_Service_Line_Item__c>();
        mapSLI.put(sliValid.Id, sliValid);
        dao.serviceLineItems = mapSLI;

        Test.startTest();
        Boolean returnValue = service.doesServiceLineItemForWorkOrderAndProductCodeExist( workOrderId, 'TW' );
        Test.stopTest();

        System.assertEquals( 1, dao.serviceLineItems.size(), 'There should only be one Service Line Item with product code TW' );
        System.assertEquals( returnValue, true, 'Service Line Item with product code TW should exist' );
    }

    @IsTest
    public static void testServiceLineItemService_doesServiceLineItemForWorkOrderAndProductCodeExist_returnsFalse() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();
        
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'XX');
        FSL_Service_Line_Item__c sliValid =  new FSL_Service_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = workOrderId);
        sliValid.Product__r = productx;
        Map<Id, FSL_Service_Line_Item__c> mapSLI = new  Map<Id, FSL_Service_Line_Item__c>();
        mapSLI.put(sliValid.Id, sliValid);
        dao.serviceLineItems = mapSLI;

        Test.startTest();
        Boolean returnValue = service.doesServiceLineItemForWorkOrderAndProductCodeExist( workOrderId, 'TW' );
        Test.stopTest();

        System.assertEquals( 1, dao.serviceLineItems.size(), 'There should only be one Service Line Item with product code XX' );
        System.assertEquals( returnValue, false, 'Service Line Item with product code TW should not exist' );
    }

    @IsTest
    public static void testServiceLineItemService_createServiceLineItem_ProductServiceReturnsNull_NotCreated() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );
        
        productService.getProductReturnValue = null;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createServiceLineItem( workOrderId, unit, 'TW - TOW MILEAGE' );
        Test.stopTest();

        System.assertEquals( 0, dao.serviceLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
    }
    
    @IsTest
    public static void testServiceLineItemService_createServiceLineItem_ProductServiceThrowsException_NotCreated() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );
        
        productService.throwsException = true;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createServiceLineItem( workOrderId, unit, 'TW - TOW MILEAGE' );
        Test.stopTest();

        System.assertEquals( 0, dao.serviceLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
    }


    @IsTest
    public static void testServiceLineItemService_DeleteTowServiceLineItemsForWorkOrders_InvalidInputs_NoExceptions() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();


        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );

        // Create some service line items matched to a WorkOrder and populate the MockDAO

        FSL_WorkOrderTest.WorkOrderDAOMock woDao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        WorkOrder w1 = new WorkOrder( Id = woDao.Builder.getMockId() );

        FSL_Service_Line_Item__c nullProdSli =  new FSL_Service_Line_Item__c(Product__c = null, Id = dao.Builder.getMockId(), Work_Order__c = w1.Id, Unit__c = 20 ,Cost__c = 5);

        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = null);
        FSL_Service_Line_Item__c blankProCodeSli =  new FSL_Service_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = w1.Id, Unit__c = 20 ,Cost__c = 5);

        Map<Id, FSL_Service_Line_Item__c> mapSLI = new  Map<Id, FSL_Service_Line_Item__c>();
        
        mapSLI.put(nullProdSli.Id, nullProdSli);
        mapSLI.put(blankProCodeSli.Id, blankProCodeSli);
        dao.serviceLineItems = mapSLI;

        Set<Id> woIdSet = new Set<Id>();
        woIdSet.add(w1.Id);

        Exception exCaught = null;
        try {
            service.deleteTowServiceLineItemsForWorkOrders(woIdSet);
        } catch (Exception ex) {
            exCaught = ex;
        }
        
        System.assertEquals(exCaught, null);

        
    }

    @IsTest
    public static void testServiceLineItemService_DeleteTowServiceLineItemsForWorkOrders_MatchFound_Deleted() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();


        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );

        // Create some service line items matched to a WorkOrder and populate the MockDAO

        FSL_WorkOrderTest.WorkOrderDAOMock woDao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        WorkOrder w1 = new WorkOrder( Id = woDao.Builder.getMockId() );

        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'TWXyz');
        FSL_Service_Line_Item__c sliValid =  new FSL_Service_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = w1.Id, Unit__c = 20 ,Cost__c = 5);
        sliValid.Product__r = productx;
        
        Map<Id, FSL_Service_Line_Item__c> mapSLI = new  Map<Id, FSL_Service_Line_Item__c>();
        
        mapSLI.put(sliValid.Id, sliValid);

        dao.serviceLineItems = mapSLI;

        Set<Id> woIdSet = new Set<Id>();
        woIdSet.add(w1.Id);

        System.assertEquals(dao.serviceLineItems.size(), 1);
        Exception exCaught = null;
        try {
            service.deleteTowServiceLineItemsForWorkOrders(woIdSet);
        } catch (Exception ex) {
            exCaught = ex;
        }
        
        System.assertEquals(exCaught, null);
        
    }

    @IsTest
    public static void testServiceLineItemService_DeleteTWLineItemsForWorkOrdersResolvedWithoutTow_MatchNotFound_NoDeletions() {
        ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();


        FSL_ServiceLineItem.IServiceLineItemService service = new FSL_ServiceLineItem.ServiceLineItemService( dao, productService );

        // Create some service line items matched to a WorkOrder and populate the MockDAO

        FSL_WorkOrderTest.WorkOrderDAOMock woDao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        WorkOrder w1 = new WorkOrder( Id = woDao.Builder.getMockId() );

        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'TWXyz');
        FSL_Service_Line_Item__c sliValid =  new FSL_Service_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = w1.Id, Unit__c = 20 ,Cost__c = 5);

        Map<Id, FSL_Service_Line_Item__c> mapSLI = new  Map<Id, FSL_Service_Line_Item__c>();
        
        dao.serviceLineItems = mapSLI;

        Set<Id> woIdSet = new Set<Id>();
        woIdSet.add(w1.Id);

        Exception exCaught = null;
        try {
            service.deleteTowServiceLineItemsForWorkOrders(woIdSet);
        } catch (Exception ex) {
            exCaught = ex;
        }
        
        System.assertEquals(exCaught, null);
        
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ServiceLineItem.IFactory {
        public FSL_ServiceLineItem.IServiceLineItemService createService() {
            ServiceLineItemDAOMock dao = new ServiceLineItemDAOMock();
            FSL_Product.IProductService productService = new FSL_ProductTest.ProductServiceMock();
            return new ServiceLineItemServiceMock( );
        }
    }


    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType PRODUCT_TYPE = FSL_Service_Line_Item__c.getSObjectType();
    public class ServiceLineItemDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ServiceLineItem.IServiceLineItemDAO {
        public Map<Id, FSL_Service_Line_Item__c> serviceLineItems;
        public Boolean isSuccess = true;
        
        public ServiceLineItemDAOMock() {
            super( new Map<Id, FSL_Service_Line_Item__c>(), PRODUCT_TYPE );
            this.serviceLineItems = (Map<Id, FSL_Service_Line_Item__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ServiceLineItemDAOMock' );
            }
        }

        public List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrders( Set<Id> workOrders ) {
            isQueryException();
            List<FSL_Service_Line_Item__c> result = new List<FSL_Service_Line_Item__c>();
            for( FSL_Service_Line_Item__c sli : serviceLineItems.values() ) {
                if( workOrders.contains( sli.Work_Order__c ) ) {
                    result.add( sli );
                }
            }
            return result;
        }

        public List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrderAndProductCode( Id workOrderId, String productCode ) {
            isQueryException();
            List<FSL_Service_Line_Item__c> result = new List<FSL_Service_Line_Item__c>();
            for( FSL_Service_Line_Item__c sli : serviceLineItems.values() ) {
                if( (workOrderId == sli.Work_Order__c) && (productCode.equals(sli.product__r.productcode)) ) {
                    result.add( sli );
                }
            }
            return result;
        }
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ServiceLineItemServiceMock implements FSL_ServiceLineItem.IServiceLineItemService {

        public Integer createServiceLineItemcallCount = 0;
        public Integer createOrUpdateServiceLineItemForProductCodeCallCount = 0;
        public Integer deleteTowServiceLineItemsForWorkOrdersCallCount = 0;
        public Integer doesServiceLineItemForWorkOrderAndProductCodeExistCallCount = 0;
        public Boolean doesServiceLineItemForWorkOrderAndProductCodeExistReturnValue = false;
        public Boolean throwsException = false;

        public void createServiceLineItem(Id WorkOrderId, Integer unit, String productName ) {
            ++createServiceLineItemcallCount;
            throwExceptionIfConfigured();
        }

        public void createOrUpdateServiceLineItemForProductCode(Id WorkOrderId, Integer units, Decimal unitCost, String productCode ) {
            ++createOrUpdateServiceLineItemForProductCodeCallCount;
            throwExceptionIfConfigured();
        }
        
        public boolean doesServiceLineItemForWorkOrderAndProductCodeExist( Id workOrderId, String productCode ) {
            ++doesServiceLineItemForWorkOrderAndProductCodeExistCallCount;
            throwExceptionIfConfigured();
            return doesServiceLineItemForWorkOrderAndProductCodeExistReturnValue;
        }

        public void deleteTowServiceLineItemsForWorkOrders(Set<Id> workOrders) {
            ++deleteTowServiceLineItemsForWorkOrdersCallCount;
            throwExceptionIfConfigured();
        }

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in FSL_ServiceLineItemTest.ServiceLineItemServiceMock' );
            }
        }
    } 

    @IsTest
    public static void testServiceLineItemServiceMock_CreateServiceLineItem_NoException_CallCountIncremented() {
        ServiceLineItemServiceMock service = new ServiceLineItemServiceMock();

        Test.startTest();
        Integer callCount0 = service.createServiceLineItemcallCount;

        service.createServiceLineItem( null, null, null );
        Integer callCount1 = service.createServiceLineItemcallCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
    }

    @IsTest
    public static void testServiceLineItemServiceMock_CreateServiceLineItem_Exception_ExceptionRaised() {
        ServiceLineItemServiceMock service = new ServiceLineItemServiceMock();

        Exception exThrown = null;
        service.throwsException = true;
        Test.startTest();
    
        try {
            service.createServiceLineItem( null, null, null );
        }
        catch (EXception ex) {
            exThrown = ex;
        }
        Test.stopTest();
        System.assertNotEquals( null, exThrown );
    }

    @IsTest
    public static void testServiceLineItemServiceMock_DeleteTWLineItemsForWorkOrdersResolvedWithoutTow_NoException_CallCountIncremented() {
        ServiceLineItemServiceMock service = new ServiceLineItemServiceMock();

        Test.startTest();
        Integer callCount0 = service.deleteTowServiceLineItemsForWorkOrdersCallCount;

        service.deleteTowServiceLineItemsForWorkOrders( null);
        Integer callCount1 = service.deleteTowServiceLineItemsForWorkOrdersCallCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
    }

    @IsTest
    public static void testServiceLineItemServiceMock_DeleteTWLineItemsForWorkOrdersResolvedWithoutTow_Exception_ExceptionRaised() {
        ServiceLineItemServiceMock service = new ServiceLineItemServiceMock();

        Exception exThrown = null;
        service.throwsException = true;
        Test.startTest();
    
        try {
            service.deleteTowServiceLineItemsForWorkOrders( null);
        }
        catch (EXception ex) {
            exThrown = ex;
        }
        Test.stopTest();
        System.assertNotEquals( null, exThrown );
    }

}