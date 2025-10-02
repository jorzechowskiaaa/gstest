@isTest
global class NationalCreateHaasJsonRequest_Test {
@isTest 
    public  static void validateParse() {
      String json=		'{'+
		'    "type": "disabled_vehicle",'+
		'    "clubCode": "240",'+
		'    "sourceId": "SF",'+
		'    "external_id": "08pEc000001jG4rIAE",'+
		'    "features": ['+
		'        {'+
		'            "type": "point",'+
		'            "geometry": ['+
		'                {'+
		'                    "lat": 39.022929,'+
		'                    "lon": -77.216036'+
		'                }'+
		'            ]'+
		'        }'+
		'    ],'+
		'    "street_name": "Woodcreek Rd",'+
		'    "alert_message": "Disabled Vehicle Ahead",'+
		'    "accuracy": "3"'+
		'}'+
		'';
        NationalCreateHaasJsonRequest obj = NationalCreateHaasJsonRequest.parse(json);
    }
}