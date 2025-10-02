/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 07-02-2022
 * @last modified by  : Clement Shiu
**/
public class FSL_ServiceLineItem {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IServiceLineItemService createService();
    }

    public class Factory implements IFactory {
        public IServiceLineItemService createService() {
            IServiceLineItemDAO dao = createDAO();
            FSL_Product.IProductService productService = new FSL_Product.Factory().createService();
            return new ServiceLineItemService(dao, productService);
        }

        private IServiceLineItemDAO createDAO() {
            return new ServiceLineItemDAO();
        }

    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IServiceLineItemDAO extends FSL_DAO.DmlInterface {
        List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrders(Set<Id> workOrders);
        List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrderAndProductCode(Id workOrderId, String productCode);
    }

    public class ServiceLineItemDAO extends FSL_DAO.DmlBase implements IServiceLineItemDAO {
        public List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrders(Set<Id> workOrders) {
            return [SELECT Id, Work_Order__c, Product__r.ProductCode, Unit__c, Unit_Price__c
                    FROM FSL_Service_Line_Item__c
                    WHERE Work_Order__c IN:workOrders];
        }

        public List<FSL_Service_Line_Item__c> fetchServiceLineItemForWorkOrderAndProductCode(Id workOrderId, String productCode){
            return [SELECT Id, Work_Order__c, Product__r.ProductCode, Unit__c, Unit_Price__c
                    FROM FSL_Service_Line_Item__c
                    WHERE Work_Order__c = :workOrderId AND Product__r.ProductCode = :productCode];
        }

    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IServiceLineItemService{
        void createServiceLineItem(Id workOrderId, Integer unit, String productName);
        boolean doesServiceLineItemForWorkOrderAndProductCodeExist(Id workOrderId, String productCode);
        void deleteTowServiceLineItemsForWorkOrders(Set<Id> workOrderIds);
        void createOrUpdateServiceLineItemForProductCode(Id workOrderId, Integer units, Decimal unitCost, String productCode);
    }

    public class ServiceLineItemService implements IServiceLineItemService{
        private IServiceLineItemDAO dao;
        private FSL_Product.IProductService productService;
        public ServiceLineItemService(IServiceLineItemDAO dao, FSL_Product.IProductService productService){
            this.dao = dao;
            this.productService = productService;
        }

        public void createServiceLineItem(Id WorkOrderId, Integer unit, String productName){
            System.debug(LoggingLevel.DEBUG, 'FSL_ServiceLineItem.ServiceLineItem.createServiceLineItem: Enter - WorkOrderId = [' + workOrderId + ']');
            try{
                // List<FSL_Service_Line_Item__c> serviceLineItems = dao.fetchServiceLineItemForWorkOrders( new Set<Id>{ workOrderId } );
                Product2 product = productService.getProduct(productName);
                if (product != null){
                    FSL_Service_Line_Item__c c = FSL_DataFactory.createServiceLineItems(workOrderId, null, unit, product.Id);
                    dao.insertRecords(new List<FSL_Service_Line_Item__c>{ c });
                }
            } catch (Exception ex){
                System.debug(LoggingLevel.ERROR, 'FSL_ServiceLineItem.ServiceLineItem.createServiceLineItem: Exception = [' + ex.getMessage() + ']');
            }
        }

        public void createOrUpdateServiceLineItemForProductCode(Id WorkOrderId, Integer units, Decimal unitCost, String productCode){
            try{
                Product2 product = productService.getProductByCode(productCode);
                if (product != null){
                 
                    if (doesServiceLineItemForWorkOrderAndProductCodeExist(workOrderId, productCode)){
                        FSL_Service_Line_Item__c serviceLineItem = findMatchingServiceLineItem(workOrderId, productCode);
                        if ( serviceLineItem != null ) {
                            serviceLineItem.Unit__c = units;
                            serviceLineItem.Cost__c = unitCost;
                            dao.updateRecords(new List<FSL_Service_Line_Item__c>{ serviceLineItem });
                        }
                    } else{
                        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c(Product__c = product.Id, Work_Order__c = WorkOrderId, Unit__c = units, Cost__c = unitCost);
                        dao.insertRecords(new List<FSL_Service_Line_Item__c>{ serviceLineItem });
                    }
                }
            } catch (Exception ex){
                System.debug(LoggingLevel.ERROR, 'FSL_ServiceLineItem.ServiceLineItem.createServiceLineItem: Exception = [' + ex.getMessage() + ']');
            }
        }

        private FSL_Service_Line_Item__c  findMatchingServiceLineItem(Id workOrderId, String productCode) {
            List<FSL_Service_Line_Item__c> svcLineItems = dao.fetchServiceLineItemForWorkOrderAndProductCode(workOrderId, productCode);
            return (svcLineItems != null &&  svcLineItems.size() > 0) ? svcLineItems.get(0) : null;
        }

        public boolean doesServiceLineItemForWorkOrderAndProductCodeExist(Id workOrderId, String productCode){
            boolean exists = false;
            List<FSL_Service_Line_Item__c> svcLineItems = dao.fetchServiceLineItemForWorkOrderAndProductCode(workOrderId, productCode);
            for (FSL_Service_Line_Item__c svcLI : svcLineItems){
                if (!(String.isBlank(svcLI.Product__c) || String.isBlank(svcLI.Product__r.ProductCode))){
                    if (svcLI.Product__r.ProductCode.startsWith(TOW_PRODUCT_CODE_PREFIX)){
                        exists = true;
                    }
                }
            }

            return exists;
        }

        private String TOW_PRODUCT_CODE_PREFIX = 'TW';
        public void deleteTowServiceLineItemsForWorkOrders(Set<Id> workOrderIds){
            List<FSL_Service_Line_Item__c> svcLineItems = dao.fetchServiceLineItemForWorkOrders(workOrderIds);

            List<FSL_Service_Line_Item__c> deletableSvcLineItems = new List<FSL_Service_Line_Item__c>();
            for (FSL_Service_Line_Item__c svcLI : svcLineItems){
                if (!(String.isBlank(svcLI.Product__c) || String.isBlank(svcLI.Product__r.ProductCode))){
                    if (svcLI.Product__r.ProductCode.startsWith(TOW_PRODUCT_CODE_PREFIX)){
                        deletableSvcLineItems.add(svcLI);
                    }
                }
            }
            if (deletableSvcLineItems.size() > 0){
                dao.deleteRecords(deletableSvcLineItems);
            }
        }

    }

}