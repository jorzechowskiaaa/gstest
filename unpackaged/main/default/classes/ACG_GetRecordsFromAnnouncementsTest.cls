/*
* @description: Test class for ACG_GetRecordsFromAnnouncements
* @date: September 28th,2021
* author: Deloitte USI
*/
 @isTest
public class ACG_GetRecordsFromAnnouncementsTest {
    //@testSetup
    public static void testSetup(){
    /* Test data for getRecordsFromAnnouncementTest()*/
        Announcements__c obj = New Announcements__c();
        obj.Name='@Test Announcement Rec#';
        obj.Announcement_Description__c= '*# Announcement Description #*';
        obj.Status__c='Active';
        obj.Approval_Status__c='Approved';
        obj.Effective_Date__c = System.today().addDays(-10);
		obj.Expiration_Date__c = System.today().addDays(10);
		obj.Service_Types__c = 'Battery';
        obj.Announcement_Priority__c = 'High';
      	obj.Announcement_Location__c = 'Case';
        obj.Case_Record_Type__c = 'ERS';
        insert obj;
        
        Id ERS_recType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case objCase = new Case(Subject='@Test GetAnnoucement Record@', RecordTypeId = ERS_recType, ACG_Service_Type__c = 'Battery' );
        insert objCase;
        
    }
     @isTest
    Public static void getRecordsFromAnnouncementTest(){
        
        /* Test data for getRecordsFromAnnouncementTest()*/
        Announcements__c announcementRecord = New Announcements__c();
        announcementRecord.Name='@Test Announcement Rec#';
        announcementRecord.Announcement_Description__c= '*# Announcement Description #*';
        announcementRecord.Status__c='Active';
        announcementRecord.Approval_Status__c='Approved';
        announcementRecord.Effective_Date__c = System.today().addDays(-10);
		announcementRecord.Expiration_Date__c = System.today().addDays(10);
		announcementRecord.Service_Types__c = 'Battery';
        announcementRecord.Announcement_Priority__c = 'High';
      	announcementRecord.Announcement_Location__c = 'Case';
        announcementRecord.Case_Record_Type__c = 'ERS';
        insert announcementRecord;
        
        Id ERS_recType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case objCase = new Case(Subject='@Test GetAnnoucement Record@', RecordTypeId = ERS_recType, ACG_Service_Type__c = 'Battery' );
        insert objCase;
        
        //Case objCase = [SELECT Id FROM Case WHERE Subject ='@Test GetAnnoucement Record@' LIMIT 1];
        //Announcements__c announcementRecord=[SELECT Id FROM Announcements__c WHERE Name ='@Test Announcement Rec#' LIMIT 1];
        
       	Map<Id, Announcements__c> mapRecords = new Map<Id, Announcements__c>(ACG_GetRecordsFromAnnouncements.getRecordsFromAnnouncement(objCase.Id));
     	System.assertEquals(true,(mapRecords.keySet()).contains(announcementRecord.Id),'Record Not Found: '+mapRecords);
    }

}