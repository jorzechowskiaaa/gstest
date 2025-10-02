/****
 * *@Name: FSL_AddressTriggerHandler
 * *@Description: when the address is changed on the ServiceAppointment (Address,lat,lag etc..).
 * *@Date: 06-24-2019
 * *@Version: 1.0
 * * 
 * **/

public class FSL_AddressTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<Schema.Address> newList = Trigger.new;
    List<Schema.Address> oldList = Trigger.old;
    Map<Id, Schema.Address> newMap = (Map<Id, Schema.Address>)Trigger.newMap;
    Map<Id, Schema.Address> oldMap = (Map<Id, Schema.Address>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Address');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        system.debug('address data updated');
        system.debug(newMap.values());
        Map<Id,Schema.Address> saIdMap = new Map<Id,Schema.Address>();
        for(ID addrID : newMap.keySet()){
            if(oldMap.get(addrID).latitude != newMap.get(addrID).latitude){
                if(newMap.get(addrID).Service_Appointment__c != null){
                    saIdMap.put(newMap.get(addrID).Service_Appointment__c,newMap.get(addrID));
                }
            }
        }
        if(!saIdMap.isEmpty()) {
            // TODO: add to helper method
            List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
            for(Id saId : saIdMap.keySet()) {
                ServiceAppointment sa = new ServiceAppointment();
                sa.Id = saId;
                sa.latitude = saIdMap.get(saId).latitude;
                sa.Longitude = saIdMap.get(saId).Longitude;
                sa.FSL__InternalSLRGeolocation__Latitude__s = saIdMap.get(saId).latitude;
                sa.FSL__InternalSLRGeolocation__Longitude__s = saIdMap.get(saId).Longitude;
                saUpdateList.add(sa);
            }
            if(!saUpdateList.isEmpty() && Schema.sObjectType.ServiceAppointment.fields.latitude.IsUpdateable()) {
                update saUpdateList;                    
            }
        }
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    //Why this function is here? It is not used by this trigger handler
    public static void sAsWithNewAddress (List<ServiceAppointment> newSAs) {
        List<Schema.Address> newAddresses = new List<Schema.Address>();
        Schema.Address address = new Schema.Address();
        String locationId = System.Label.FSL_Location_Id;

        for(ServiceAppointment sa : newSAs) {
            address = new Schema.Address(Service_Appointment__c = sa.Id, ParentId = locationId);
            address.city = sa.city;
            address.state = sa.state;
            address.postalCode = sa.postalCode;
            address.country = sa.country;
            address.street = sa.street;
            newAddresses.add(address);
        }
        try{
            insert newAddresses;
        }
        catch (DmlException e) {
            //TODO:AddressLogger
            system.debug('Exception caught: ' + e);
        }   
    }

}