/**
 * Created by divnaidu on 3/1/2019.
 */

@IsTest
private class FSL_DisableFeedPostDeleteTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }    

    @isTest
    static void testBehavior() {
        User u = [select id from user where alias='D_Fleet'];
		Chatter_Delete_Settings__c setting = Chatter_Delete_Settings__c.getOrgDefaults();
        setting.Allow_Feed_Post_and_Comment_deletes__c= false;
        update setting;

        system.runas(u){
			Contact c= New contact(lastname='test');
			insert c;            
            FeedItem f = new FeedItem(parentId = c.Id, Body = 'Test');
            insert f;
            system.assertEquals(f.Body, 'Test');            
            FeedComment fc = new FeedComment(CommentBody = 'Test', FeedItemId = f.Id);
            insert fc;
            system.assertEquals(fc.CommentBody, 'Test'); 
            try{
                delete fc;
                delete f;
            }catch(exception e){
                system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
            }
        }
        
    }
}