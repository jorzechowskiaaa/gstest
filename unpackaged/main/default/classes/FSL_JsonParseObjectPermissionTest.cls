@isTest
public class FSL_JsonParseObjectPermissionTest {
    static testmethod void parseObjectPermissionJsonTest(){ 
        Id objectId = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = 'FSL_Application_Log__c'].DurableId;
       // System.assertEquals(objectId, '');
        FSL_JsonParseObjectPermission jsonObjPerm = new FSL_JsonParseObjectPermission();
        String jsonStringEnable = '{"enableRead":["'+ObjectId+'"],"enableCreate":["'+ObjectId+'"],"enableEdit":["'+objectId+'"],"enableDelete":["'+objectId+'"],"enableViewAll":["'+objectId+'"],"enableModifyAll":["'+objectId+'"]}';
        jsonObjPerm.parseObjectPermissionJson(jsonStringEnable);
        String jsonStringDisable = '{"disableRead":["'+ObjectId+'"],"disableCreate":["'+ObjectId+'"],"disableEdit":["'+objectId+'"],"disableDelete":["'+objectId+'"],"disableViewAll":["'+objectId+'"],"disableModifyAll":["'+ObjectId+'"]}';
        jsonObjPerm.parseObjectPermissionJson(jsonStringDisable);
    }
}