/**** Apex Class Name    :    ACG_SpotMemberLocationController
* Description        :    This  class is used to update the member location in case record,
*                         When member calls to agent for ERS request   
* Modification Log   :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Venkat Kommuri               	Jul 28 2021             Created
* Tarun Singh					Mar 1, 2022				Modified
*********************************************************************************/
global without sharing class ACG_SpotMemberLocationController {
    
    /***
* Method name        : fetchcase
* Description        : used to fetch the case redcord based on caseid
* Return Type        : Case
* @Param idCase      : Case Record Id
*/
    @Remoteaction
    public static case fetchcase(String idCase){
        Case objcase = new case();
        if(idCase!=null){
            String decrypted_Id_String = getDecryptedID(idCase);
            objcase = [Select id,caseNumber,ACG_Vehicle_Location_Address__c from case where Id=:decrypted_Id_String];
        }
        return objcase;
    }
    
    /***
* Method name        : fetchcase
* Description        : update the case record with members lat,lon and location details
* Return Type        : string
* @Param decLat      : Latitude of the member's spot location
* @Param decLon      : Longitude of the member's spot location
* @Param strLoc      : Formated Address of the member's spot location
* @Param idCase      : Case Record Id
*/
    @Remoteaction
    global static string updateCasedetails(Decimal decLat,Decimal decLon,String strLoc,String street,String city,String country,String state,String zip ,String idCase){
        string strResult;
        String latLong;
        String zipCode;
        try{
            String decrypted_Id_String = getDecryptedID(idCase);
            case objCS =new case();
            objCS.id = decrypted_Id_String;
            latLong = decLat+','+decLon;
            objCS.Member_Submitted_Get_GPS__c = true;
            objCS.Vehicle_Location_City__c = city;
            objCS.Vehicle_Location_Country__c = country;
            if(!String.isBlank(state)){
                Map<String, ERS_StateNamesWithCode__mdt> stateNameWithCodeMap = ERS_StateNamesWithCode__mdt.getAll();
                for(String key : stateNameWithCodeMap.keySet()){
                    if(stateNameWithCodeMap.get(key).label==state){
                        objCS.Vehicle_Location_State__c = key;
                        zipCode=key;
                    }
                }
            }
            if(string.isBlank(zip) || strLoc.contains('+')){
                //String bingResponse = INTMapSearchAddressWithAPI.getGeoJSONAddress(null,latLong);
                //system.debug('bingResponse'+bingResponse);
                //JSONParser parser = JSON.createParser(bingResponse);
                String sadaResponse = INTSADAGeoMapAPI.getGeoJSONAddress(null, latLong);
                system.debug('sadaResponse' + sadaResponse);
                JSONParser parser = JSON.createParser(sadaResponse);
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'postalCode')) {
                        parser.nextToken(); 
                        zip = parser.getText();
                        break;
                    }
                }
                List<String> plusCodeAddress = strLoc.split(' ');
                street=plusCodeAddress[0];
                
            }            
            objCS.ACG_Vehicle_Location_Address__c = strLoc;
         	/*EMI commented lines 80-83,due to null point error : 09/03/2024*/
            /*  String TimezoneUTCOffset =INTSADAGeoMapAPI.getTimezoneUTCOffset_Str(String.valueOf(decLat), String.valueOf(decLon));
            if(TimezoneUTCOffset !=null){
                objCS.Member_Location_TZ_Offset__c=TimezoneUTCOffset;
            }*/
            objCS.Vehicle_Location_Postal_Code__c = zip;
            objCS.Vehicle_Location_Street__c =street;
            objCS.Vehicle_Geolocation__Latitude__s =  decLat;
            objCS.Vehicle_Geolocation__Longitude__s = decLon;
            objCS.Breakdown_Location__Latitude__s = decLat;
            objCS.Breakdown_Location__Longitude__s = decLon;
            objCS.LandMark__c = street;
            if(objCS!=null){
                update objCS;
                strResult = ACG_ConstantsClass.SUCCESS;
            }
            List<Update_GPS_Location__e> events = new list<Update_GPS_Location__e>();
            Update_GPS_Location__e gpsEvent = new Update_GPS_Location__e();
            gpsEvent.Case_ID__c = decrypted_Id_String;
            gpsEvent.Vehicle_Location_Street__c = street;
            gpsEvent.LandMark__c = street;
            gpsEvent.Vehicle_Location_City__c = city;
            gpsEvent.Vehicle_Location_State__c = state;
            gpsEvent.Vehicle_Location_Country__c = country;
            gpsEvent.Vehicle_Location_Postal_Code__c = zip;
            gpsEvent.Vehicle_Geolocation_Latitude__c = String.valueOf(decLat);
            gpsEvent.Vehicle_Geolocation_Longitude__c = String.valueOf(decLon);
            gpsEvent.ACG_Vehicle_Location_Address__c = strLoc;
           // gpsEvent.Member_Location_TZ_Offset__c=TimezoneUTCOffset; //EMI as per SSFI-171:09/03/2024
            system.debug('gpsEvent'+gpsEvent);
            events.add(gpsEvent);
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                } 
            }
        }
        Catch(Exception e){
            strResult = e.getMessage();
        }
        return strResult;
    }
    
    public static String getDecryptedID(String encryptedId){
        Blob key = EncodingUtil.base64Decode(Label.ERS_Encryption_Key);
        Blob data;
        if(Test.isRunningTest()){
            data = EncodingUtil.base64Decode(EncodingUtil.urlDecode(encryptedId, 'UTF-8'));
        }else{
            data = EncodingUtil.base64Decode(encryptedId);
        }
        Blob decrypted_Id = Crypto.decryptWithManagedIV('AES128', key, data);
        String decrypted_Id_String = decrypted_Id.toString();
        return decrypted_Id_String;
    }
}