/*
* @File Name   : FSL_GetSiteURLTest
* @Description : Apex Test Class for FSL_GetSiteURL class
* @Modification Log
------------------------------------------------------------------------------------------------------------------------
Ver     Date           Author               Modification
---     ----           ------               ------------
*   1.0     5/12/2020    Gowtham Rajsekhar         Created
	
*/
@IsTest
public with sharing class FSL_GetSiteURLTest{
     @IsTest
     static void testgetVisualforceFSLDomain() {
         FSL_GetSiteURL.getVisualforceFSLDomain();
     }
     @IsTest
     static void testgetLightningDomain() {
         FSL_GetSiteURL.getLightningDomain();
     }
     @IsTest
     static void testgetMyDomain() {
         FSL_GetSiteURL.getMyDomain();
     }
     @IsTest
     static void testgetInstance() {
         FSL_GetSiteURL.getInstance();
     }
}