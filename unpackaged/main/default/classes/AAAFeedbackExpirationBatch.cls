public class AAAFeedbackExpirationBatch implements Database.Batchable<SObject>, Schedulable{
    public String query;
    Date inputDate = date.today();
    boolean dateMode = false;
    boolean singleMode = false;
    string singleModeInput = '';
    
    public AAAFeedbackExpirationBatch(){}
    
    public AAAFeedbackExpirationBatch (Date input){
        dateMode = true;
        inputDate = input;  //To use this, call like: Database.executeBatch(new AAAFeedbackExpirationBatch(date.newinstance(2025, 5, 12))); the example here would run for May 12th, 2025 (will still take 180 days off)
    }
    
    public AAAFeedbackExpirationBatch (string input){ //To use this, call like: Database.executeBatch(new AAAFeedbackExpirationBatch('FeedbackId'));
        singleMode = true;
        singleModeInput = input;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('QueryLocator:Start');
        inputDate=inputDate.addDays(-180);
        system.debug('QueryLocator:Date:'+inputDate.format());
        query =
            'SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate' +
            ' FROM Feedback__c' +
            ' WHERE' +
            ' Status__c IN (\'Open\', \'In Process\')'+
            ' AND  CreatedDate < '+Datetime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        if(singleMode){
            system.debug('QueryLocator:singleMode');
            query = query + ' AND Id = \''+singleModeInput+'\'';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Feedback__c> scope) {
        system.debug('Scope Size: '+scope.size());
        List<Feedback__c> fbUpdateList = new List<Feedback__c>();
        for(Feedback__c item:scope)
        {
            system.debug('Id:'+item.Id);
            item.Charge_Entitlement__c = false;
            item.Status__c = 'Expired';
            system.debug('Item:'+item);
            fbUpdateList.add(item);
        }
        if (fbUpdateList.size() > 0) {
            update fbUpdateList;
        }
    }
    public void finish(Database.BatchableContext bc) {
        System.debug('Finished batch: AAAFeedbackExpirationBatch');
    }
    public void execute(SchedulableContext ctx) {
        AAAFeedbackExpirationBatch batch = new AAAFeedbackExpirationBatch();
        Database.executeBatch(batch, 50);
    }
}