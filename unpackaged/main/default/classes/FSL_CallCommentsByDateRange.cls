public class FSL_CallCommentsByDateRange {
    
/**********
* @Method Name:createDeleteCallComment
* @Parameters:(list<list<workOrder>>)
* @Description: Accepts the the list of workorders list from flow and merge all call comment 
which are assoicated to work order insert it as a single record and delete the all old records of call comments.
* Return the (success OR failure) message along with work order number. 
* @Author: Sanket Thore
* **********/
    
    @InvocableMethod(label='Insert Bulk Call Comments' description='inserting and deleting call comments as we are hitting 151 by flow')
    public static list<list<string>> createDeleteCallComment(list<list<workOrder>> woListFromFlow)
    {
        
        set<string> setofWoId = new set<string>();
        
        for(workOrder wo : woListFromFlow[0])
        {
            setofWoId.add(wo.id);
        }
        
        List<FSL_Call_Comments__c> lstCallComments =[SELECT id, FSL_Comment__c, FSL_Work_Order__c, FSL_Work_Order__r.WorkOrderNumber, 
                                                     CreatedBy.FirstName,CreatedBy.LastName, CreatedDate  
                                                     FROM FSL_Call_Comments__c 
                                                     WHERE FSL_Work_Order__c IN : setofWoId];
        
        map<id, List<FSL_Call_Comments__c>> mapofWOIdvsListOfComment = new map<id, List<FSL_Call_Comments__c>> ();
        
        for(FSL_Call_Comments__c comObje : lstCallComments)
        {  
            if(mapofWOIdvsListOfComment.containsKey(comObje.FSL_Work_Order__c))
            {
                
                List<FSL_Call_Comments__c> commentList1 = new List<FSL_Call_Comments__c>();
                
                commentList1 = (mapofWOIdvsListOfComment.get(comObje.FSL_Work_Order__c));
                
                commentList1.add(comObje);
                
                mapofWOIdvsListOfComment.put(comObje.FSL_Work_Order__c,commentList1);
            }
            else
            {
                List<FSL_Call_Comments__c> commentList2 = new List<FSL_Call_Comments__c>();
                
                commentList2.add(comObje);
                
                mapofWOIdvsListOfComment.put(comObje.FSL_Work_Order__c,commentList2);
            }
            
        }
        List<FSL_Call_Comments__c> listToMerge           = new List<FSL_Call_Comments__c>();
        List<FSL_Call_Comments__c> noNeedtotouch         = new List<FSL_Call_Comments__c>();
        List<list<string>> listOfstringMessgetoReturn    = new List<list<string>>(); 
        List<string> tempstringList                      = new List<string>(); 
        List<FSL_Call_Comments__c> listToInsert          = new List<FSL_Call_Comments__c>();
        map<id, FSL_Call_Comments__c> mapOfwoIdVsCallCom = new map<id, FSL_Call_Comments__c>();
         List<FSL_Call_Comments__c> listtoTempcheck      = new List<FSL_Call_Comments__c>();
        list<string> tempstringList1                     = new list<string>();
        
        
        for(String keys : mapofWOIdvsListOfComment.keyset())
        {
            listtoTempcheck = mapofWOIdvsListOfComment.get(keys);
                     
            if(listtoTempcheck.size()<=1)
            {
                noNeedtotouch.addAll(listtoTempcheck);
                
            }
            else
            {
                listToMerge.addAll(listtoTempcheck);
                
            }
        }
        
        for(FSL_Call_Comments__c Merg: listToMerge)
        {
            String createdDateinText = string.valueOf(Merg.CreatedDate);
            FSL_Call_Comments__c callComment;
            if(mapOfwoIdVsCallCom.containsKey(Merg.FSL_Work_Order__c))
            {
                callComment = mapOfwoIdVsCallCom.get(Merg.FSL_Work_Order__c);
                string comments;
                comments =  ' By ' + Merg.CreatedBy.FirstName + ' '+ Merg.CreatedBy.LastName+ ' On ' + createdDateinText + ' - ' + Merg.FSL_Comment__c ;
                mapOfwoIdVsCallCom.get(Merg.FSL_Work_Order__c).FSL_Comment__c =  mapOfwoIdVsCallCom.get(Merg.FSL_Work_Order__c).FSL_Comment__c + comments;
                
            }
            else{
                callComment = new FSL_Call_Comments__c();
                
                String comments = 'By ' + Merg.CreatedBy.FirstName + ' '+ Merg.CreatedBy.LastName+ ' On ' + createdDateinText + ' - ' + Merg.FSL_Comment__c ;
                callComment.FSL_Comment__c = comments;
                callComment.FSL_Work_Order__c = Merg.FSL_Work_Order__c;
                
                tempstringList1.add(Merg.FSL_Work_Order__r.WorkOrderNumber + ':' + 'Successfully Merged Call Comments');
                
                mapOfwoIdVsCallCom.put(Merg.FSL_Work_Order__c, callComment);
                
            }
            
            listToInsert  = mapOfwoIdVsCallCom.values();
            
        }
        
        if(!listToInsert.isEmpty())
        {
            insert listToInsert;
        }
        
        if(!listToMerge.isEmpty())
        {
            Delete listToMerge;
        }
        
        //logic for returning message for each order where no need to merge
   
        for(FSL_Call_Comments__c obj : noNeedtotouch)
        {
            tempstringList1.add(obj.FSL_Work_Order__r.WorkOrderNumber + ':' + ' No Call Comments Merge Needed');	
        }
        
        listOfstringMessgetoReturn.add(tempstringList1);
        
        system.debug('listOfstringMessgetoReturn' + listOfstringMessgetoReturn);
        
        return listOfstringMessgetoReturn;
        
    }
}