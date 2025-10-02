/**
 * @File Name          : FSL_MileageCalculatedUtilityTest.cls
 * @Description        : 
 * @Author             : Dylan Truong
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 09/20/2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    09/20/2021   Dylan Truong          ERS-223670 :Updates to Mileage and ER Calculation
*  1.1    10/25/2021   Dylan Truong          ERS-226141 :Reimplement Calculate Mileage by Using Bing Webservice instead built in DISTANCE Function
*  1.2    11/25/2021   Dylan Truong          ERS-222039 :Reimplement Calculate Mileage: Replace Exist OM/TW Logic With New CE/CT Service Line Items Logic
**/

@IsTest
public with sharing class FSL_MileageCalculatedUtilityTest {
        @IsTest
        static void testCalculateMileageFromFlow(){
            FSL_MileageCalculatedUtility.CalculateMileage calMileage =  new FSL_MileageCalculatedUtility.CalculateMileage();
            Product2  p = new Product2 (productCode='OM');
            WorkOrder wo = new WorkOrder();
    
            calMileage.originLatitude = '33.847';
            calMileage.originLongitude = '-118.231';
            calMileage.destinationLatitude = '33.727972';
            calMileage.destinationLongitude = '-117.790392';
            calMileage.workOrderId = wo.Id;
            calMileage.productCode = 'OM';
            List<FSL_MileageCalculatedUtility.CalculateMileage> calMileages = new List<FSL_MileageCalculatedUtility.CalculateMileage>();
            calMileages.add(calMileage);
            Test.startTest();
            FSL_MileageCalculatedUtility.calculateMileageFromFlow(calMileages);
            Test.stopTest();
            List<FSL_Calculated_Mileage_Line_Item__c> sli = [SELECT Id, Product__c, Work_Order__c, Unit__c FROM FSL_Calculated_Mileage_Line_Item__c WHERE  Product__c=:p.Id];
            System.assertEquals(true, sli.size()>0);
            
        }

        @IsTest
        static void testCalculateMileageFromFlow_Exception(){
            FSL_MileageCalculatedUtility.CalculateMileage calMileage =  new FSL_MileageCalculatedUtility.CalculateMileage();
            Product2  p = new Product2 (productCode='OM');
            WorkOrder wo = new WorkOrder();
            calMileage.originLatitude = '33.847';
            calMileage.originLongitude = '-118.231';
            calMileage.destinationLatitude = '33.727972';
            calMileage.destinationLongitude = '0';
            calMileage.workOrderId = wo.Id;
            calMileage.productCode = 'OM';
            FSL_MileageCalculatedUtility.CalculateMileageService calService = new FSL_MileageCalculatedUtility.CalculateMileageService(calMileage);
            calService.distanceService = new MappingServiceMock(true);
                    
            Test.startTest();
            calService.calculateDistance();
            Test.getEventBus().deliver();
            Test.stopTest();
            List<FSL_Application_Log__c> appLogs = [SELECT Id, Operation__c, Error_Message__c FROM FSL_Application_Log__c];
            System.assertEquals(true, appLogs.size() > 0);
        
        }
    
        @IsTest
        static void testCalculateDistanceInMile(){
   
            FSL_MileageCalculatedUtility.CalculateMileage calMileage =  new FSL_MileageCalculatedUtility.CalculateMileage();
            calMileage.originLatitude = '33.847';
            calMileage.originLongitude = '-118.231';
            calMileage.destinationLatitude = '33.727972';
            calMileage.destinationLongitude = '-117.790392';
            FSL_MileageCalculatedUtility.CalculateMileageService calService = new FSL_MileageCalculatedUtility.CalculateMileageService(calMileage);
            calService.distanceService = new MappingServiceMock(false); 
            Test.startTest();
            Decimal distance = calService.calculateDistanceInMile();
            Test.stopTest();
            System.assertEquals(1.0,distance);
        }

        public class MappingServiceMock implements FSL_Mapping.IMap {
            private Boolean isException = false;
            public MappingServiceMock(Boolean isException) {
                this.isException = isException;
            }

            public Decimal calculateDistanceInMiles( Double latOrigin, Double longOrigin, Double latDestination, Double longDestination ) {
                if (isException) {
                    throw new MockingException();
                } else {
                    return 1.0; 
                }
                
            }
        }

        public class MockingException extends Exception {

        }

    

}