public class ERS_Case_VehicleNotificationMapping {
	@AuraEnabled(cacheable=true)
    public static String getVehicleNotification(String VehicleInfomation){

       string CurrentTab;
       string ServiceType;
       string VehicleYear;
       string VehicleMake;
       string VehicleModel;

       String setVehicleServiceNotification;     
       List<string> VehicleInfo = new List<string>();

        if (string.isNotEmpty(VehicleInfomation)){      
        VehicleInfo = VehicleInfomation.split('_');       
        CurrentTab = VehicleInfo[0].toUpperCase();
        ServiceType = VehicleInfo[0].toUpperCase();
        VehicleYear = VehicleInfo[1].toUpperCase();
        VehicleMake = VehicleInfo[2].toUpperCase();
        VehicleModel =VehicleInfo[3].toUpperCase();        
       
        System.debug('VehicleInfo ' +CurrentTab + ServiceType + VehicleYear + VehicleMake + VehicleModel );
  
        //Get all the custom object mappings specific to the Current tab.
            
        List<VehicleServiceNotification__c> NotificationList = [SELECT  ServiceNotificationText__c                                          
                                                                        FROM VehicleServiceNotification__c
																        WHERE Name_of_Triage_Tab__c =:CurrentTab   
                                                                        AND ServiceDescription__c  =:ServiceType 
                                                                        AND  VehicleYear__c  =:VehicleYear 
                                                                        AND  VehicleMake__c  =:VehicleMake  
                                                                        AND  VehicleModel__c  =:VehicleModel                                                                                                                                  
                                                                        ];    
             
           
       
        if(!NotificationList.isEmpty()){
            	//Search through the custom object records
                for(VehicleServiceNotification__c NotificationRec : NotificationList){
                if ( VehicleInfomation!=NULL && NotificationRec.ServiceNotificationText__c!= NULL ) 
                {  
                    setVehicleServiceNotification= NotificationRec.ServiceNotificationText__c;  
                }
            }
        }
        
    }
    return  setVehicleServiceNotification;   
      
  }
}