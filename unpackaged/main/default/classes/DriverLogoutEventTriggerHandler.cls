public class DriverLogoutEventTriggerHandler {
 
    Public Static Void Run(List<LogoutEventStream> logoutList){
     // System.debug('after insert'+ logoutList[0]);
      LogoutEventStream event = logoutList[0];

     Integer isPermission = [SELECT count() FROM PermissionSetAssignment where AssigneeId = :event.UserId and 
                              PermissionSet.name ='Mobile_Technician_Permission_Set' ];
               
    IF(isPermission > 0)
    {
       Driver_Logout_Event__e record = new Driver_Logout_Event__e();
      //record.EventIdentifier__c = event.EventIdentifier;
      // record.UserId__c = event.UserId;
   
       record.EventTime__c = event.EventDate;
       record.Event__c= 'End Shift'; 
        
       List<ServiceResource> srList = [Select Facility_Number__c,name, Driver_Id__c,RelatedRecordId from ServiceResource where RelatedRecordId = :event.UserId];
       record.DriverName__c = srList[0].name;
       String facility_num = srList[0].Facility_Number__c;
       String driver_id =    srList[0].Driver_Id__c;
        
       record.DriverId__c = driver_id;
       record.FacilityID__c = facility_num ; 
        
       EventBus.publish(record);
    }

    

  }
}