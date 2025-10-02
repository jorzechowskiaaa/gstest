/**
 * Author: Marcus Ericsson - mericsson@salesforce.com
 */
trigger FSL_DisableFeedCommentDeletes on FeedComment (before delete)
{
    FSL_TriggerDispatcher.run(new FSL_DisableFeedCommentDeletesHandler());

    //======================================================================================================================================
    private class FSL_DisableFeedCommentDeletesHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
        
        List<FeedComment> newList = Trigger.new;
        List<FeedComment> oldList = Trigger.old;
        Map<Id, FeedComment> newMap = (Map<Id, FeedComment>)Trigger.newMap;
        Map<Id, FeedComment> oldMap = (Map<Id, FeedComment>)Trigger.oldMap;

        //========================================================================================================================
        //========================================================================================================================
        public override Boolean isDisabled() {
            return FSL_TriggerUtility.isDisabled('FeedComment');
        }

        //========================================================================================================================
        //========================================================================================================================
        public override void beforeDelete() {
            if (!FSL_DisableChatterDeleteDelegate.allowDelete()) {
                for(FeedComment f : oldList){
                    f.addError('Your administrator has disabled feed post and comment deletions.');
                }
            }
        }


        //========================================================================================================================
        //========================================================================================================================
        //========================================================================================================================

    }
}