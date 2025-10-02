/**
 *  @purpose    -   Copy the Latitude and Longitude from the updated address to the
 *                  Service Appointment that this Address looks up to.  
 */
trigger FSL_AddressTrigger on Address (after update) {
    FSL_TriggerDispatcher.run(new FSL_AddressTriggerHandler());

}