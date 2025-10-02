/**
 * @description       : Creates Payment records from Allocations and Reimbursements
 * @author            : ksarathy@salesforce.com
 * @group             : 
 * @last modified on  : 05-29-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-16-2024   ksarathy@salesforce.com
 *       05-29-2024   joshtupas@salesforce.com             Included additional query condition for Spend Category metadata
 * @last modified on  : 07-22-2024
 * @last modified by  : Vishnu Popuru
 * Modifications Log
 * Removed comma and added a space in the below line
 * String vendorName = vendorFirstName + ' ' + vendorLastName;
**/
public class BackOfficeReimbursementBatch implements Database.Batchable<SObject>, Schedulable{
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
    public String query; 
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = 
            'SELECT ' +
                'Id,' +
                'Account__c,' +
                'Other_Account__c,' +
                'Approved__c,' +
                'Reimbursement__c,' +
                'Reimbursement__r.Id,' + 
                'Reimbursement__r.Name,' +
                'Reimbursement__r.Use_Alternative_Address__c,' +
                'Reimbursement__r.Member_Id__c,' +
                'Reimbursement__r.ACG_Service_Date__c,' + 
                'Reimbursement__r.First_Name__c,' +
                'Reimbursement__r.Last_Name__c,' +
                'Reimbursement__r.Street_Address__c,' +
                'Reimbursement__r.State_Member__c,' +
                'Reimbursement__r.City_Member__c,' +
                'Reimbursement__r.Zip__c,' +
                'Reimbursement__r.Alt_First_Name__c,' +
                'Reimbursement__r.Alt_Last_Name__c,' +
                'Reimbursement__r.Alt_Street_Address__c,' +
                'Reimbursement__r.Alt_State__c,' +
                'Reimbursement__r.Alt_City__c,'+ 
                'Reimbursement__r.Alt_Zip__c,' +
                'Reimbursement__r.ACG_Status__c,' +
                'Reimbursement__r.ACG_Pay_Date__c,' +
                'Reimbursement__r.ACG_Member_Name__c,' +
            	'Reimbursement__r.Mbr_Street_Address__c,' +
            	'Reimbursement__r.Mbr_City__c,' +
            	'Reimbursement__r.Mbr_State__c,' +
            	'Reimbursement__r.Mbr_Zip__c' +
            ' FROM Allocations__c' +
            ' WHERE Reimbursement__c != NULL' + 
            ' AND Approved__c != NULL' +
            ' AND Account__c != NULL' +
            ' AND Reimbursement__r.ACG_Status__c = \'Decision Approved\'' +
            ' AND Reimbursement__r.ACG_Pay_Date__c = NULL' +
            ' AND Reimbursement__r.Member_Id__c != NULL';

        return Database.getQueryLocator(query);
    }
     
    public void execute(Database.BatchableContext bc, List<Allocations__c> scope) {
        String club = boSettings.Club_Code__c;
        List<Spend_Category__mdt> scMtdList = [
            SELECT Id, Label, Spend_Category__c 
            FROM Spend_Category__mdt
            WHERE Club_Code__c = :club
            AND (NOT DeveloperName LIKE '%_ISP')
        ];
        Map<String, Object> rmbMap = new Map<String, Object>();
        Map<String, String> spendCategoryMap = new Map<String, String>();
        List<Payment__c> paymentsToInsert = new List<Payment__c>();
        List<ACG_Reimbursement__c> reimbursementsToUpdate = new List<ACG_Reimbursement__c>();

        // For Spend category - use the Account__c to get the spend category. 
        // build spend category map
        for (Spend_Category__mdt scMtd : scMtdList) {
            spendCategoryMap.put(scMtd.Label.toUpperCase(), scMtd.Spend_Category__c);
        }

        for (Allocations__c alloc : scope) {
            String spendCat = alloc.Account__c;

            // ACA uses Other_Account__c as spend categories
            if (club == '212') {
                spendCat = alloc.Other_Account__c;
            }

            if (rmbMap.get(alloc.Reimbursement__c) == null) {
                Map<String, Decimal> allocMap = new Map<String, Decimal>();

                allocMap.put(spendCat, alloc.Approved__c);

                Map<String, Object> container = new Map<String, Object>{
                    'reimbursement' => alloc.Reimbursement__r,
                    'allocations' => allocMap 
                };

                rmbMap.put(alloc.Reimbursement__c, container);
            } else {
                Map<String, Object> tempContainer = (Map<String, Object>) rmbMap.get(alloc.Reimbursement__c);
                Map<String, Decimal> tempMap = (Map<String, Decimal>) tempContainer.get('allocations');

                if (tempMap.get(spendCat) == null) {
                    tempMap.put(spendCat, alloc.Approved__c);
                } else {
                    Decimal prevVal = tempMap.get(spendCat);
    
                    tempMap.put(spendCat, prevVal + alloc.Approved__c);
                }

                tempContainer.put('allocations', tempMap);
                rmbMap.put(alloc.Reimbursement__c, tempContainer);
            }
        }
        
        for (String rmbId : rmbMap.keySet()) {
            // Create a unique# for Payment.Line_Row__c     
            Integer lineRow = 1;
            Map<String, Object> container = (Map<String, Object>) rmbMap.get(rmbId);
            ACG_Reimbursement__c reimbursement = (ACG_Reimbursement__c) container.get('reimbursement');
            Map<String, Decimal> allocMap = (Map<String, Decimal>) container.get('allocations');
            String vendorFirstName = reimbursement.First_Name__c;
            String vendorLastName  = reimbursement.Last_Name__c;
            String address = reimbursement.Mbr_Street_Address__c;
            String city = reimbursement.Mbr_City__c;
            String state = reimbursement.Mbr_State__c;
            String zip = reimbursement.Mbr_Zip__c;

            if (reimbursement.Use_Alternative_Address__c) {
                vendorFirstName = reimbursement.Alt_First_Name__c;
                vendorLastName = reimbursement.Alt_Last_Name__c;
                address = reimbursement.Alt_Street_Address__c;
                city = reimbursement.Alt_City__c;
                state = reimbursement.Alt_State__c;
                zip = reimbursement.Alt_Zip__c;
            }

            String vendorName = vendorFirstName + ' ' + vendorLastName;
            for (String spendCat : allocMap.keySet()) {
                Payment__c payment = new Payment__c(
                    Document_Number__c = reimbursement.Name,
                    Vendor_Id__c = reimbursement.Member_Id__c,
                    Document_Date__c = System.today(),
                    Address_1__c = address,
                    City__c = city,
                    Vendor_Name__c = vendorName,
                    Document_Description__c = 'Member Reimbursement',
                    Line_Row__c =  lineRow,  // Unique number for a Reimbursement
                    State__c = state,
                    Zip__c = zip,
                    Spend_Category__c = spendCategoryMap.get(spendCat),
                    Amount__c = allocMap.get(spendCat),
                    Reimbursement__c = reimbursement.Id
                );             

                payment.Item_Description__c = spendCat;
                paymentsToInsert.add(payment);
                lineRow++;
            }

            reimbursement.ACG_Pay_Date__c = System.today();
            reimbursement.ACG_Status__c = 'Ready for Payment'; 
            reimbursementsToUpdate.add(reimbursement);
        }

        insert paymentsToInsert;
        update reimbursementsToUpdate;    
    }   
     
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch Job Complete');
    }

    public void execute(SchedulableContext ctx) {
        BackOfficeReimbursementBatch batch = new BackOfficeReimbursementBatch();

        Database.executeBatch(batch, 200);
    }
}