@isTest
public class FSL_CalculatedMileageLineItemTest {
     // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_CalculatedMileageLineItem.IFactory factory = new FSL_CalculatedMileageLineItem.Factory();

        Test.startTest();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = factory.createService();
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
            p.Name='CT - Calculated Tow';
            p.ProductCode = 'CT';
        }
        update products;

        List<FSL_Calculated_Mileage_Line_Item__c> calculatedMileageLineItems = new List<FSL_Calculated_Mileage_Line_Item__c>();
        for( Integer i = 0; i < recordCount; ++i ) {
            calculatedMileageLineItems.add( new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id ));
            calculatedMileageLineItems.add( new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id));
            calculatedMileageLineItems.add( new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[i].Id, Product__c = products[0].Id));
        }
        insert calculatedMileageLineItems;
    }

    @IsTest
    public static void testCalculatedMileageLineItemDAO_fetchCalculatedMileageLineItemForWorkOrderAndProductCode_CorrectNumberOfRecordsReturned() {
        createDaoData();

        Test.startTest();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemDAO dao = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];
        List<FSL_Calculated_Mileage_Line_Item__c> calculatedMileageLineItems = dao.fetchCalculatedMileageLineItemForWorkOrderAndProductCode( insertedWorkOrders[0].Id, 'CT' );
        Test.stopTest();

        System.assertEquals( 3, calculatedMileageLineItems.size(), 'There should be 3 Calculated Mileage Line Items with product code of CT' );
    }    

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testCalculatedMileageLineItemService_createCalculatedMileageLineItem_ProductServiceReturnProduct_Created() {
        CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemService( dao, productService );
        
        Product2 product = new Product2( Id = dao.Builder.getMockId( Schema.Product2.getSObjectType() ) );
        productService.getProductReturnValue = product;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createCalculatedMileageLineItem( workOrderId, unit, 'CT - Calculated Tow' );
        Test.stopTest();

        System.assertEquals( 1, dao.calculatedMileageLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
        FSL_Calculated_Mileage_Line_Item__c sli = dao.calculatedMileageLineItems.values()[0];
        System.assertEquals( unit, sli.Unit__c );
        System.assertEquals( workOrderId, sli.Work_Order__c );
        System.assertEquals( product.Id, sli.Product__c );
    }
    
    
    @IsTest
    public static void testCalculatedMileageLineItemService_doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist_returnsTrue() {
        CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemService( dao, productService );
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();
        
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'CT');
        FSL_Calculated_Mileage_Line_Item__c sliValid =  new FSL_Calculated_Mileage_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = workOrderId);
        sliValid.Product__r = productx;
        Map<Id, FSL_Calculated_Mileage_Line_Item__c> mapSLI = new  Map<Id, FSL_Calculated_Mileage_Line_Item__c>();
        mapSLI.put(sliValid.Id, sliValid);
        dao.calculatedMileageLineItems = mapSLI;

        Test.startTest();
        Boolean returnValue = service.doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist( workOrderId, 'CT' );
        Test.stopTest();

        System.assertEquals( 1, dao.calculatedMileageLineItems.size(), 'There should only be one CalculatedMileage Line Item with product code CT' );
        System.assertEquals( returnValue, true, 'CalculatedMileage Line Item with product code CT should exist' );
    }

    @IsTest
    public static void testCalculatedMileageLineItemService_doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist_returnsFalse() {
        CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemService( dao, productService );
        FSL_ProductTest.ProductDAOMock prodDao = new FSL_ProductTest.ProductDAOMock();
        
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Product2 productx = new Product2( Id = prodDao.Builder.getMockId(), ProductCode = 'XX');
        FSL_Calculated_Mileage_Line_Item__c sliValid =  new FSL_Calculated_Mileage_Line_Item__c(Product__c = productx.Id, Id = dao.Builder.getMockId(), Work_Order__c = workOrderId);
        sliValid.Product__r = productx;
        Map<Id, FSL_Calculated_Mileage_Line_Item__c> mapSLI = new  Map<Id, FSL_Calculated_Mileage_Line_Item__c>();
        mapSLI.put(sliValid.Id, sliValid);
        dao.calculatedMileageLineItems = mapSLI;

        Test.startTest();
        Boolean returnValue = service.doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist( workOrderId, 'CT' );
        Test.stopTest();

        System.assertEquals( 1, dao.calculatedMileageLineItems.size(), 'There should only be one CalculatedMileage Line Item with product code XX' );
        System.assertEquals( returnValue, false, 'CalculatedMileage Line Item with product code CT should not exist' );
    }

    @IsTest
    public static void testCalculatedMileageLineItemService_createCalculatedMileageLineItem_ProductServiceReturnsNull_NotCreated() {
        CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemService( dao, productService );
        
        productService.getProductReturnValue = null;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createCalculatedMileageLineItem( workOrderId, unit, 'CT - Calculated Tow' );
        Test.stopTest();

        System.assertEquals( 0, dao.calculatedMileageLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
    }
    
    @IsTest
    public static void testCalculatedMileageLineItemService_createCalculatedMileageLineItem_ProductServiceThrowsException_NotCreated() {
        CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
        FSL_ProductTest.ProductServiceMock productService = new FSL_ProductTest.ProductServiceMock();
        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService service = new FSL_CalculatedMileageLineItem.CalculatedMileageLineItemService( dao, productService );
        
        productService.throwsException = true;
        Id workOrderId = dao.Builder.getMockId( WorkOrder.getSObjectType() );
        Integer unit = 18;

        Test.startTest();
        service.createCalculatedMileageLineItem( workOrderId, unit, 'CT - Calculated Tow' );
        Test.stopTest();

        System.assertEquals( 0, dao.calculatedMileageLineItems.size() );
        System.assertEquals( 1, productService.getProductCallCount );
    }


    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_CalculatedMileageLineItem.IFactory {
        public FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService createService() {
            CalculatedMileageLineItemDAOMock dao = new CalculatedMileageLineItemDAOMock();
            FSL_Product.IProductService productService = new FSL_ProductTest.ProductServiceMock();
            return new CalculatedMileageLineItemServiceMock( );
        }
    }


    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType PRODUCT_TYPE = FSL_Calculated_Mileage_Line_Item__c.getSObjectType();
    public class CalculatedMileageLineItemDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemDAO {
        public Map<Id, FSL_Calculated_Mileage_Line_Item__c> calculatedMileageLineItems;
        public Boolean isSuccess = true;
        
        public CalculatedMileageLineItemDAOMock() {
            super( new Map<Id, FSL_Calculated_Mileage_Line_Item__c>(), PRODUCT_TYPE );
            this.calculatedMileageLineItems = (Map<Id, FSL_Calculated_Mileage_Line_Item__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from CalculatedMileageLineItemDAOMock' );
            }
        }

        public List<FSL_Calculated_Mileage_Line_Item__c> fetchCalculatedMileageLineItemForWorkOrders( Set<Id> workOrders ) {
            isQueryException();
            List<FSL_Calculated_Mileage_Line_Item__c> result = new List<FSL_Calculated_Mileage_Line_Item__c>();
            for( FSL_Calculated_Mileage_Line_Item__c sli : calculatedMileageLineItems.values() ) {
                if( workOrders.contains( sli.Work_Order__c ) ) {
                    result.add( sli );
                }
            }
            return result;
        }

        public List<FSL_Calculated_Mileage_Line_Item__c> fetchCalculatedMileageLineItemForWorkOrderAndProductCode( Id workOrderId, String productCode ) {
            isQueryException();
            List<FSL_Calculated_Mileage_Line_Item__c> result = new List<FSL_Calculated_Mileage_Line_Item__c>();
            for( FSL_Calculated_Mileage_Line_Item__c sli : calculatedMileageLineItems.values() ) {
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
    public class CalculatedMileageLineItemServiceMock implements FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService {

        public Integer createCalculatedMileageLineItemcallCount = 0;
        public Integer doesCalculatedMileageLineItemForWorkOrderAndProductCodeExistCallCount = 0;
        public Boolean doesCalculatedMileageLineItemForWorkOrderAndProductCodeExistReturnValue = false;
        public Boolean throwsException = false;

        public void createCalculatedMileageLineItem(Id WorkOrderId, Integer unit, String productName ) {
            ++createCalculatedMileageLineItemcallCount;
            throwExceptionIfConfigured();
        }
        
        public boolean doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist( Id workOrderId, String productCode ) {
            ++doesCalculatedMileageLineItemForWorkOrderAndProductCodeExistCallCount;
            throwExceptionIfConfigured();
            return doesCalculatedMileageLineItemForWorkOrderAndProductCodeExistReturnValue;
        }

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in FSL_CalculatedMileageLineItemTest.CalculatedMileageLineItemServiceMock' );
            }
        }
    } 

    @IsTest
    public static void testCalculatedMileageLineItemCalculatedMileageMock_CreateServiceLineItem_NoException_CallCountIncremented() {
        CalculatedMileageLineItemServiceMock service = new CalculatedMileageLineItemServiceMock();

        Test.startTest();
        Integer callCount0 = service.createCalculatedMileageLineItemcallCount;

        service.createCalculatedMileageLineItem( null, null, null );
        Integer callCount1 = service.createCalculatedMileageLineItemcallCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
    }

    @IsTest
    public static void testCalculatedMileageLineItemServiceMock_CreateCalculatedMileageLineItem_Exception_ExceptionRaised() {
        CalculatedMileageLineItemServiceMock service = new CalculatedMileageLineItemServiceMock();

        Exception exThrown = null;
        service.throwsException = true;
        Test.startTest();
    
        try {
            service.createCalculatedMileageLineItem( null, null, null );
        }
        catch (EXception ex) {
            exThrown = ex;
        }
        Test.stopTest();
        System.assertNotEquals( null, exThrown );
    }

    /************************************************************** */
    /*  Test cases for the Flows */
    /************************************************************** */

    private static List<WorkOrder> createDaoDataForFlow(String callType, String callMileage) {
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
            workOrders[i].Status = 'Spotted';
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
        List<Product2> products = FSL_DataFactory.createProducts();

        if(callTYpe != null) {

            List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

            ServiceTerritory st = new ServiceTerritory( Name = 'Service Territory 1', 
                                                        OperatingHoursId = hours[0].Id, 
                                                        IsActive = true, 
                                                        Enable_Calculate_Mileage__c = callMileage,
                                                        city = 'ESCONDIDO',
                                                        geocodeAccuracy = 'Block',
                                                        latitude = 33.122977,
                                                        longitude = -117.091146,
                                                        postalCode = '92025',
                                                        country='United States', //As it was failing during deployement so its quick fix by sanket T.
                                                        state = 'CA',
                                                        street = '520 N QUINCE STREET #11'
                                                        );
            insert st;

            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();

            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st.Id, workOrders[0].Id, contacts[0].Id, System.now(), 1800, 'Breakdown Appointment');
            breakdownSa.ParentRecordId = workOrders[0].Id;
            breakdownSa.city = 'Escondido';
            breakdownSa.country = 'United States';
            breakdownSa.postalCode = '92025';
            breakdownSa.state = 'CA';
            breakdownSa.street = '425 N Quince St';    
            //breakdownSa.FSL__Internal_SLR_Geolocation__Latitude__s = 33.122494;
            //breakdownSa.FSL__Internal_SLR_Geolocation__Longitude__s = -117.091821;
            breakdownSa.Latitude = 33.122494;
            breakdownSa.Longitude = -117.091821;
            serviceAppointments.add( breakdownSa );
            
            if('Tow'.equals(callType)) {
                ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st.Id, workOrders[0].Id, contacts[0].Id, System.now() + 1800, 1800, 'Tow Appointment');
                towSa.ParentRecordId = workOrders[0].Id;
                towSa.city = 'Escondido';
                towSa.country = 'United States';
                towSa.postalCode = '92025';
                towSa.state = 'CA';
                towSa.street = '1157 W Misson Ave';        
                serviceAppointments.add( towSa );
            }

            insert serviceAppointments;        
        }

        return workOrders;
    }    

    /****
     * Update_Or_Insert_Service_Line_Item
     */    
    @IsTest
    public static void testInsertServiceLineItemQuantityExceeds999ShouldInsertRecordWithZero() {
        List<WorkOrder> workOrders = createDaoDataForFlow(null, 'From Service Territory');
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId', workOrders[0].Id);
        inputs.put('Quantity', 1000);
        inputs.put('ProductCode', 'CE');        

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Update_Or_Insert_Service_Line_Item', inputs);
        mySubFlow.start();

        List<FSL_Calculated_Mileage_Line_Item__c> result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        Test.stopTest();
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(0, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');        
    }

    @IsTest
    public static void testInsertServiceLineItemQuantityLessThan999ShouldInsertRecordWithQuantity() {
        List<WorkOrder> workOrders = createDaoDataForFlow(null, 'From Service Territory');
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId', workOrders[0].Id);
        inputs.put('Quantity', 50);
        inputs.put('ProductCode', 'CE');        

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Update_Or_Insert_Service_Line_Item', inputs);
        mySubFlow.start();

        List<FSL_Calculated_Mileage_Line_Item__c> result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        Test.stopTest();
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(50, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');        
    }

    @IsTest
    public static void testUpdateServiceLineItemQuantityExceeds999ShouldInsertRecordWithZero() {
        List<WorkOrder> workOrders = createDaoDataForFlow(null, 'From Service Territory');
        List<Product2> products = [SELECT Id FROM Product2 WHERE ProductCode = 'CE'];
        FSL_Calculated_Mileage_Line_Item__c cmli = new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[0].Id, Product__c = products[0].Id, Unit__c = 50 );
        insert cmli;
        List<FSL_Calculated_Mileage_Line_Item__c> result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(50, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');                
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId', workOrders[0].Id);
        inputs.put('Quantity', 1000);
        inputs.put('ProductCode', 'CE');        

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Update_Or_Insert_Service_Line_Item', inputs);
        mySubFlow.start();

        result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        Test.stopTest();
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(0, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');        
    }

    @IsTest
    public static void testUpdateServiceLineItemQuantityLessThan999ShouldInsertRecordWithQuantity() {
        List<WorkOrder> workOrders = createDaoDataForFlow(null, 'From Service Territory');
        List<Product2> products = [SELECT Id FROM Product2 WHERE ProductCode = 'CE'];
        FSL_Calculated_Mileage_Line_Item__c cmli = new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[0].Id, Product__c = products[0].Id, Unit__c = 50 );
        insert cmli;
        List<FSL_Calculated_Mileage_Line_Item__c> result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(50, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');                
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId', workOrders[0].Id);
        inputs.put('Quantity', 100);
        inputs.put('ProductCode', 'CE');        

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Update_Or_Insert_Service_Line_Item', inputs);
        mySubFlow.start();

        result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        Test.stopTest();
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(100, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.');        
    }

    /****
     * Work_Order_Calculated_Mileage_on_Cleared
     */
    @IsTest
    public static void testWorkOrderClearStatusChangeDeleteCERecord() {
        List<WorkOrder> workOrders = createDaoDataForFlow('Breakdown', 'From Service Territory');
        List<Product2> products = [SELECT Id FROM Product2 WHERE ProductCode = 'CE'];
        FSL_Calculated_Mileage_Line_Item__c cmli = new FSL_Calculated_Mileage_Line_Item__c( Work_Order__c = workOrders[0].Id, Product__c = products[0].Id, Unit__c = 50 );    
        insert cmli;    
        List<FSL_Calculated_Mileage_Line_Item__c> result = [SELECT Id, Unit__c, Product__c, Work_Order__c, Product__r.ProductCode FROM FSL_Calculated_Mileage_Line_Item__c];
        System.assertEquals(1, result.size(), 'There should be 1 Calculated Mileage after running the SubFlow.');        
        System.assertEquals(50, result[0].unit__c, 'Quantity value should be zero after running the SubFlow.'); 
        System.assertEquals('CE', result[0].Product__r.ProductCode, 'Quantity value should be zero after running the SubFlow.');                        
        Test.startTest();
        List<ServiceTerritory> sts = [select id from ServiceTerritory];
        workOrders[0].ServiceTerritoryId = sts[0].id;
        workOrders[0].Status = 'Cleared';
        workOrders[0].Resolution_Code__c = 'X001';
        update workOrders;
        result = [SELECT Id, Unit__c, Product__c, Work_Order__c FROM FSL_Calculated_Mileage_Line_Item__c];
        Test.stopTest();
        System.assertEquals(0, result.size(), 'There should be 0 Calculated Mileage after Work Order Clear.');        
    }



}