/**
 * @File Name          : FSL_JSONParserLocationUpdates
 * @Description        : 
 * @Author             : Salesforce Services
 * @Group              : 
 * @Last Modified By   : Salesforce Services
 * @Last Modified On   : 5/1/2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
**/
@isTest
public class FSL_JsonParserLocationUpdatesTest {
    static testMethod void jsonParserLocationTest(){
        FSL_JSONParserLocationUpdates jsonParserWO = new FSL_JSONParserLocationUpdates();
        
        jsonParserWO.id = 'Test Id';
        jsonParserWO.requestEventType = 'Test requestEventType';
    	jsonParserWO.subType = 'Test subType'; 
    	jsonParserWO.version = 'Test version';
    	jsonParserWO.createDate = 'Test createDate';
        
        FSL_JSONParserLocationUpdates.Phones_Contacts phoneContact = new FSL_JSONParserLocationUpdates.Phones_Contacts();
        phoneContact.phoneNumber = '9999999999';
        phoneContact.phoneType = 'Work';
        phoneContact.preferred = true;
         
        FSL_JSONParserLocationUpdates.SystemOrganziation systemOrg = new FSL_JSONParserLocationUpdates.SystemOrganziation();
        systemOrg.code = 'Test Code';
        systemOrg.name = 'Test Name';
        
        FSL_JSONParserLocationUpdates.SourceSystem sourceSystem = new FSL_JSONParserLocationUpdates.SourceSystem();
        sourceSystem.systemId = 'Test System Id';
        sourceSystem.systemOrganziation = systemOrg;
        
        FSL_JSONParserLocationUpdates.Calls call = new FSL_JSONParserLocationUpdates.Calls();
        
        FSL_JSONParserLocationUpdates.Contact contact = new FSL_JSONParserLocationUpdates.Contact();        
        contact.userId = 'USER ID';
        contact.contactType = 'Test Contact Type';
        
        //FSL_JSONParserLocationUpdates.Location location = new FSL_JSONParserLocationUpdates.Location();
        FSL_JSONParserLocationUpdates.Address address = new FSL_JSONParserLocationUpdates.Address();
        address.addressType = 'Home Address';
        address.city = 'City';
        address.country = 'United States';
        address.county = 'County';
        address.crossStreet = 'Cross Street';
        address.crossStreet2 = 'Cross Street1';
        address.full = '';
        address.postalCode = '12345';
        address.state = 'State';
        address.street = 'Street';
        address.streetDirection = '';
        address.streetName = 'Street Name';
        address.streetNumber = '1234B';
        
        /*location.address = address;
        location.latitude = 09.09;
        location.longitude = 10.09;*/
        
        FSL_JSONParserLocationUpdates.Channel channel = new FSL_JSONParserLocationUpdates.Channel();
        channel.channelType = 'Test Channel Type';
        channel.org = systemOrg;
        channel.contact = contact;
        
        FSL_JSONParserLocationUpdates.Service service = new FSL_JSONParserLocationUpdates.Service();
        FSL_JSONParserLocationUpdates.Facility facility = new FSL_JSONParserLocationUpdates.Facility();
        FSL_JSONParserLocationUpdates.ServiceLocations serviceLocation = new FSL_JSONParserLocationUpdates.ServiceLocations();
        FSL_JSONParserLocationUpdates.Foi foi = new FSL_JSONParserLocationUpdates.Foi();
        FSL_JSONParserLocationUpdates.Contacts contacts = new FSL_JSONParserLocationUpdates.Contacts();
        FSL_JSONParserLocationUpdates.ServiceLocations_Location serviceLocationLocation = new FSL_JSONParserLocationUpdates.ServiceLocations_Location();
        FSL_JSONParserLocationUpdates.Location_TowDest loc_towDest = new FSL_JSONParserLocationUpdates.Location_TowDest();
        FSL_JSONParserLocationUpdates.Address_TowAddress add_TowAdd = new FSL_JSONParserLocationUpdates.Address_TowAddress();
        FSL_JSONParserLocationUpdates.Foi_TowDest foi_TowDest = new FSL_JSONParserLocationUpdates.Foi_TowDest();
        FSL_JSONParserLocationUpdates.Status status = new FSL_JSONParserLocationUpdates.Status();
        
        add_TowAdd.addressType = 'Test Address type';
        add_TowAdd.city = 'Test City';
        add_TowAdd.country = 'Country';
        add_TowAdd.county = 'County';
        add_TowAdd.crossStreet = 'Cross Street';
        add_TowAdd.full = '';
        add_TowAdd.postalCode = '12345';
        add_TowAdd.state = 'State';
        add_TowAdd.streetName = 'Street Name';
        add_TowAdd.streetNumber = '1234B';
        
        loc_towDest.address = add_TowAdd;
        loc_towDest.landmark = 'Test Landmark';
        loc_towDest.latitude = 109.98;
        loc_towDest.longitude = 198.09;
        
        foi_TowDest.location = loc_towDest;
        foi_TowDest.name = 'Test Name';
        
        serviceLocationLocation.address = address;
        serviceLocationLocation.grid = 'Test Grid';
        serviceLocationLocation.highway = 'Test Highway';
        serviceLocationLocation.landmark = 'Test Landmark';
        serviceLocationLocation.latitude = 10.987;
        serviceLocationLocation.locationCode = 'Test Code';
        serviceLocationLocation.longitude = 196.97;
        serviceLocationLocation.mileMarker = 'Test Mile Marker';
        serviceLocationLocation.zone = 'Test Zone';
        
        contacts.contactType = 'Test Contact Type';
        contacts.firstName = 'Test First Name';
        contacts.lastName = 'Test Last Name';
        contacts.phones = new List<FSL_JSONParserLocationUpdates.Phones_Contacts>{phoneContact};
        
        foi.location = serviceLocationLocation;
        foi.name = 'Test Name';
        foi.contacts = new List<FSL_JSONParserLocationUpdates.Contacts>{contacts};
            

        serviceLocation.foi = foi;
        serviceLocation.foi_towDest = foi_TowDest;
        serviceLocation.serviceLocationType = 'Test Service Location Type';
        
        facility.id = 'Test Id';
        facility.name = 'Test Name';
        
        status.updateCode = 'UP';
        status.modifiedDate = '10/10/2019';
        status.pta = '98876543';
        status.status = 'Test Status';
        status.waitTime = 1875;
        
        service.status = status;
        service.serviceLocations = new List<FSL_JSONParserLocationUpdates.ServiceLocations>{serviceLocation};
        service.facility = facility;
        
            
        FSL_JSONParserLocationUpdates.Comments comment = new FSL_JSONParserLocationUpdates.Comments();
        comment.commentType = 'Test Comment Type';
        comment.contact = contact;
        comment.date_str = 'Test Date String';
        comment.system_Z = sourceSystem;
        comment.text = 'Test Text';
        comment.visibility = 'Public';
        
        
        call.callDate = '10/10/2019';
        call.callId = 'ID-01987';
        call.callKey = 'Test Call Key';
        call.channel = channel;
        call.version = 'Test Version';
        call.service = service;
        call.comments = new List<FSL_JSONParserLocationUpdates.Comments>{comment};
         
        jsonParserWo.calls = new List<FSL_JSONParserLocationUpdates.Calls>{call};
    }

}