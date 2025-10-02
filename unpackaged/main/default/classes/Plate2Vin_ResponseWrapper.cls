public without sharing class Plate2Vin_ResponseWrapper{
    @AuraEnabled
	public Integer statusCode;	//200
    @AuraEnabled
	public String description;	//Success
    @AuraEnabled
	public cls_data data;

	class cls_data {
        @AuraEnabled
		public cls_inputPayload inputPayload;
        @AuraEnabled
		public cls_vehicleSearchResponse[] vehicleSearchResponse;
	}
	class cls_inputPayload {
        @AuraEnabled
		public String state;	//ND
        @AuraEnabled
		public String tag;	//464BLB
        @AuraEnabled
		public boolean batteryQuote;
        @AuraEnabled
		public String zipCode;	//11201
        @AuraEnabled
		public String clubCode;	//420
        @AuraEnabled
		public String sourceId;	//ABC123
	}
	class cls_vehicleSearchResponse {
        @AuraEnabled
		public String vin;	//1GNSKHKC5KR216635
        @AuraEnabled
		public String tag;	//464BLB
        @AuraEnabled
		public String state;	//ND
        @AuraEnabled
		public String driveType;	//4RD
        @AuraEnabled
		public String fuelType;	//Gas
        @AuraEnabled
		public String make;	//CHEVROLET
        @AuraEnabled
		public String model;	//SUBURBAN
        @AuraEnabled
		public String year;	//2019
        @AuraEnabled
		public String trim;	//K1500 LT
        @AuraEnabled
		public cls_battery battery;
        @AuraEnabled
		public cls_commercialTrailer commercialTrailer;
        @AuraEnabled
		public cls_engine engine;
        @AuraEnabled
		public cls_tireSize tireSize;
        @AuraEnabled
		public cls_manufacturer manufacturer;
        @AuraEnabled
		public cls_nci nci;
        @AuraEnabled
		public cls_options options;
        @AuraEnabled
		public cls_truck truck;
        @AuraEnabled
		public cls_vinInformation vinInformation;
        @AuraEnabled
		public cls_wheel wheel;
        @AuraEnabled
		public cls_batteryQuote batteryQuote;
	}
	class cls_battery {
        @AuraEnabled
		public String kwRatingCode;	//
        @AuraEnabled
		public String typeCode;	//
        @AuraEnabled
		public String typeDescription;	//
        @AuraEnabled
		public String voltageDescription;	//
	}
	class cls_commercialTrailer {
        @AuraEnabled
		public String bodySpecCode;	//
        @AuraEnabled
		public String bodySpecDescription;	//
        @AuraEnabled
		public String length;	//
        @AuraEnabled
		public String vslCapacity;	//0
        @AuraEnabled
		public String vslMatrCode;	//
        @AuraEnabled
		public String vslMatrDescription;	//
	}
	class cls_engine {
        @AuraEnabled
		public String aspiratedSupportCode;	//N
        @AuraEnabled
		public String aspiratedSupportDescription;	//No
        @AuraEnabled
		public String aspiratedTroubleCode;	//N
        @AuraEnabled
		public String aspiratedTroubleDescription;	//No
        @AuraEnabled
		public String aspiratedWeightLimitCode;	//Y
        @AuraEnabled
		public String aspiratedWeightLimitDescription;	//Yes
        @AuraEnabled
		public String blockTypeCode;	//V
        @AuraEnabled
		public String blockTypeDescription;	//V-type
        @AuraEnabled
		public String carbBarrels;	//NA
        @AuraEnabled
		public String carbTypeCode;	//F
        @AuraEnabled
		public String carbTypeDescription;	//Fuel Injection
        @AuraEnabled
		public String cylinderReturnCount;	//8
        @AuraEnabled
		public String cycleCount;	//
        @AuraEnabled
		public String displCubicCentimeters;	//0
        @AuraEnabled
		public String displCubicInches;	//323
        @AuraEnabled
		public String displCubicLiters;	//5.3
        @AuraEnabled
		public String fuelCode;	//G
        @AuraEnabled
		public String fuelInjectorTypeCode;	//D
        @AuraEnabled
		public String fuelInjectorTypeDescription;	//Direct
        @AuraEnabled
		public String headConfigCode;	//OHV
        @AuraEnabled
		public String headConfigDescription;	//Overhead Valve
        @AuraEnabled
		public String modelCode;	//080044
        @AuraEnabled
		public String modelDescription;	//5.3L
        @AuraEnabled
		public String manufacturerCode;	//080
        @AuraEnabled
		public String manufacturerDescription;	//GENERAL MOTORS
        @AuraEnabled
		public String truckDutyTypeCode;	//ME
        @AuraEnabled
		public String truckDutyTypeDescription;	//Medium Duty
        @AuraEnabled
		public String vinCode;	//C
        @AuraEnabled
		public String valvesPerCylinder;	//2
        @AuraEnabled
		public String valvesTotal;	//16
	}
	class cls_tireSize {
        @AuraEnabled
		public String frontSizeCode;	//73
        @AuraEnabled
		public String frontSizeDescription;	//18R265
        @AuraEnabled
		public String frontOption1Code;	//
        @AuraEnabled
		public String frontOption1Description;	//
        @AuraEnabled
		public String frontOption2Code;	//
        @AuraEnabled
		public String frontOption2Description;	//
        @AuraEnabled
		public String frontOption3Code;	//
        @AuraEnabled
		public String frontOption3Description;	//
        @AuraEnabled
		public String frontOption4Code;	//
        @AuraEnabled
		public String frontOption4Description;	//
        @AuraEnabled
		public String rearOption1Code;	//
        @AuraEnabled
		public String rearOption1Description;	//
        @AuraEnabled
		public String rearOption2Code;	//
        @AuraEnabled
		public String rearOption2Description;	//
        @AuraEnabled
		public String rearOption3Code;	//
        @AuraEnabled
		public String rearOption3Description;	//
        @AuraEnabled
		public String rearOption4Code;	//
        @AuraEnabled
		public String rearOption4Description;	//
        @AuraEnabled
		public String rearSizeCode;	//73
        @AuraEnabled
		public String rearSizeDescription;	//18R265
	}
	class cls_manufacturer {
        @AuraEnabled
		public String baseMSRP;	//58800
        @AuraEnabled
		public String code;	//C137
        @AuraEnabled
		public String description;	//General Motors
	}
	class cls_nci {
        @AuraEnabled
		public String makeCode;	//CHEV
        @AuraEnabled
		public String seriesCode;	//SUB
	}
	class cls_options {
        @AuraEnabled
		public String option1TrimDescription;	//
	}
	class cls_truck {
        @AuraEnabled
		public String bedLength;	//R
        @AuraEnabled
		public String bedLengthDescription;	//Regular
        @AuraEnabled
		public String brakeTypeCode;	//
        @AuraEnabled
		public String brakeTypeDescription;	//
        @AuraEnabled
		public String cabConfigCode;	//SUV
        @AuraEnabled
		public String cabConfigDescription;	//Sport Utility
        @AuraEnabled
		public String frontAxelCode;	//U
        @AuraEnabled
		public String frontAxelDescription;	//Unknown
        @AuraEnabled
		public String grossWeightRatingCode;	//2
        @AuraEnabled
		public String grossWeightRatingDescription;	//6,001 - 10,000#
        @AuraEnabled
		public String rearAxelCode;	//U
        @AuraEnabled
		public String rearAxelDescription;	//Unknown
        @AuraEnabled
		public String tongueRatingCode;	//U
        @AuraEnabled
		public String tongueRatingDescription;	//Unknown
        @AuraEnabled
		public String trailerAxelCount;	//
	}
	class cls_vinInformation {
        @AuraEnabled
		public String position;	//OMVGSBBEKYPNNNNNN
        @AuraEnabled
		public String vinaBodyTypeCode;	//
        @AuraEnabled
		public String vinaSeriesCode;	//
        @AuraEnabled
		public String modelYearChar;	//K
        @AuraEnabled
		public String pattern;	//CHE  2019 1GNSKHKC\\CKR\\R000001-999999
	}
	class cls_wheel {
        @AuraEnabled
		public String longestInches;	//130
        @AuraEnabled
		public String shortestInches;	//130
        @AuraEnabled
		public String count;	//4
        @AuraEnabled
		public String driveCount;	//4
	}
	class cls_batteryQuote {
	}
	public static Plate2Vin_ResponseWrapper parse(String json){
		return (Plate2Vin_ResponseWrapper) System.JSON.deserialize(json, Plate2Vin_ResponseWrapper.class);
	}
}