@isTest
public class INTNationalRBPAPIResponse_WrapperTest {
    @isTest
    static void parseTest() {
        INTNationalRBPAPIResponse_Wrapper respWrapper = new INTNationalRBPAPIResponse_Wrapper();
        respWrapper.STATUS_CODE = 200;
        respWrapper.ERR_MESSAGE = 'N/A';
        respWrapper.RETRY_COUNT = '0';
        respWrapper.ERR_STATUS = 'N/A';
        respWrapper.responseHeaders = new INTNationalRBPAPIResponse_Wrapper.ResponseHeaders();
        respWrapper.responseHeaders.tranId = '1234';
        respWrapper.responseHeaders.tranCode = '2222';
        respWrapper.responseHeaders.tranStatus = 'GOOD';
        respWrapper.responseHeaders.timeStamp = '2024-01-01';
        respWrapper.responseHeaders.tranStatusDescription = 'description here';

        Boolean hasError = true;
        String jsonResp = JSON.serialize(respWrapper);
        INTNationalRBPAPIResponse_Wrapper respWrapperTest;

        try {
            respWrapperTest = INTNationalRBPAPIResponse_Wrapper.parse(jsonResp);
            hasError = false;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        System.assertEquals(false, hasError, 'Encountered error parsing JSON.');

        try {
            respWrapperTest = INTNationalRBPAPIResponse_Wrapper.parse(null);
            hasError = true;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        System.assertEquals(true, hasError, 'Exception not thrown.');
    }
}