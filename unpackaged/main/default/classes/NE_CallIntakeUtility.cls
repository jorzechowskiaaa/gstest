/*
@description: util class for NE specific loigc
@date: SEP 21, 2023
@author: Salesforce Services
*/
public with sharing class NE_CallIntakeUtility {
    public static string getMembershipLevel(string mLevel) {
        string membershipLevel;
        switch on mLevel {
            when 'BASIC' {
                membershipLevel = 'Basic';
            }
            when 'PREMIER' {
                membershipLevel = 'Premier';
            }
            when 'PREMIER RV', 'PREMIERRV' {
                membershipLevel = 'Premier RV';
            }
            when 'PLUS RV', 'PLUSRV' {
                membershipLevel = 'Plus RV';
            }
            when 'PLUS' {
                membershipLevel = 'Plus';
            }
            when 'EVERYDAY' {
                membershipLevel = 'Everyday';
            }
            when 'NON STANDARD MEMBERSHIP LEVEL' {
                membershipLevel = 'Non Standard';
            }
            when else {
                membershipLevel = 'Basic';
            }
        }
        return membershipLevel;
    }
}