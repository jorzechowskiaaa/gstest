@isTest
public class Plate2VinTest {
    @isTest
	static void test1() {      
        Test.setMock(HttpCalloutMock.class, new Plate2VinMockResponse());
       	FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(
        	Name = 'Plate2Vin',
            Endpoint_URL__c = 'http://something.com',
            Timeout__c = 2000
        );
        insert endpoint;
        Test.startTest();
        Plate2Vin_ResponseWrapper p2vrw = Plate2Vin.getVin('ND','464BLB');
        Test.stopTest();
        System.assert(p2vrw != null);
    }
    private class Plate2VinMockResponse implements HttpCalloutMock{
        public HTTPResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"statusCode":200,"description":"Success","data":{"vehicleSearchResponse":[{"year":"2019","wheel":{"shortestInches":"130","longestInches":"130","driveCount":"4","count":"4"},"vinInformation":{"vinaSeriesCode":"","vinaBodyTypeCode":"","position":"OMVGSBBEKYPNNNNNN","pattern":"CHE  2019 1GNSKHKCCKRR000001-999999","modelYearChar":"K"},"vin":"1GNSKHKC5KR216635","truck":{"trailerAxelCount":"","tongueRatingDescription":"Unknown","tongueRatingCode":"U","rearAxelDescription":"Unknown","rearAxelCode":"U","grossWeightRatingDescription":"6,001 - 10,000#","grossWeightRatingCode":"2","frontAxelDescription":"Unknown","frontAxelCode":"U","cabConfigDescription":"Sport Utility","cabConfigCode":"SUV","brakeTypeDescription":"","brakeTypeCode":"","bedLengthDescription":"Regular","bedLength":"R"},"trim":"K1500 LT","tireSize":{"rearSizeDescription":"18R265","rearSizeCode":"73","rearOption4Description":"","rearOption4Code":"","rearOption3Description":"","rearOption3Code":"","rearOption2Description":"","rearOption2Code":"","rearOption1Description":"","rearOption1Code":"","frontSizeDescription":"18R265","frontSizeCode":"73","frontOption4Description":"","frontOption4Code":"","frontOption3Description":"","frontOption3Code":"","frontOption2Description":"","frontOption2Code":"","frontOption1Description":"","frontOption1Code":""},"tag":"464BLB","state":"ND","options":{"option1TrimDescription":""},"nci":{"seriesCode":"SUB","makeCode":"CHEV"},"model":"SUBURBAN","manufacturer":{"description":"General Motors","code":"C137","baseMSRP":"58800"},"make":"CHEVROLET","fuelType":"Gas","engine":{"vinCode":"C","valvesTotal":"16","valvesPerCylinder":"2","truckDutyTypeDescription":"Medium Duty","truckDutyTypeCode":"ME","modelDescription":"5.3L","modelCode":"080044","manufacturerDescription":"GENERAL MOTORS","manufacturerCode":"080","headConfigDescription":"Overhead Valve","headConfigCode":"OHV","fuelInjectorTypeDescription":"Direct","fuelInjectorTypeCode":"D","fuelCode":"G","displCubicLiters":"5.3","displCubicInches":"323","displCubicCentimeters":"0","cylinderReturnCount":"8","cycleCount":"","carbTypeDescription":"Fuel Injection","carbTypeCode":"F","carbBarrels":"NA","blockTypeDescription":"V-type","blockTypeCode":"V","aspiratedWeightLimitDescription":"Yes","aspiratedWeightLimitCode":"Y","aspiratedTroubleDescription":"No","aspiratedTroubleCode":"N","aspiratedSupportDescription":"No","aspiratedSupportCode":"N"},"driveType":"4RD","commercialTrailer":{"vslMatrDescription":"","vslMatrCode":"","vslCapacity":"0","length":"","bodySpecDescription":"","bodySpecCode":""},"batteryQuote":null,"battery":{"voltageDescription":"","typeDescription":"","typeCode":"","kwRatingCode":""}}],"inputPayload":{"zipCode":"11201","tag":"464BLB","state":"ND","sourceId":"AAANE","clubCode":"420","batteryQuote":true}}}');
            return res;
        }
    }
    /*
    private class MockUtil_ManageAccessTokens extends Util_ManageAccessTokens {
        public override Map<String, String> callOAuth(string integrationName){
            return new Map<String,String>{
                'access_token' => 'mockToken',
                'expires_in' => '2000'
            };
        }
    }
	*/
}