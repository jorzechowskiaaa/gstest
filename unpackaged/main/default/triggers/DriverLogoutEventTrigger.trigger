trigger DriverLogoutEventTrigger on LogoutEventStream (after insert) {
    
 DriverLogoutEventTriggerHandler.run(Trigger.new);
      
}