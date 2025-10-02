/*
``@description: util class for ACA specific loigc
  @date: SEP 21, 2023
  @author: Salesforce Services
*/
public with sharing class ACA_CallIntakeUtility {
    
    public static string getMembershipLevel(string mLevel) {
        string membershipLevel;
        switch on mLevel {
            when 'CLASSIC', 'CLSC', 'BASIC' {
                membershipLevel = 'Basic';
            }
            when 'PREMIER', 'PREM' {
                membershipLevel = 'Premier';
            }
            when 'PREMIER RV', 'PRRV', 'PREMIERRV' {
                membershipLevel = 'Premier RV';
            }
            when 'PLUS RV', 'PLRV', 'PLUSRV' {
                membershipLevel = 'Plus RV';
            }
            when 'PLUS' {
                membershipLevel = 'Plus';
            }
            when else {
                membershipLevel = 'Basic';
            }
        }
        return membershipLevel;
    }
}