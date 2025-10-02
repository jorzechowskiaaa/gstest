/**** Apex Class Name    :    INTERSFeedbackRequest_Wrapper
    * Description        :    This  is wrapper class for  for INTERSFeedbackInbound
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Nov 3 2021             Created
*********************************************************************************/
public without sharing class INTERSFeedbackRequest_Wrapper {
    
    public string source_club;
    public string member_club;
    public string member_id;
    public string service_year;
    public string service_month;
    public string service_date;
    public string ticket_number;
    public string trouble_code;
    public string authorization_code;
    public string long_tow_miles;
    public string long_tow_kilometers;
    public string rental_days;
    public string authorization_log;
    
    public static INTERSFeedbackRequest_Wrapper parse(String json) {
		return (INTERSFeedbackRequest_Wrapper) System.JSON.deserialize(json, INTERSFeedbackRequest_Wrapper.class);
	}

}