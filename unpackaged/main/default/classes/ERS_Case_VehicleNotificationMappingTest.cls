@isTest
public class ERS_Case_VehicleNotificationMappingTest {
    @isTest(SeeAllData=true)
    public static void getNotificationTest_FlatTire(){
        String CurrentTab = 'TOW';
        string ServiceDescription = 'TOW';
        string VehicleYear ='2021';
        string VehicleMake ='BMW';
        string VehicleModel = 'M3';

        string VehicleInfo='TOW_2021_BMW_M3';

        List<VehicleServiceNotification__c> NotificationList = [SELECT ServiceNotificationText__c
                                                                FROM VehicleServiceNotification__c
                                                                WHERE Name_of_Triage_Tab__c =:CurrentTab
                                                                AND ServiceDescription__c =:ServiceDescription
                                                                AND VehicleYear__c =:VehicleYear
                                                                AND VehicleMake__c =:VehicleMake
                                                                AND VehicleModel__c =:VehicleModel
                                                                LIMIT 1 ];      
                                                               
        
        String Notification_MSgs = ERS_Case_VehicleNotificationMapping.getVehicleNotification( VehicleInfo);
        
         if( !NotificationList.isEmpty() && ! string.isNotEmpty(Notification_MSgs)){
            system.assertEquals(true,Notification_MSgs.contains(NotificationList[0].ServiceNotificationText__c), 'Error getting the Notification message');
        }
    }

    @isTest(SeeAllData=true)
    public static void getVehicleNotificationTest_TOW(){                
        String CurrentTab = 'TOW';
        string ServiceDescription = 'TOW';
        string VehicleYear ='2008';
        string VehicleMake ='VOLKSWAGEN';        
       string VehicleModel = 'BEETLE';

       string VehicleInfo='TOW_2008_VOLKSWAGEN_BEETLE';

        List<VehicleServiceNotification__c> NotificationList = [SELECT  ServiceNotificationText__c
                                                                FROM VehicleServiceNotification__c
                                                                WHERE Name_of_Triage_Tab__c =:CurrentTab
                                                                AND ServiceDescription__c =:ServiceDescription
                                                                AND VehicleYear__c =:VehicleYear
                                                                AND VehicleMake__c =:VehicleMake
                                                                AND VehicleModel__c =:VehicleModel
                                                                LIMIT 1 ];          
       
                                                                           
        String Notification_MSgs = ERS_Case_VehicleNotificationMapping.getVehicleNotification(VehicleInfo);

       
        if( !NotificationList.isEmpty() && ! string.isNotEmpty(Notification_MSgs)){
            system.assertEquals(true,Notification_MSgs.contains(NotificationList[0].ServiceNotificationText__c), 'Error getting the Notification message');
        }
    }
}