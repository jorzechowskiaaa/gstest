@RestResource(urlMapping='/fslupdateworkorder/*')
global without sharing class FSL_UpdateWorkOrder { 
    
    //  ***    Service Tech Team: This class is retired    ***

    /*  
	HttpPost method is used to capture a HttpPOST request has been sent to our rest apex class.  
	Used to request data on the basis of JSON request sent in the URL  
	*/  
    
    // @HttpPost
    // global static string doPost() {
    //     String RequestString = '';
    // 	try{
    		

    // 		RestRequest req = RestContext.request;
    		
    // 		RequestString = req.requestBody.toString();
    // 		system.debug('RequestString'+RequestString);
    //         List<Object> deserialized = (List<Object>)JSON.deserializeuntyped(RequestString);
    //         system.debug(deserialized.size()+' '+deserialized);
    // 		list<workorder> wos = new list<workorder>();
    //         list<string> finaljson = new list<string>();
    //         for(object wo :  deserialized){
    //             system.debug('wo'+wo);
    //             finaljson.add(json.serialize(wo));
    //         }

    //         for(string s : finaljson){
    //             workorder w = (workorder)json.deserialize(s, workorder.class);
    //             wos.add(w);
    //         }
	// 		update wos;
            
	// 		return 'Success';
    // 	}catch(exception ex){
    //         system.debug('Exception:'+ex.getMessage());
    // 		return 'Error: '+ex.getMessage()+' Stack Trace:'+ex.getStackTraceString();
    // 	}
    // }

}