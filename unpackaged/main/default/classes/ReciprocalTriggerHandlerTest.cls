@isTest
private class ReciprocalTriggerHandlerTest {
    @TestSetup
    static void createTestData() {
                Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();

        Reciprocal__c r = new Reciprocal__c();
            r.Member_First_Name__c = 'Wanda';
            r.Member_Last_Name__c = 'Doe';
            r.Service_Call_Date__c = System.today();
            r.Service_Call_Trouble_Code__c = 'T1';
            r.RecordTypeId = recordTypeId;
            r.Cost_Buffer__c = 'PLS/02100/:BAS/07250/:BON/0';
            insert r;
    }

    @isTest 
    static void test_CostBufferChange(){
        List<Reciprocal__c> rs = [Select Id, is_Duplicate__c from Reciprocal__c where Member_First_Name__c='Wanda'];
        rs[0].Cost_Buffer__c = 'PLS/02100/:BAS/07250/:BON/1248' ; 
        rs[0].Total_Dollar_Amount__c = 0 ; 

        update rs[0]; 

        List<Reciprocal__c> rs_afterChange = [Select Id, is_Duplicate__c,Total_Dollar_Amount__c from Reciprocal__c where Member_First_Name__c='Wanda'];
        System.assertEquals(12.00, rs_afterChange[0].Total_Dollar_Amount__c);
    }
    
    
    @isTest
    static void insertDupe(){
      Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();

       Reciprocal__c r = new Reciprocal__c();
        r.Member_First_Name__c = 'Wanda';
        r.Member_Last_Name__c = 'Doe';
        r.Service_Call_Date__c = System.today();
        r.Service_Call_Trouble_Code__c = 'T1';
        r.RecordTypeId = recordTypeId;
        insert r;
        
        List<Reciprocal__c> rs = [Select Id, is_Duplicate__c from Reciprocal__c where Is_Duplicate__c=true];
        
        System.assertEquals(rs.size(),2, 'Should be both marked as duplicate');        
        
    }
    
        @isTest
    static void insertDifferentRt(){
      Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Outbound_Payment_Requests').getRecordTypeId();

       Reciprocal__c r = new Reciprocal__c();
        r.Member_First_Name__c = 'Wanda';
        r.Member_Last_Name__c = 'Doe';
        r.Service_Call_Trouble_Code__c = 'T1';
        r.RecordTypeId = recordTypeId;
        r.Service_Call_Date__c = System.today();
        insert r;
        
        List<Reciprocal__c> rs = [Select Id, is_Duplicate__c from Reciprocal__c where Is_Duplicate__c=true];
        
        System.assertEquals(rs.size(),0, 'Should be  no duplicate');        
        
    }
    
        @isTest
    static void insertDupeWithCaseDiffernce(){
      Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();

       Reciprocal__c r = new Reciprocal__c();
        r.Member_First_Name__c = 'WanDa';
        r.Member_Last_Name__c = 'DoE';
        r.Service_Call_Date__c = System.today();
        r.Service_Call_Trouble_Code__c = 'T1';
        r.RecordTypeId = recordTypeId;
        insert r;
        
        List<Reciprocal__c> rs = [Select Id, is_Duplicate__c from Reciprocal__c where Is_Duplicate__c=true];
        
        System.assertEquals(rs.size(),2, 'Should be both marked as duplicate');        
        
    }
    
    
        @isTest
    static void insertNoDupe(){
      Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();

       Reciprocal__c r = new Reciprocal__c();
        r.Member_First_Name__c = 'Wendy';
        r.Member_Last_Name__c = 'Doe';
        r.Service_Call_Date__c = System.today();
        r.Service_Call_Trouble_Code__c = 'T1';
        r.RecordTypeId = recordTypeId;
        insert r;
        
        List<Reciprocal__c> rs = [Select Id, is_Duplicate__c from Reciprocal__c where Is_Duplicate__c=true];
        
        System.assertEquals(rs.size(),0, 'Should be no duplicates');        
        
    }
    
    @isTest
    static void insertTwoDupes(){
        Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();

        List <Reciprocal__c> rs = new List<Reciprocal__c>();
       Reciprocal__c r = new Reciprocal__c();
        r.Member_First_Name__c = 'Mandy';
        r.Member_Last_Name__c = 'Doe';
        r.Service_Call_Date__c = System.today();
        r.Service_Call_Trouble_Code__c = 'T1';
        r.RecordTypeId = recordTypeId;

       rs.add(r);
              Reciprocal__c r2 = new Reciprocal__c();
        r2.Member_First_Name__c = 'Mandy';
        r2.Member_Last_Name__c = 'Doe';
        r2.Service_Call_Date__c = System.today();
        r2.Service_Call_Trouble_Code__c = 'T1';
        r2.Long_Tow_Indicator__c = true;
        r2.RecordTypeId = recordTypeId;

       rs.add(r2);
        insert rs;
        
        rs = [Select Id, is_Duplicate__c from Reciprocal__c where Is_Duplicate__c=true and Member_First_Name__c='Mandy'];
        
        System.assertEquals(rs.size(),2, 'Should be two duplicates');        
        
    }
    
    
}