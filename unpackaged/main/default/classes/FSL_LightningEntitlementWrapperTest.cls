@IsTest
public class FSL_LightningEntitlementWrapperTest {
    @IsTest
    static void testFSL_LightningEntitlementWrapper() {
        // Create an instance of the FSL_LightningEntitlementWrapper class
        FSL_LightningEntitlementWrapper wrapper = new FSL_LightningEntitlementWrapper();
        
        // Set properties
        wrapper.serviceChargeIndicator = true;
        wrapper.associates = 10;
        wrapper.chargeableCalls = 5;
        wrapper.currentCalls = 3;
        wrapper.callsAllowed = 10;
        wrapper.callsRemaining = 7;
        wrapper.callsUsed = 3;
        wrapper.onlineGarageMember = true;
        wrapper.longTowAllowed = true;
        wrapper.longTowKilometers = 100;
        wrapper.longTowMiles = 62;
        wrapper.rentalDays = 5;
        wrapper.specialMemberType = 1;
        wrapper.homeLockoutEntitled = false;
        wrapper.carRentalEntitled = true;
        wrapper.sameDayService = false;
        wrapper.CAPREeligible = true;
        wrapper.RVUsage = false;
        wrapper.premierBatteryEntitled = true;
        
        // Assert that the properties were set correctly
        System.assert(wrapper.serviceChargeIndicator == true);
        System.assertEquals(10, wrapper.associates);
        System.assertEquals(5, wrapper.chargeableCalls);
        System.assertEquals(3, wrapper.currentCalls);
        System.assertEquals(10, wrapper.callsAllowed);
        System.assertEquals(7, wrapper.callsRemaining);
        System.assertEquals(3, wrapper.callsUsed);
        System.assert(wrapper.onlineGarageMember == true);
        System.assert(wrapper.longTowAllowed == true);
        System.assertEquals(100, wrapper.longTowKilometers);
        System.assertEquals(62, wrapper.longTowMiles);
        System.assertEquals(5, wrapper.rentalDays);
        System.assertEquals(1, wrapper.specialMemberType);
        System.assert(wrapper.homeLockoutEntitled == false);
        System.assert(wrapper.carRentalEntitled == true);
        System.assert(wrapper.sameDayService == false);
        System.assert(wrapper.CAPREeligible == true);
        System.assert(wrapper.RVUsage == false);
        System.assert(wrapper.premierBatteryEntitled == true);
    }
}