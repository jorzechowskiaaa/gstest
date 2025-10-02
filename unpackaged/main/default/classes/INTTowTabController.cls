public without sharing class INTTowTabController {
    
    @AuraEnabled(cacheable = false)
    public static List<Account> getAarMprDetails(Id caseId, String latitude, String longitude, string towReason){
        //define variables to use in this method
        System.debug('caseId' +caseId);
        System.debug('caseId' +latitude);
        System.debug('caseId' +longitude);
        System.debug('caseId' +towReason);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Approved Garage').getRecordTypeId();
        List<Account> accList = new List<Account>();
        String qryAccount;
        String qryStart;
        String qryVehicleType;
        String qryVehicleMake;
        String qryEnd;
        String qryLimit;
        List<String> approvedGarageTypeList = new List<String>();
        Set<String> approvedGarageTypeSet = new Set<String>();
        decimal dLat ;
        decimal dLon;
        
        if(latitude != null){
            dLat = decimal.valueOf(latitude);
            //system.debug('dLat=== '+dLat);
        }
        if(longitude != null){
            dLon = decimal.valueOf(longitude);
            //system.debug('dLon=== '+dLon);
        }
        
        //query case to get all fields already saved to case
        Case cs = [SELECT Id, Vehicle_Geolocation__c, ACG_Service_Type__c, Flat_Tire_Status__c, Member_Vehicle_Type__c,
                   Tow_Request_Reason__c, ACG_Make__c, ACG_Vehicle_Location_Address__c,Total_Mileage__c
                   FROM Case 
                   WHERE Id =: caseId LIMIT 1];
        String caseVehicleMake = cs.ACG_Make__c;
        String memberVehicleType = cs.Member_Vehicle_Type__c;
        ARR_Call_Receive_LWC_UI_Configuration__c arrCustomSetting = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
        String searchLimit = String.valueOf(arrCustomSetting.Approved_Garage_Search_Result_Limit__c);
        //get all custom setting records from Approved_Garage_Type_Mapping__c
        Map<String,Approved_Garage_Type_Mapping__c> approvedGarageMap = Approved_Garage_Type_Mapping__c.getall();
        try{
            if(cs.ACG_Service_Type__c == null || towReason == null || cs.ACG_Vehicle_Location_Address__c == null || cs.Member_Vehicle_Type__c == null){
                System.debug('ACG_Service_Type__c: '+cs.ACG_Service_Type__c);
                System.debug('towReason: '+ towReason);
                System.debug('ACG_Vehicle_Location_Address__c: '+cs.ACG_Vehicle_Location_Address__c);
                System.debug('Member_Vehicle_Type__c: '+cs.Member_Vehicle_Type__c);
                
                throw new AuraHandledException('Please select reason');
            }
            else{
                for(String apGarageMap : approvedGarageMap.keySet()){
                    Approved_Garage_Type_Mapping__c code = approvedGarageMap.get(apGarageMap);
                    
                    //Fetch mapping factors to update the account query and find the only match of the custom setting mapping condition
                    if(code.Service_Type__c.contains(cs.ACG_Service_Type__c) 
                       && code.Tow_Service_Reason__c.contains(towReason)
                       && code.Vehicle_Type__c.contains(cs.Member_Vehicle_Type__c)){
                           //split approved garage type from mapping record to a list, then add to a set to dedup
                           //use this set to query account
                           approvedGarageTypeList = code.Approved_Garage_Type__c.split(';');
                           approvedGarageTypeSet.addAll(approvedGarageTypeList);
                           system.debug('approvedGarageTypeSet== '+approvedGarageTypeSet);
                           //fetch if we need to consider the vehicle type in the account query
                           if(code.Ignore_Type__c == true){
                               qryVehicleType ='';
                           }
                           else {
                               qryVehicleType = ' AND Service_Vehicle_Type__c INCLUDES (:memberVehicleType)';  
                           }
                           //fetch if we need to consider the vehicle make in the account query
                           if(code.Ignore_Make__c == true){
                               qryVehicleMake ='';
                           }
                           else {
                               qryVehicleMake = ' AND Service_Vehicle_Make__c INCLUDES (:caseVehicleMake)';  
                           }
                       }
                    //qryLimit = code.Limit_search_result__c;
                }
            }
            //system.debug('approvedGarageType '+ approvedGarageTypeSet);
            //consolidate the dynamic qurey after fetching the conditions
            //1st part of the account query   
            qryStart = 'SELECT Id, Name, Approved_Garage_Type__c, AAR_Display_Address__c, ACG_Priority_Service__c, Information__c,'
                + ' BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,'
                + ' BillingLatitude, BillingLongitude, BillingAddress,'
                + ' DISTANCE(BillingAddress, GEOLOCATION( :dLat, :dLon),\'mi\') dist'
                + ' FROM Account'
                + ' WHERE Approved_Garage_Type__c IN :approvedGarageTypeSet'
                + ' AND recordTypeId = :recordTypeId';
            //last part of the account query
            qryEnd = ' ORDER BY DISTANCE(BillingAddress, GEOLOCATION( :dLat, :dLon),\'mi\') ASC LIMIT ';// 15';
            qryLimit = '15'; //searchLimit;
            
            qryAccount = qryStart + qryVehicleType + qryVehicleMake + qryEnd + qryLimit;
            system.debug('qry '+qryAccount);
            accList = database.query(qryAccount);
            for(Account acc : accList){
                if(acc.Information__c != null){
                    acc.Information__c = acc.Information__c.stripHtmlTags();
                }
            }
            
            return accList;
        }catch(exception e){
            System.debug('AuraHandledException:  '+e.getMessage());
            throw new AuraHandledException(e.getStackTraceString());
        }
    } 
    
    @AuraEnabled
    public static List<Account> getAARBasedOnSelectedAddress(Id recId){
        List<Account> aarRecord = [SELECT Id, Name, Latitude__c, Longitude__c, BillingStreet, BillingCity,
                                   BillingState, BillingCountry, BillingPostalCode
                                   FROM Account 
                                   WHERE Id=: recId];
        system.debug('aarRecord=== '+aarRecord);
        
        return aarRecord;
    }
    
    @AuraEnabled 
    public static List<Case> updateCaseTowData(Id caseId, Id accId){//, string towReason
        List<Case> caseListToUpdate = new List<Case>();
        system.debug('caseId'+caseId);
        system.debug('accId'+accId);
        //system.debug('towReason'+towReason);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Approved Garage').getRecordTypeId();
        List<Account> getAccountRecord = [SELECT Id, Name, Latitude__c, Longitude__c, BillingStreet, BillingCity,RecordTypeId,
                                          BillingState, BillingCountry, BillingPostalCode, BillingLatitude, BillingLongitude
                                          FROM Account 
                                          WHERE Id=: accId];
        
        for(Account acc : getAccountRecord){
            Case c = new Case();
            c.Id = caseId;
            c.Tow_Destination_Street__c = acc.BillingStreet;
            c.Tow_Destination_City__c = acc.BillingCity;
            c.Tow_Destination_State__c = acc.BillingState;
            c.Tow_Destination_Country__c = acc.BillingCountry;
            c.Tow_Destination_Postal_Code__c = acc.BillingPostalCode;
            if(acc.RecordTypeId == recordTypeId){
                c.Approved_Garage__c = acc.Id;
                c.Repair_Shop__c = acc.Id;
                // c.Tow_Destination_Landmark__c = acc.Name;
                c.Tow_Destination_Name__c  = acc.Name;
            }
            else{
                c.Approved_Garage__c = '';
                //c.Tow_Destination_Landmark__c = '';
                c.Tow_Destination_Name__c  = '';
            }
            //c.Tow_Request_Reason__c = towReason;
            c.Tow_Geolocation__latitude__s = acc.BillingLatitude;
            c.Tow_Geolocation__longitude__s = acc.BillingLongitude;
            c.ACG_Tow_Destination_Address__c = acc.BillingStreet + ' ' + acc.BillingCity + ' ' + acc.BillingState + ' ' +
                acc.BillingCountry + ' ' + acc.BillingPostalCode;
            caseListToUpdate.add(c);
        }
        system.debug('caseListToUpdate'+caseListToUpdate);
        if(!caseListToUpdate.isEmpty()){
            update caseListToUpdate;
        }
        return caseListToUpdate;
    }
    
    @AuraEnabled
    public static Case getCaseDetails(Id caseId){
        Case cs = [SELECT Id, Tow_Request_Reason__c, ACG_Tow_Destination_Address__c, ACG_Vehicle_Location_Address__c, Landmark__c,
                   Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Tow_Destination_Landmark__c,Tow_Destination_Name__c,Total_Mileage__c 
                   FROM Case
                   WHERE Id=: caseId];
        system.debug('cs== '+cs);
        return cs;        
    }
    
    @AuraEnabled
    public static List<Case> updateCaseBasedonTowAddressValue(Id caseId, String Address, String addrStreet, String addrCity, String addrState, String addrZip, String addrCountry, String latitude, String longitude, String landmark){
        List<Case> caseToBeUpdated = new List<Case>();
        List<Case> csRecord = [SELECT Id, ACG_Vehicle_Location_Address__c, Landmark__c, POI_Mile_Marker_Location__c,
                               Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c, 
                               Vehicle_Location_Postal_Code__c, Vehicle_Location_Country__c,
                               ACG_Tow_Destination_Address__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Postal_Code__c, Tow_Destination_Country__c,Tow_Destination_Name__c,Total_Mileage__c,Repair_Shop__c //AGB added Repair_Shop__c for SSFI-990
                               FROM Case
                               WHERE Id =: caseId];
        for(Case c : csRecord){
            system.debug('Address== '+Address);
            
            system.debug('addrStreet== '+addrStreet);
            
            system.debug('addrCity== '+addrCity);
            
            system.debug('addrState== '+addrState);
            
            system.debug('addrZip== '+addrZip);
            
            system.debug('addrZip== '+addrCountry);
            c.ACG_Tow_Destination_Address__c = Address;
            c.Tow_Destination_Street__c = addrStreet;
            if(addrStreet == null && Address != null){
                c.Tow_Destination_Street__c = c.ACG_Tow_Destination_Address__c.substringBefore(',');
            }
            c.Tow_Destination_City__c = addrCity; 
            c.Tow_Destination_State__c = addrState;
            c.Tow_Destination_Postal_Code__c = addrZip;
            c.Tow_Destination_Country__c = addrCountry;
            // c.Tow_Destination_Landmark__c = landmark;
            c.Tow_Destination_Name__c  = landmark;
            
            c.Approved_Garage__c = null;
            
            system.debug('Address== latitude double '+Decimal.valueOf(latitude).setScale(8) );
            
            system.debug('Address== longitude double '+Decimal.valueOf(longitude).setScale(8) );
            c.Tow_Geolocation__latitude__s = Decimal.valueOf(latitude).setScale(8) ;
            c.Tow_Geolocation__longitude__s = Decimal.valueOf(longitude).setScale(8) ; 
            c.Repair_Shop__c = null; //AGB added Repair_Shop__c for SSFI-990
            caseToBeUpdated.add(c);
        }                        
        system.debug('caseToBeUpdated=== '+caseToBeUpdated);
        if(!caseToBeUpdated.isEmpty()){
            update caseToBeUpdated;
        }
        
        return csRecord;
    }
}