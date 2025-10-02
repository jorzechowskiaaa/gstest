public class ACG_GlobalSearchControllerSupport {


    @AuraEnabled
    public static String upsertCustomerRecord(Account accRecord){
        System.debug('Account - > '+accRecord);
        if(accRecord != null){
            try{
                upsert accRecord Contact_Object_ID_MDM__c;
                System.debug('accRecord-->'+accRecord);
                return accRecord.Id;
            }catch(Exception e){System.debug(e.getMessage());return null;
        }
        }else{
            return null;
        }
    }

    


}