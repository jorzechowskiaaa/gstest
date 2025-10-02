/**
* Test Suite for testing Chatter Disable Delete app 
* 
* Author: Marcus Ericsson - mericsson@salesforce.com
* Updated 2024-09-24 by John Orzechowski for SSFI-377 - change query for system admin user
*/
@isTest
private class FSL_DisableChatterDeletesTest {
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

    static void deleteAllCustomSettings() {
        Chatter_Delete_Settings__c[] settings = [select id from Chatter_Delete_Settings__c];
        delete(settings);
    }
    
    static testMethod void testFeedItemDeleteSysAdmin() {
        deleteAllCustomSettings();
        User u = [select id from user where alias='C_Admin'];
        
        System.runAs(u) {
            
            Contact c = [select id from contact limit 1];
            
            // test single item delete
            FeedItem p = new FeedItem();
            p.parentId = c.id;
            p.Body = 'force.com labs is great!';
            insert(p);
            delete(p);
        }
    }
    
    static testMethod void testFeedItemDeleteSysAdminFrench() {
        deleteAllCustomSettings();
        User u = [select id from user where profile.name='System Administrator' AND IsActive=True Limit 1];
        
        System.runAs(u) {
            // test single item delete
            FeedItem p = new FeedItem();
            p.parentId = u.id;
            p.Body = 'force.com labs is great!';
            insert(p);
            delete(p);
        }
    }
    
    static testMethod void testFeedCommentDeleteSysAdmin() {
        User u = [select id from user where profile.name='System Administrator' AND IsActive=True Limit 1];
        
        System.runAs(u) {    
            Contact con = [select id from contact limit 1];
            
            // test single item delete
            FeedItem p = new FeedItem();
            p.parentId = con.id;
            p.Body = 'force.com labs is great!';
            
            Database.SaveResult sr = Database.Insert(p);
            System.assert(sr.isSuccess());
            Id pId = sr.getId();
            
            FeedComment c = new FeedComment();
            c.feedItemId = pid;
            c.CommentBody = 'this is a comment';
            insert(c);
            
            delete(c);
        }
    }
    
    static testMethod void testFeedItemDelete() {
        User u = [select id from user where alias='C_Admin'];
        
        System.runAs(u) {
            // The following code runs as user 'u'   
            //insert a dummy contact we can post on
            Contact c = [select id from contact limit 1];
            // test single item delete
            FeedItem p = new FeedItem();
            p.parentId = c.id;
            p.Body = 'force.com labs is great!';
            insert(p);
            try {
                delete(p);
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('disabled'));
            }
            
            
            // now test bulk delete
            FeedItem[] ps = new FeedItem[150];
            for (Integer i = 0; i < 150; i++) {
                ps[i] = new FeedItem();
                ps[i].parentId = c.id;
                ps[i].body = 'force.com labs is great!';
            }
            insert(ps);
            try {
                delete(ps);
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('disabled'));
            }
        }
    }
    
    static testMethod void testFeedItemDeleteFrench() {
        User u = [select id from user where alias='C_Admin'];
        
        System.runAs(u) {
            // test single item delete
            FeedItem p = new FeedItem();
            p.parentId = u.id;
            p.Body = 'force.com labs is great!';
            insert(p);
            try {
                delete(p);
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('disabled'));
            }
        }
    }
    
    static testMethod void testFeedCommentDelete() {
        User u = [select id from user where alias='C_Admin'];
        
        System.runAs(u) {
            // The following code runs as user 'u'   
            //insert a dummy contact we can post on
            //Id cid = insertDummyContact();
            
            // test single item delete
            FeedItem p = new FeedItem();
            //p.parentId = cid;
            p.parentId = userInfo.getUserId();
            p.Body = 'force.com labs is great!';
            
            Database.SaveResult sr = Database.Insert(p);
            System.assert(sr.isSuccess());
            Id pId = sr.getId();
            
            FeedComment c = new FeedComment();
            c.feedItemId = pid;
            c.CommentBody = 'this is a comment';
            insert(c);
            
            try {
                delete(c);
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('disabled'));
            }
            
            
            // now test bulk delete
            FeedComment[] cs = new FeedComment[150];
            for (Integer i = 0; i < 150; i++) {
                cs[i] = new FeedComment();
                cs[i].feeditemid = pid;
                cs[i].CommentBody = 'force.com labs is great!';
            }
            insert(cs);
            try {
                delete(cs);
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('disabled'));
            }
        }
    }
    
    static testMethod void testFeedItemDeleteCustomSetting() {
        User u = [select id from user where alias='C_Admin'];
        try {
            System.runAs(u) {
                // The following code runs as user 'u'   
                //insert a dummy contact we can post on
                Id cid = userInfo.getUserId();
                
                // test single item delete
                FeedItem p = new FeedItem();
                p.parentId = cid;
                p.Body = 'force.com labs is great!';
                insert(p);
                delete(p);
                
                // now test bulk delete
                FeedItem[] ps = new FeedItem[150];
                for (Integer i = 0; i < 150; i++) {
                    ps[i] = new FeedItem();
                    ps[i].parentId = cid;
                    ps[i].body = 'force.com labs is great!';
                }
                insert(ps);
                delete(ps);
            }
        } finally {}
    }
    
    static testMethod void testFeedCommentDeleteCustomSetting() {
        User u = [select id from user where alias='C_Admin'];
        try {
            System.runAs(u) {
                // The following code runs as user 'u'   
                //insert a dummy contact we can post on
                Id cid = userInfo.getUserId();
                
                // test single item delete
                FeedItem p = new FeedItem();
                p.parentId = cid;
                p.Body = 'force.com labs is great!';
                
                Database.SaveResult sr = Database.Insert(p);
                System.assert(sr.isSuccess());
                Id pId = sr.getId();
                
                FeedComment c = new FeedComment();
                c.feedItemId = pid;
                c.CommentBody = 'this is a comment';
                insert(c);
                
                
                delete(c);
                
                // now test bulk delete
                FeedComment[] cs = new FeedComment[150];
                for (Integer i = 0; i < 150; i++) {
                    cs[i] = new FeedComment();
                    cs[i].feeditemid = pid;
                    cs[i].CommentBody = 'force.com labs is great!';
                }
                insert(cs);
                delete(cs);
            }
        }finally{} 
        
    }
    
    
}