global class FSL_TruckSkillDMLBatch implements Database.Batchable<sObject>{
    
    global final List<SObject> listObjectsForDML;
    global final String dmlOperation;
    
    global FSL_TruckSkillDMLBatch(List<SObject> sobjectList, String operation) {
        this.dmlOperation = operation;
        this.listObjectsForDML = sobjectList;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){
      return listObjectsForDML;
    }
   
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
            if(dmlOperation == 'Upsert') {
                upsert scope;
                System.debug('Upsert done Succfully!!!!');
            }
        }catch(Exception ex) {
            System.debug('Error while Upsert is happening!!!!!!');
        }
        try{
            if(dmlOperation == 'Update') {
                update scope;
                System.debug('Updated Succfully!!!!');
            }
        }catch(Exception ex) {
            System.debug('Error while Updating!!!!!!');
        }
        try{
            if(dmlOperation =='Insert') {
                insert scope;
                System.debug('Inserted Succfully!!!!');
            }
        }catch(Exception ex) {
            System.debug('Error while Inserting!!!!!!');
        }
        try{
            if(dmlOperation == 'Delete') {
                delete scope;
                System.debug('Deleted Succfully!!!!');
            }
        }catch(Exception ex) {
            System.debug('Error while Deleting!!!!!!');
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}