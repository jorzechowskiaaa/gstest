public class FSL_CalculatedMileageLineItem {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ICalculatedMileageLineItemService createService();
    }

    public class Factory implements IFactory {
        public ICalculatedMileageLineItemService createService() {
            ICalculatedMileageLineItemDAO dao = createDAO();
            FSL_Product.IProductService productService = new FSL_Product.Factory().createService();
            return new CalculatedMileageLineItemService( dao, productService );
        }

        private ICalculatedMileageLineItemDAO createDAO() {
            return new CalculatedMileageLineItemDAO();
        }
    }
    
    // *********************************************
    // * DAO
    // *********************************************
    public interface ICalculatedMileageLineItemDAO extends FSL_DAO.DmlInterface {
       List<FSL_Calculated_Mileage_Line_Item__c> fetchCalculatedMileageLineItemForWorkOrderAndProductCode( Id workOrderId, String productCode );
    }
    
    public class CalculatedMileageLineItemDAO extends FSL_DAO.DmlBase implements ICalculatedMileageLineItemDAO{
        public List<FSL_Calculated_Mileage_Line_Item__c> fetchCalculatedMileageLineItemForWorkOrderAndProductCode( Id workOrderId, String productCode ) {
            return [SELECT Id , Work_Order__c, Product__r.ProductCode
                    FROM FSL_Calculated_Mileage_Line_Item__c 
                    WHERE Work_Order__c = :workOrderId AND Product__r.ProductCode = :productCode];
        }        
    }
    
    // *********************************************
    // * Service
    // *********************************************
    public interface ICalculatedMileageLineItemService  {
        void createCalculatedMileageLineItem(Id WorkOrderId, Integer unit, String productName );
        boolean doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist( Id workOrderId, String productCode );
    }
    
    public class CalculatedMileageLineItemService implements ICalculatedMileageLineItemService {
        private ICalculatedMileageLineItemDAO dao;
        private FSL_Product.IProductService productService;

        public CalculatedMileageLineItemService( ICalculatedMileageLineItemDAO dao, FSL_Product.IProductService productService ) {
            this.dao = dao;
            this.productService = productService;
        }

        public void createCalculatedMileageLineItem( Id WorkOrderId, Integer unit, String productName) {
            System.debug( LoggingLevel.DEBUG, 'FSL_CalculatedMileageLineItem.CalculatedMileageLineItem.createCalculatedMileageLineItem: Enter - WorkOrderId = [' + workOrderId + ']' );
            try {
                Product2 product = productService.getProduct( productName );
                if( product != null ) {
                    FSL_Calculated_Mileage_Line_Item__c c = new FSL_Calculated_Mileage_Line_Item__c(Product__c = product.Id, Work_Order__c = WorkOrderId,Unit__c = unit);
                    dao.insertRecords( new List<FSL_Calculated_Mileage_Line_Item__c>{ c } );
                }
            }
            catch( Exception ex ) {
                System.debug( LoggingLevel.ERROR, 'FSL_CalculatedMileageLineItem.CalculatedMileageLineItem.createCalculatedMileageLineItem: Exception = [' + ex.getMessage() + ']' );
            }
        }

        private  String CT_PRODUCT_CODE_PREFIX = 'CT';
        public boolean doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist( Id workOrderId, String productCode ) {
            boolean exists = false;
            List<FSL_Calculated_Mileage_Line_Item__c> svcLineItems = dao.fetchCalculatedMileageLineItemForWorkOrderAndProductCode(workOrderId, productCode);
            for( FSL_Calculated_Mileage_Line_Item__c svcLI : svcLineItems) {
                if ( !(String.isBlank(svcLI.Product__c) || String.isBlank(svcLI.Product__r.ProductCode) ) ) {
                    if ( svcLI.Product__r.ProductCode.startsWith(CT_PRODUCT_CODE_PREFIX) ) {
                        exists = true;
                    }                    
                }
            }

            return exists;
        }

    }
}