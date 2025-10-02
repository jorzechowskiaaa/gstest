@isTest
public class FSL_CallCommentsByDateRangeTest {
    
    @isTest
    private static void FSL_CallCommentsByDateRangemethod(){
                
      integer recordCount = 2;
        
        List<Account> accounts = new List<Account>();
        for( Integer i = 0; i < recordCount; ++i ) {
            accounts.add( new Account( Name = 'Name ' + i ) );
        }
        insert accounts;

        system.debug('accounts 25' + accounts);
            
        List<Contact> contacts = new List<Contact>();
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts.add( new Contact( LastName = 'Last Name ' + i, AccountId = accounts[i].Id ) );
           
        }
        insert contacts;
        
         List<WorkOrder> workOrders = new List<WorkOrder>();
        List<List<WorkOrder>> workOrderslist = new List<List<WorkOrder>>();
        for( Integer i = 0; i < recordCount; ++i ) {
            String recordType = ( math.mod( i, 2 ) == 0 ? 'Light Service' : 'Tow' );
            WorkOrder wo = FSL_DataFactory.createWorkOrderShell( recordType, contacts[i] );
            wo.Status = 'Cleared';
            workOrders.add( wo );
          
        }
        insert workOrders;
        workOrderslist.add(workOrders);
        
        FSL_Call_Comments__c comment1 = new FSL_Call_Comments__c( FSL_Work_Order__c = workOrders[0].Id, FSL_Comment__c = 'Comment 1' );
        FSL_Call_Comments__c comment2 = new FSL_Call_Comments__c( FSL_Work_Order__c = workOrders[0].Id, FSL_Comment__c = 'Comment 2' );
        List<FSL_Call_Comments__c> comments = new List<FSL_Call_Comments__c>{ comment1, comment2 };
        insert comments;
        test.startTest();
        FSL_CallCommentsByDateRange.createDeleteCallComment(workOrderslist);
        List<FSL_Call_Comments__c> calllist =[Select Id,FSL_Work_Order__c,FSL_Comment__c from FSL_Call_Comments__c];
        system.assertEquals(1, calllist.size());
        test.stopTest();
    }
    
}