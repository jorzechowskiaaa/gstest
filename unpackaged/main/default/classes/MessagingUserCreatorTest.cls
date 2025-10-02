@isTest
public class MessagingUserCreatorTest {
    @testSetup
    static void setup() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Test1',
            Phone = '1234567890'
        );
        insert testContact;
    }

    @isTest
    static void testCreateMessagingUser() {
        // Get the test contact
        Contact testContact = [SELECT Id, FirstName, LastName, Phone FROM Contact WHERE FirstName = 'John' AND LastName = 'Test1' LIMIT 1];

        // Create a request for the MessagingUserCreator
        MessagingUserCreator.MessagingUserRequest request = new MessagingUserCreator.MessagingUserRequest();
        request.FirstName = new List<String>{'John'};
        request.LastName = new List<String>{'Test1'};

        // Call the method
        List<MessagingUserCreator.MessagingUserRequest> requests = new List<MessagingUserCreator.MessagingUserRequest>{ request };
        Test.startTest();
        MessagingUserCreator.createMessagingUser(requests);
        Test.stopTest();

        // Verify the MessagingEndUser was created
        List<MessagingEndUser> messagingUsers = [SELECT Id, Name, MessagingPlatformKey, MessageType, MessagingChannelId, MessagingConsentStatus, ContactId FROM MessagingEndUser WHERE ContactId = :testContact.Id];

        System.assertEquals(1, messagingUsers.size(), 'One MessagingEndUser should be created.');
        MessagingEndUser createdUser = messagingUsers[0];
    }
}