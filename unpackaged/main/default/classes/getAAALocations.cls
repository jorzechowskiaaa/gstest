public class getAAALocations {
    
    @AuraEnabled(cacheable=true)
    public static List<wrapperclass> getAccounts(Decimal latitude, Decimal longitude,String vehicleMake){
        if(vehicleMake != '' && vehicleMake != null){
        	vehicleMake = vehicleMake.toUpperCase();
        }
        Id repairShopAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_AAR').getRecordTypeId();
        String strAOR = 'SELECT id,'
                        +' Name, '
                        +' BillingLatitude, '
                        +' BillingLongitude, '
                        +' DISTANCE( BillingAddress, GEOLOCATION( :latitude, :longitude ),  \'mi\' ) dist, '
                        +' BillingAddress, '
                        +' billingstreet, ' 
                        +' billingcity, '
                        +' billingstate, '
                        +' billingPostalCode, '
                        +' BillingCountry, '
                        +' ACG_Priority_Service__c, '
                        +' RecordTypeId, '
                        +' Type '
                        +' FROM Account WHERE RecordTypeId = :repairShopAccountRecordTypeId';
        if(vehicleMake!=null && vehicleMake != 'OTHER' ){
            strAOR = strAOR + ' AND Vehicle_Make__c includes (:VehicleMake) ';       
        }              
      	strAOR  =strAOR +' AND BillingLatitude!= NULL AND BillingLongitude!=NULL '
            			+' AND  (Type =  \'AAR\' OR Type =  \'COR\') '
            			+' AND DISTANCE( BillingAddress, GEOLOCATION( :latitude, :longitude ),  \'mi\' )<40  ORDER BY '
                        +' Type DESC,DISTANCE( BillingAddress, GEOLOCATION( :latitude, :longitude ),  \'mi\' ) '
                        +' LIMIT 10';
        List<Account> accounts = Database.query(strAOR); 
        List<wrapperclass> lst=new List<wrapperclass>();
        for(Account acc_new:accounts){
            wrapperclass obj=new wrapperclass(acc_new);
            lst.add(obj);
        }
        return lst;
    }

    public class wrapperclass {
        
        @auraenabled public string name;
        @auraenabled public decimal distance;
        @auraenabled public string locationAddress;
        @auraenabled public decimal lat;
        @auraenabled public decimal lng;
        @auraenabled public string id;
        @auraenabled public string street;
        @auraenabled public string state;
        @auraenabled public string city;
        @auraenabled public string country;
        @auraenabled public string postalCode;
        @auraenabled public string type;
        @auraenabled public boolean priorityService;
        
        public wrapperclass(Account acc){
            
            name=acc.Name; 
            distance = decimal.valueOf(String.valueOf(acc.get('dist')));
            lat = acc.BillingLatitude;
            lng = acc.BillingLongitude;
            id = acc.id;
            locationAddress = acc.billingstreet+' '+acc.billingcity +' '+ acc.billingstate +' '+ acc.billingPostalCode+' '+ acc.BillingCountry;
            street = acc.billingstreet;
            city  = acc.BillingCity;
            state = acc.BillingState;
            country = acc.BillingCountry;
            postalCode = acc.BillingPostalCode;
            priorityService = acc.ACG_Priority_Service__c;
            type = acc.Type;
        }   
    } 
}