/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 */

public with sharing class FSL_FeatureFlag {

    // *********************************************
   // * Factory
   // *********************************************
   public interface IFactory {
       IFeatureFlagService createService();
   }

   public class Factory implements IFactory {
       public IFeatureFlagService createService() {
           IFeatureFlagDAO dao = createDAO();
           return new FeatureFlagService( dao );
       }

       private IFeatureFlagDAO createDAO() {
           return new FeatureFlagDAO();
       }
   }

   // *********************************************
   // * DAO
   // *********************************************
   public interface IFeatureFlagDAO extends FSL_DAO.DmlInterface {
       List<FSL_Feature_Flag__mdt> fetchFeatureFlags();
       List<FSL_Feature_Flag__mdt> fetchFeatureFlagByName(String labelName);
   }

   public class FeatureFlagDAO extends FSL_DAO.DmlBase implements IFeatureFlagDAO{
       public List<FSL_Feature_Flag__mdt> fetchFeatureFlags(){
           return [SELECT DeveloperName,Enabled__c,Id,Label,Language,MasterLabel,NamespacePrefix,QualifiedApiName FROM FSL_Feature_Flag__mdt];
       }   
       public List<FSL_Feature_Flag__mdt> fetchFeatureFlagByName(String labelName){
           return [SELECT DeveloperName,Enabled__c,Id,Label,Language,MasterLabel,NamespacePrefix,QualifiedApiName FROM FSL_Feature_Flag__mdt
                   WHERE Label =: labelName];  
       }   
   }
   // *********************************************
   // * Service
   // *********************************************
   public interface IFeatureFlagService {
    List<FSL_Feature_Flag__mdt> getFeatureFlags();
    List<FSL_Feature_Flag__mdt> getFeatureFlagByName(String labelName);
   }

   public class FeatureFlagService implements IFeatureFlagService {
       private IFeatureFlagDAO dao;
       public FeatureFlagService(IFeatureFlagDAO dao) {
           this.dao = dao;
       }
       public List<FSL_Feature_Flag__mdt> getFeatureFlags() {
           return dao.fetchFeatureFlags();
       }

       public List<FSL_Feature_Flag__mdt> getFeatureFlagByName(String labelName) {
           return dao.fetchFeatureFlagByName(labelName);
       }
   }
}