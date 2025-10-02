/**** Apex Class Name    :    INTERSAuthorize
    * Description        :    API class  to receive the feedback record when member
    *                         has serviced outside of member home club service territory.  
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri              Nov 3 2021             Created
*********************************************************************************/
@RestResource(urlMapping='/ERSFeedback/*')
global without sharing class INTERSFeedbackInbound {

    /***
    * Method name        : getERSFeedback
    * Description        : This method  returns the ERS authorization details 
    */ 
    @HttpPost
    global static void getERSFeedback(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        INTERSFeedbackRequest_Wrapper reqBody = new INTERSFeedbackRequest_Wrapper();
        string strjson;
        Feedback__c objRec = new Feedback__c();
        try{
            reqBody = INTERSFeedbackRequest_Wrapper.parse(request.requestBody.toString());
            objRec =  updateFeedbackRecord(reqBody);
            if(objRec.Id!=null){
            strjson = jsonGenerator(ACG_ConstantsClass.ZERO,ACG_ConstantsClass.OK,objRec.Name);
            response.statusCode = ACG_ConstantsClass.STATUS_CODE_SUCCESS;
            } else{
                strjson = jsonGenerator(ACG_ConstantsClass.NINE,ACG_ConstantsClass.NOT_FOUND,null);
                response.statusCode = ACG_ConstantsClass.ERROR_CODE404;
            }
            response.responseBody = Blob.valueOf(strjson);
            FSL_ApplicationLogCreator.integrationLog (request.requestBody.toString(),strjson,'ERS Feedback Inbound API','ERS Feedback Inbound',false,'',null);
        } catch(Exception e){
            response.statusCode = ACG_ConstantsClass.ERROR_CODE400;
            strjson = jsonGenerator(ACG_ConstantsClass.ONE,ACG_ConstantsClass.BAD_REQUEST,null);
            response.responseBody = Blob.valueOf(strjson);
            String ErrorMessage = e.getStackTraceString()+'Line Number:'+e.getLineNumber()+''+e.getMessage();
            FSL_ApplicationLogCreator.integrationLog (request.requestBody.toString(),strjson,'ERS Feedback Inbound API','ERS Feedback Inbound',true,ErrorMessage,null);
        }
    }
    
    /***
    * Method name                  : jsonGenerator
    * Description                  : This method  used to generate the JSON in specified format
    * Return                       : Json String 
    */ 
    Public static string jsonGenerator(string returncode,string message,string feedbackName){
         JSONGenerator gen = JSON.createGenerator(true);
         gen.writeStartObject();
         gen.writeStringField('return_cd',returncode);
         gen.writeStringField('message',message);
         if(feedbackName!=null){
         gen.writeStringField('receive_num',feedbackName);
         }
         gen.writeEndObject();
        return gen.getAsString();
        
    }
    
    /***
    * Method name                  : updateFeedbackRecord
    * Description                  : This method  used to updates the feedback record
    * Return  Feedback__C         : Feedback record 
    */ 
    public static Feedback__C updateFeedbackRecord(INTERSFeedbackRequest_Wrapper reqWrapper){
        Feedback__C objfbk = new Feedback__C();
        List<Feedback__C> lstfbk = new List<Feedback__C>();
        if(!String.isEmpty(reqWrapper.member_id)&& !String.isEmpty(reqWrapper.authorization_code)){
        lstfbk = [select id,Name,Authorization_Code__c,Member_ID__c from  feedback__C 
                      where Authorization_Code__c=:(reqWrapper.authorization_code).replace('+','').trim()];
        }
        List<FSL_Trouble_Code_Mappings__mdt> lstoftroublecodes = [Select MasterLabel,Trouble_Code__c from FSL_Trouble_Code_Mappings__mdt];
        Map<string,string> mapoftroublecodes = new Map<string,string>();
        for(FSL_Trouble_Code_Mappings__mdt tcode:lstoftroublecodes){
            mapoftroublecodes.put(tcode.Trouble_Code__c,tcode.MasterLabel);
        }
        if(!lstfbk.isempty()){
             objfbk = lstfbk[0];
        //    objfbk.Tracking_Number__c = (reqWrapper.ticket_number).replace('+','').trim();
            /**EMI--211**/
           if(reqWrapper.long_tow_miles != null){
                 objfbk.Long_Tow_Miles__c = (reqWrapper?.long_tow_miles).replace('+','').trim();
            }
            
            //objfbk.Long_Tow_Miles__c = (reqWrapper?.long_tow_miles).replace('+','').trim();//EMI
            if(reqWrapper.long_tow_kilometers != null){
                objfbk.Long_Tow_Kilometers__c = (reqWrapper?.long_tow_kilometers).replace('+','').trim();
            }
            /**EMI--211**/
            //objfbk.Long_Tow_Kilometers__c = (reqWrapper?.long_tow_kilometers).replace('+','').trim();//EMI
            /**EMI--236**/
            
            if(reqWrapper.rental_days != null){
                  objfbk.Rental_Days__c = (reqWrapper?.rental_days).replace('+','').trim();
            }
            /**EMI--236**/
           // objfbk.Rental_Days__c = (reqWrapper?.rental_days).replace('+','').trim();
            objfbk.Source_Club__c = (reqWrapper?.source_club).replace('+','').trim();
            // AGB 4/17/2025 SSFI-1003
            if(reqWrapper.trouble_code != null && reqWrapper.trouble_code != '')
            {
                objfbk.Trouble_Code__c = (reqWrapper.trouble_code).replace('+','').trim();
            }
            if(reqWrapper.ticket_number != null && reqWrapper.ticket_number != '')
            {
                objfbk.Ticket_Number__c = (reqWrapper.ticket_number).replace('+','').trim();
            }
            //end AGB 4/17/2025 SSFI-1003
         //   objfbk.Trouble_Code__c = (reqWrapper.trouble_code).replace('+','').trim(); -- none of this?
      //  objfbk.Service_Call_ID__c = (reqWrapper.ticket_number).replace('+','').trim();  -- check to see if work order
            objfbk.Service_Date__c = date.parse((reqWrapper.service_month).replace('+','').trim()+'/'+(reqWrapper.service_date).replace('+','').trim()+'/'+(reqWrapper.service_year).replace('+','').trim());
            objfbk.Member_Club__c = (reqWrapper.member_club).replace('+','').trim();
             objfbk.Time_Stamp__c = system.today().format();
            objfbk.Charge_Entitlement__c=true; 
            objfbk.Status__c = 'Closed';
        }else{
            
        //    objfbk.Tracking_Number__c = (reqWrapper.ticket_number).replace('+','').trim();
            /**EMI--211**/
            if(reqWrapper.long_tow_miles != null){
                 objfbk.Long_Tow_Miles__c = (reqWrapper?.long_tow_miles).replace('+','').trim();
            }
           // objfbk.Long_Tow_Miles__c = (reqWrapper?.long_tow_miles).replace('+','').trim();//EMI
            if(reqWrapper.long_tow_kilometers != null){
                objfbk.Long_Tow_Kilometers__c = (reqWrapper?.long_tow_kilometers).replace('+','').trim();
            }
            /**EMI--211**/
            //objfbk.Long_Tow_Kilometers__c = (reqWrapper?.long_tow_kilometers).replace('+','').trim();//EMI
              /**EMI--236**/
                
                if(reqWrapper.rental_days != null){
                      objfbk.Rental_Days__c = (reqWrapper?.rental_days).replace('+','').trim();
                }
               /**EMI--236**/
              //  objfbk.Rental_Days__c = (reqWrapper?.rental_days).replace('+','').trim();
            objfbk.Source_Club__c = (reqWrapper?.source_club).replace('+','').trim();
            // AGB 4/17/2025 SSFI-1003
            if(reqWrapper.trouble_code != null && reqWrapper.trouble_code != '')
            {
                objfbk.Trouble_Code__c = (reqWrapper.trouble_code).replace('+','').trim();
            }
            if(reqWrapper.ticket_number != null && reqWrapper.ticket_number != '')
            {
                objfbk.Ticket_Number__c = (reqWrapper.ticket_number).replace('+','').trim();
            }
            //end AGB 4/17/2025 SSFI-1003
          //  objfbk.Trouble_Code__c = (reqWrapper.trouble_code).replace('+','').trim(); //need to double check
        //objfbk.Service_Call_ID__c = (reqWrapper.ticket_number).replace('+','').trim(); //need to double check
            objfbk.Service_Date__c = date.parse((reqWrapper.service_month).replace('+','').trim()+'/'+(reqWrapper.service_date).replace('+','').trim()+'/'+(reqWrapper.service_year).replace('+','').trim());
            objfbk.Member_Club__c = (reqWrapper.member_club).replace('+','').trim();
            objfbk.Time_Stamp__c = system.today().format();
            objfbk.Member_ID__c=reqWrapper.member_id.replace('+','').trim();
            objfbk.Authorization_Code__c=reqWrapper?.authorization_code.replace('+','').trim();
           // objfbk.Charge_Entitlements__c=true;
             }
             
        if(objfbk!=null){
            upsert objfbk;
        } 
        
        
        return objfbk;
    }
}