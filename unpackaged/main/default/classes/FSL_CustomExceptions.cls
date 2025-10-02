/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-18-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   12-18-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
 * 2.0   01-29-2021   Fixed a typo in the class spelling
**/
public with sharing class FSL_CustomExceptions {  
    public class ExclusiveRowLockException extends Exception {}
    public class NoCandidateFoundException extends Exception {}
}