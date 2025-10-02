/**** 
* Apex Class Name    :    INTNationalRBPAPIRequest_Wrapper
* Description        :    This class is used to prepare response for ERS Medallia api call   
* Modification Log   :
* Test Class Name    :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Dhruv Javiya             OCT 29 2021             Initial version
*********************************************************************************/
public class INTNationalRBPAPIRequest_Wrapper {
    public class ProvidedService {
        public Charge charge;
        public String providedServiceType;
        public Integer quantity;
        public String service;
        public String unit;
    }

    public class Charge {
        public String amount;
        public String chargeType;
    }
    
    public class Status {
        public String modifiedDate;
        public String status;
        // public string updateCode;
        // public String eta;
        // public String pta;
        // public Integer waitTime;
    }
    
    public class Comment {
        public String commentDate;
        public String commentType;
        public Contact contact;
        public SystemClass systems;
        public String text;
        public String visibility;
    }
    
    public class SystemClass {
        public String systemId;
        public SystemOrganziation systemOrganization;
    }

    public class SystemOrganziation {
        public String name;
        public String code;
    }

    public class Contact {
        public String contactType;
        public List<Email> emails;
        public String firstName;
        public String lastName; 
        public String middleName;
        public List<Phone> phones;
        public String userId;
        public String suffix;
        //public String title;
    }
    
    public class Phone {
        public String phoneNumber;
        public String phoneType;
        public boolean preferred;
        //public String phoneExtension;
        //public boolean smsOptIn;

        public Phone() {
            //smsOptIn=false;
			preferred = false;
        }
    }

    public class Email {
        public String emailType;
        public String address;
        public boolean optIn;
        
        public Email() {
            optIn = false;
        }
    }
    
    public String callKey;
    public String cdmCallKey;
    public List<Comment> comments;
    public List<ProvidedService> providedService;
    public List<Status> status;
    // public String recordId; 
    
    public INTNationalRBPAPIRequest_Wrapper() {}
}