/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 */

public with sharing class FSL_ConfigurationSetting {

     // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IConfigurationSettingService createService();
    }

    public class Factory implements IFactory {
        public IConfigurationSettingService createService() {
            IConfigurationSetttingDAO dao = createDAO();
            return new ConfigurationSettingService( dao );
        }

        private IConfigurationSetttingDAO createDAO() {
            return new ConfigurationSetttingDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IConfigurationSetttingDAO extends FSL_DAO.DmlInterface {
        List<FSL_Configuration_Setting__mdt> fetchConfigurationSettings();
        List<FSL_Configuration_Setting__mdt> fetchConfigurationSettingByName(String labelName);
    }

    public class ConfigurationSetttingDAO extends FSL_DAO.DmlBase implements IConfigurationSetttingDAO{
        public List<FSL_Configuration_Setting__mdt> fetchConfigurationSettings(){
            return [SELECT Activation_Date__c,DeveloperName,Enabled__c,
                            Id,Label,Language,MasterLabel,NamespacePrefix,No_of_Retries__c,
                            QualifiedApiName,Release_Number__c 
                    FROM FSL_Configuration_Setting__mdt ];
        }   
        public List<FSL_Configuration_Setting__mdt> fetchConfigurationSettingByName(String labelName){
            return [SELECT Activation_Date__c,DeveloperName,Enabled__c,Id,
                            Label,Language,MasterLabel,NamespacePrefix,No_of_Retries__c,
                            QualifiedApiName,Release_Number__c 
                    FROM FSL_Configuration_Setting__mdt 
                    WHERE Label =: labelName];  
        }   
    }
    // *********************************************
    // * Service
    // *********************************************
    public interface IConfigurationSettingService {
     List<FSL_Configuration_Setting__mdt> getConfigurationSettings();
     List<FSL_Configuration_Setting__mdt> getConfigurationSettingByName(String labelName);
    }

    public class ConfigurationSettingService implements IConfigurationSettingService {
        private IConfigurationSetttingDAO dao;
        public ConfigurationSettingService(IConfigurationSetttingDAO dao) {
            this.dao = dao;
        }
        public List<FSL_Configuration_Setting__mdt> getConfigurationSettings() {
            return dao.fetchConfigurationSettings();
        }

        public List<FSL_Configuration_Setting__mdt> getConfigurationSettingByName(String labelName) {
            return dao.fetchConfigurationSettingByName(labelName);
        }
    }
}