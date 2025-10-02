/**
* @File Name : WatchListHelper.cls
* @Description : For https://aaa-ne.atlassian.net/browse/SSFI-931, Gets active warning for ERS watch list
* @Author : John Orzechowski
* @Last Modified On : June 4, 2025 - updated getWatchListStatus to handle null Account_Member_Id
**/


public without sharing class WatchListHelper {
	@AuraEnabled(cacheable=true)
    public static String getWarningText() {
           Winter_Advisory__c[] adv = [
                SELECT Advisory_Message_Display__c 
                FROM Winter_Advisory__c
                WHERE RecordType.DeveloperName = 'ERS_Watch_List' 
                AND Active__c = true
                Limit 1
            ]; 
            
            if (adv.size() > 0) {
             return adv[0].Advisory_Message_Display__c;
            }
            else {
                return null;
            }

    }

    @AuraEnabled(cacheable=true)
    public static Boolean getWatchListStatus(String AAA_ACA_Club_Code, String AAA_ACA_MembershipID, String AAA_ACA_AssociateId, String Account_Member_Id) {
        
        
        ERS_Watch_List__c[] ewlm = new List<ERS_Watch_List__c>(); 

        if( Account_Member_Id?.length() == 16 ) {
            String AccountClubCode = String.escapeSingleQuotes(Account_Member_Id).mid(3,3); 
            String AccountMembershipId = String.escapeSingleQuotes(Account_Member_Id).mid(6,7);
            String AccountAssociateId = String.escapeSingleQuotes(Account_Member_Id).mid(13,2);
            

            ewlm = [
                SELECT Id 
                FROM ERS_Watch_List__c
                WHERE (( AAA_ACA_Club_Code__c = :AAA_ACA_Club_Code 
                AND AAA_ACA_MembershipID__c = :AAA_ACA_MembershipID
                AND AAA_ACA_AssociateID__c = :AAA_ACA_AssociateId ) 
                OR ( AAA_ACA_Club_Code__c = :AccountClubCode
                AND AAA_ACA_MembershipID__c = :AccountMembershipId 
                AND AAA_ACA_AssociateID__c = :AccountAssociateId ))
                AND Active__c = true
                LIMIT 1
            ];
        } else {
            ewlm = [
                SELECT Id 
                FROM ERS_Watch_List__c
                WHERE  AAA_ACA_Club_Code__c = :AAA_ACA_Club_Code 
                AND AAA_ACA_MembershipID__c = :AAA_ACA_MembershipID
                AND AAA_ACA_AssociateID__c = :AAA_ACA_AssociateId 
                AND Active__c = true
                LIMIT 1
            ];
        }

        if (ewlm.size() > 0) {
            return TRUE; 
        }
        else {
            return FALSE;
        } 


    }
}