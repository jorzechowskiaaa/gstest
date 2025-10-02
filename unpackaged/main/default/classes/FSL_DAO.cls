public with sharing class FSL_DAO {
    
    public interface DmlInterface {
        void insertRecords( List<SObject> newRecords );
        void updateRecords( List<SObject> records );
        void upsertRecords( List<SObject> records );
        void deleteRecords( List<SObject> records );

        Database.SaveResult[] insertRecords (List <SObject> newRecords, Boolean allOrNone);
        Database.SaveResult[] updateRecords (List <SObject> records,  Boolean allOrNone);
        Database.UpsertResult[] upsertRecords (List <SObject> records,  Boolean allOrNone);
        Database.DeleteResult[] deleteRecords (List <SObject> records,  Boolean allOrNone);

    }


    public abstract class DmlBase implements DmlInterface {

        public void insertRecords( List<SObject> newRecords ) {
            insert newRecords;
        }

        public void updateRecords( List<SObject> records ) {
            update records;
        }

        public void upsertRecords( List<SObject> records ) {
            upsert records;
        }

        public void deleteRecords( List<SObject> records ) {
            delete records;
        }

        public Database.SaveResult[] insertRecords( List<SObject> newRecords, Boolean allOrNone) {            
            return Database.insert(newRecords, allOrNone);
        }

        public Database.SaveResult[] updateRecords( List<SObject> records, Boolean allOrNone) {            
            return  Database.update(records, allOrNone);
        }

        public Database.UpsertResult[] upsertRecords( List<SObject> records,  Boolean allOrNone) { 
            return Database.upsert(records, allOrNone);
        }

        public Database.DeleteResult[]  deleteRecords( List<SObject> records, Boolean allOrNone) {
            return Database.delete(records, allOrNone);
        }
    }

    public interface IDatabaseResultsProcessor {
        Boolean checkForSpecificError(Database.SaveResult result, StatusCode statusCode, String message);
        Boolean checkForSpecificError(Database.UpsertResult result, StatusCode statusCode, String message);
        Boolean checkForSpecificError(Database.DeleteResult result, StatusCode statusCode, String message);
    }

    public class DatabaseResultsProcessor implements IDatabaseResultsProcessor {

        public Boolean checkForSpecificError(Database.SaveResult result, StatusCode statusCode, String message) {
            return ( result.isSuccess() ) ? false : checkForSpecificError(result.getErrors(), statusCode,  message);
        }

        public Boolean checkForSpecificError(Database.UpsertResult result, StatusCode statusCode, String message) {
            return ( result.isSuccess() ) ? false : checkForSpecificError(result.getErrors(), statusCode,  message);
        }

        public Boolean checkForSpecificError(Database.DeleteResult result, StatusCode statusCode, String message) {
            return ( result.isSuccess() ) ? false : checkForSpecificError(result.getErrors(), statusCode,  message);
        }

        private Boolean checkForSpecificError(List<Database.Error> errors, StatusCode statusCode, String message) {
            for (Database.Error error : errors) {          
                if ( (statusCode != null && error.getStatusCode() == statusCode)  || 
                     (message    != null && error.getMessage()    == message   )  ){ 
                        return true;
                }
            }
            return false;
        }

    }

}