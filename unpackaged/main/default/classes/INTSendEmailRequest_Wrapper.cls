/**** Apex Class Name    :    INTSendEmailRequest_Wrapper
* Description        :    This class is used to prepare request for sending an email   
* Modification Log   :
* Test Class Name    :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Oct 20 2021             Created
*********************************************************************************/
public without sharing class INTSendEmailRequest_Wrapper {
	public List<String> toAddresses = new List<String>();
    public String senderDisplayName;
    public String templateName;
    public String whatId;
    public String targetObjectId;
    public Boolean treatTargetObjectAsRecipient;
    public Boolean saveAsActivity;
    
}