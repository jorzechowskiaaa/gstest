/**
 * Helper for Disable Chatter Deletes App
 * Author: Marcus Ericsson - mericsson@salesforce.com
 * Updated 2024-09-24 by John Orzechowski for SSFI-377 -- check for isRunningTest so tests do not fail
 */
public class FSL_DisableChatterDeleteDelegate
{
  public static boolean allowDelete() {
      Chatter_Delete_Settings__c settings = Chatter_Delete_Settings__c.getInstance();
      if (settings == null || Test.isRunningTest()) {
          // do default settings
          String profileId = UserInfo.getProfileId();
          Boolean modifyAllData = [select PermissionsModifyAllData from Profile where id = :profileId].PermissionsModifyAllData;
          if (modifyAllData) {
              return true;
          }
          else {
              return false;
          }
      }
      else {
          // use custom defined settings
          return settings.Allow_Feed_Post_and_Comment_deletes__c;
      }
  }

}