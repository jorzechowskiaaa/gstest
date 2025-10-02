public class Util_ManageAccessTokens {
       /**EMI -- SSFI-662--11-14-2024**/
        public Map<String, String> callOAuth(String endPointMetadata) {
            Map<String, String> accessToken = new Map<String, String>();
            try {
                Http http = new Http();
                HttpRequest oauthrequest = new HttpRequest();
                FSL_Service_Endpoints__c oauthEndpoint;
                if (!Test.isRunningTest()) {
                    oauthEndpoint = FSL_Service_Endpoints__c.getValues(endPointMetadata);
                } else {
                    oauthEndpoint = new FSL_Service_Endpoints__c(Timeout__c = 3000, Endpoint_URL__c = 'testurl', client_id__c = 'test client id', client_secret__c = 'test client secret');
                }
                oauthrequest.setMethod('POST');
                oauthrequest.setHeader('Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8');
                if (oauthEndpoint.Timeout__c != null) {
                    oauthrequest.setTimeout(integer.ValueOf(oauthEndpoint.Timeout__c));
                }
                String oauthbody = '';
                if (!String.isEmpty(oauthEndpoint.Endpoint_URL__c)) {
                    oauthrequest.setEndpoint(oauthEndpoint.Endpoint_URL__c);
                    oauthbody = 'grant_type=client_credentials' +
                        '&client_id=' + EncodingUtil.urlEncode(oauthEndpoint.client_id__c, 'UTF-8') +
                        '&client_secret=' + EncodingUtil.urlEncode(oauthEndpoint.client_secret__c, 'UTF-8');
                }
                if (!String.isEmpty(oauthEndpoint.Scope__c)) {
                    oauthbody += '&scope=' + oauthEndpoint.Scope__c;
                }
                System.debug('Oauth Body: ' + oauthbody);
                oauthrequest.setBody(oauthbody);
                HttpResponse oauthresponse = http.send(oauthrequest);
                System.debug('response: ' + oauthresponse);
                Map<String, Object> oauthresults = (Map<String, Object>)JSON.deserializeUntyped(oauthresponse.getBody());
                System.debug('Deserialized oauthresults: ' + oauthresults);
                System.debug('OAuth response: ' + oauthresponse.getBody());
				
                if (oauthresponse.getStatusCode() == 200) {
                    accessToken.put('access_token', String.valueOf(oauthresults.get('access_token')));
                    accessToken.put('expires_in', String.valueOf(oauthresults.get('expires_in'))); 
                }
            } catch (Exception ex) {
                System.debug('Exception: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            }
            return accessToken;
        }   
        /**EMI -- SSFI-662--11-14-2024**/
        
        public void sendAccessTokenToMetadata(String metadataRecordName, String accessToken){
            Manage_Access_Tokens__c customSetting = Manage_Access_Tokens__c.getInstance(metadataRecordName);
            customSetting.Token__c = accessToken;
            update customSetting;
        }
        
        public String getAccessTokenFromMetadata(String metadataRecordName){
            String accessToken = '';
            Manage_Access_Tokens__c customSetting = Manage_Access_Tokens__c.getInstance(metadataRecordName);
            if(customSetting.Token__c != null){
                accessToken = customSetting.Token__c;
            }
            return accessToken;
        }
    }