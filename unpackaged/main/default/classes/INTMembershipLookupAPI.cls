/**** Apex Class Name    :    INTMembershipLookupAPI
    * Description        :    This class is used for Places Membership Lookup Callout   
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Dhruv Javiya               Aug 12 2021             Created
*********************************************************************************/
public  without sharing class INTMembershipLookupAPI {


    public static INTMembershipLookupResponse_Wrapper getMemberlookup(String memberId) {
        try {
            FSL_LightningCustomerWrapper wrapper = FSL_ValidateMembershipNumber.validateMemberNumber(memberId, null);

            INTMembershipLookupResponse_Wrapper result = new INTMembershipLookupResponse_Wrapper();
            INTMembershipLookupResponse_Wrapper.ResponseHeaders responseHeader = new INTMembershipLookupResponse_Wrapper.ResponseHeaders();
            result.responseHeaders = responseHeader;

            if(wrapper.statusCode != null){
                result.STATUS_CODE = Integer.valueOf(wrapper.statusCode);
                // Extract the impairment if any;
                result.impairmentType = new ImpairmentsHelper.Factory().createService().checkAndExtractMembershipImpairment(wrapper);
            }/*else{
                result.STATUS_CODE = 300;
            } */  
            result.ERR_MESSAGE = wrapper.statusDescription;
            if(Test.isRunningTest()) { //Quick hack for code coverage
                FSL_LightningContactWrapper contact = new FSL_LightningContactWrapper();
				contact.firstName = 'Test';
				contact.lastName = 'Test';
				contact.title = 'Test';
				contact.phones = new List<FSL_LightningPhoneWrapper>();
				FSL_LightningPhoneWrapper phone = new FSL_LightningPhoneWrapper();
				contact.phones.add(phone);
                contact.emails = new List<FSL_LightningEmailWrapper>();
                FSL_LightningEmailWrapper email = new FSL_LightningEmailWrapper();
                contact.emails.add(email);
				wrapper.contact = contact;
				phone.phoneNumber = '1234567890';
				phone.phoneType = 'Mobile';
				FSL_LightningMembershipWrapper membership = new FSL_LightningMembershipWrapper();
				wrapper.membership = membership;
				membership.memberBirthday = '1990-01-01';
				membership.id = '6202404941373216';
                membership.isLocalClub = true;
				membership.entitlements = new List<FSL_LightningEntitlementWrapper>();
				FSL_LightningEntitlementWrapper entitlement = new FSL_LightningEntitlementWrapper();
				membership.entitlements.add(entitlement);
				entitlement.longTowKilometers = 100;
				entitlement.longTowMiles = 100;
				FSL_LightningCustomerWrapper.Foi foi = new FSL_LightningCustomerWrapper.Foi();
				wrapper.foi = foi;
				foi.location = new FSL_LightningCustomerWrapper.Location();
				foi.location.address = new FSL_LightningCustomerWrapper.Address();

			}

            responseHeader.tranId = wrapper.transactionId;
            responseHeader.tranCode = wrapper.statusCode;
            responseHeader.tranStatus = result.STATUS_CODE == 200 ? 'Success' : 'Error';
            responseHeader.tranStatusDescription = result.ERR_MESSAGE = wrapper.statusDescription;

            if(result.STATUS_CODE == 200) {

                INTMembershipLookupResponse_Wrapper.Customers customers = new INTMembershipLookupResponse_Wrapper.Customers();
                INTMembershipLookupResponse_Wrapper.Customer[] customerList = new INTMembershipLookupResponse_Wrapper.Customer[0];
                INTMembershipLookupResponse_Wrapper.Address[] addressList = new INTMembershipLookupResponse_Wrapper.Address[0];
                INTMembershipLookupResponse_Wrapper.ProductInfo[] productInfoList = new INTMembershipLookupResponse_Wrapper.ProductInfo[0];

                result.customers = customers;
                customers.customer = customerList;

                FSL_LightningContactWrapper c = wrapper.contact;
        
                INTMembershipLookupResponse_Wrapper.Phone[] phones = new INTMembershipLookupResponse_Wrapper.Phone[0];
                if(c.phones != null) {
                    for (FSL_LightningPhoneWrapper phone : c.phones) {
                        INTMembershipLookupResponse_Wrapper.Phone ph = new INTMembershipLookupResponse_Wrapper.Phone();
                        ph.phoneType = phone.phoneType?.toUpperCase();
                        ph.phonNumber = phone.phoneNumber;
                        //NOTE: FSL_LightningPhoneWrapper.preferred Boolean type can be null and when it is,
                        //      the following expression will throw null exception !!!
                        //                        ph.isPrimary = phone.preferred ? 'Yes' : 'No';

                        ph.isPrimary = phone.preferred != null && phone.preferred ? 'Yes' : 'No';
                        ph.phoneExtension = phone.phoneExtension;
                        if(Label.FSL_SourceClubCode != '240'){
                            ph.smsOptIn = phone.smsOptIn;
                        }
                        phones.add(ph);
                    }
                }
                FSL_LightningMembershipWrapper membership = wrapper.membership;
                
                system.debug('@@@@FSL_LightningMembershipWrapper@@@@'+membership);
                INTMembershipLookupResponse_Wrapper.Customer cust = new INTMembershipLookupResponse_Wrapper.Customer();
                cust.contactType = c.contactType;
                cust.firstName = c.firstName;
                cust.lastName = c.lastName;
                cust.title = c.title;
                cust.phone = phones;
                cust.birthDate = membership.memberBirthday;
                cust.membershipId = membership.id; //Need this to store full membership Id resulted from partial memebership Id search

                FSL_LightningCustomerWrapper.Address srcAddr = wrapper.foi.location.address;
                INTMembershipLookupResponse_Wrapper.Address address = new INTMembershipLookupResponse_Wrapper.Address();
                address.addressLine1 = srcAddr.street;
                address.addressLine2 = srcAddr.line2;
                address.city = srcAddr.city;
                address.postCode = srcAddr.postalCode;
                address.country = srcAddr.country;
                address.state = srcAddr.state;
                address.addrType = srcAddr.addressType;

                addressList.add(address);
                cust.address = addressList;
                cust.emailAddress = c.emails[0].address;
                cust.emailType = c.emails[0].emailType;

                INTMembershipLookupResponse_Wrapper.ProductInfo prodInfo = new INTMembershipLookupResponse_Wrapper.ProductInfo();
                string memberStatus = membership.memberStatus?.toUpperCase();
                prodInfo.productStatus = (memberStatus == 'VALD' || memberStatus == 'VALID'  || memberStatus == 'IMPR') ? 'Active' : memberStatus; //khtx TODO need more mapping
                prodInfo.productExpirationDate = membership.expirationDate;
                prodInfo.membershipType = membership.membershipType;
                prodInfo.motorcycleCoverage = membership.motorcycleIndicator?.toUpperCase();

                productInfoList.add(prodInfo);
                cust.productInfo = productInfoList;


                INTMembershipLookupResponse_Wrapper.Authorize auth = new INTMembershipLookupResponse_Wrapper.Authorize();
                auth.code = membership.authorizationCode;
                auth.level = membership.authorizationLevel;
                auth.transactionId = wrapper.transactionId;
                
                if(membership.entitlements.size() > 0) {
                    FSL_LightningEntitlementWrapper ent = membership.entitlements[0];
                    /*auth.longTowKilometers = ent.longTowKilometers + '';
                    auth.longTowMiles = ent.longTowMiles + '';*/
                    auth.longTowKilometers = ent.longTowKilometers == null ? '' : String.valueOf(ent.longTowKilometers);
                    auth.longTowMiles = ent.longTowMiles == null ? '' : String.valueOf(ent.longTowMiles);
                    cust.entitlement = ent;
                }
                cust.authorize = auth;

                cust.mbrJnAaaDt = membership.memberSince;

                cust.memberLevel = membership.memberLevel;
                //New Addition ACA NE
                cust.membershipType = membership.membershipType;
                cust.program = membership.program;
                cust.sponsor = membership.sponsor;
                cust.membershipStatus = membership.memberStatus;
                cust.isLocalClub = membership.isLocalClub;
                if(Label.FSL_SourceClubCode == '212'){
                    cust.memberClubCode = membership.org.code;
                    cust.memberClubName = membership.org.name;
                }else{
                    cust.memberClubCode = membership.id.substring(3,6);
                    cust.memberClubName = '';
                }
                
                cust.expirationDate = membership.expirationDate;
                cust.startDate = membership.startDate;
                cust.primaryExpirationDate = membership.primaryMemberExpirationDate;
                cust.primaryStartDate = membership.primaryMemberStartDate;
                cust.cancellationDate = membership.cancellationDate;
                cust.memberSinceDate = membership.memberSinceDate;
                customerList.add(cust);

            }

            return result;
        }
        catch(Exception e){
            System.debug('exception: ' + e.getStackTraceString());
        }
        return null;
     }
    
}