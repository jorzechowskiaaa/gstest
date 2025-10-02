public with sharing class MessagingUserCreator {
    @InvocableMethod
    public static void createMessagingUser(List<MessagingUserRequest> requests) {
        List<MessagingEndUser> messagingUsers = new List<MessagingEndUser>();
        List<String> firstName = requests.get(0).FirstName;
        System.debug('firstName '+firstName);
        List<String> lastName = requests.get(0).LastName;
        System.debug('lastName '+lastName);
      // for(MessagingUserRequest req : requests) {
            Contact contact = [SELECT Id, FirstName, LastName, Phone FROM Contact WHERE FirstName =:firstName[0] AND LastName=:lastName[0] LIMIT 1];
            
            MessagingEndUser u = new MessagingEndUser();
            u.MessagingPlatformKey = contact.Phone; // Use Contact's phone number
            u.MessageType = 'Text'; 
       		// u.MessagingChannelId = '0MjEk00000013wjKAA';//This is for DEV env, SF provided
          	//u.MessagingChannelId = '0MjEa00000000EXKAY'; //Hard coded Id, provided by SF for each org
      		 u.MessagingChannelId = '0MjJx0000005a7hKAA'; //Hard coded Id, provided by SF for each org for prod
            u.MessagingConsentStatus = 'ImplicitlyOptedIn'; 
            u.Name = contact.FirstName + ' ' + contact.LastName; // Use Contact's name
            u.ContactId = contact.Id;
           // messagingUsers.add(u);
       // }
        
        System.debug(u);
       // insert messagingUsers;
       insert u;
    }
    
     public class MessagingUserRequest {
        @InvocableVariable
        public List<String> FirstName;
        
        @InvocableVariable
        public List<String> LastName;
        
       /* @InvocableVariable(required=true)
        public String ContactId;*/
    }
}