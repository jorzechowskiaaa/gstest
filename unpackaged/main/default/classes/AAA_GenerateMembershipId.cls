public class AAA_GenerateMembershipId {
    private static BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    public static String genMembershipIdMain(String membershipNum) {
        String membershipId;

        if (membershipNum != null) {
            Integer mbrLength = membershipNum.length();
            String firstThree = extractFirstThreeDigits(membershipNum);

            if (
                mbrLength == 12 
                & firstThree == '212'
                || firstThree == '240'
            ) {
                membershipNum = processTwelveDigit(membershipNum);
            } else if (mbrLength == 9) {    // MemberId, Assoc. Member Id provided  
                membershipNum = processNineDigit(membershipNum);
            } else if (mbrLength == 7) {    // No Iso Code, Club Code, Assoc. Member Id provided in Membership Id
                membershipNum = processSevenDigit(membershipNum);
            }
    
            membershipId = membershipNum + calculateCheckCode(membershipNum);
        }

        return membershipId;
    }
    // 7 digit:  membership# provided.
    public static String processSevenDigit(String input) {
        String clubCode;

        if (Test.isRunningTest()) {
            clubCode = AAA_GenerateMembershipIdTest.mockClubCode();
        } else {
            clubCode = boSettings.Club_Code__c;
        }

        String isoCode = getISOCode(clubCode);
        String associateMemCode = '00';   // Associate Membership# defaults to '00'
        String membershipNum =  generateMembershipId(isoCode, clubCode, input, associateMemCode);

        return membershipNum; 
    }
    // 9 digit:  membership# and 2 digit Assoc membership provided.
    public static String processNineDigit(String input) {
        String clubCode;

        if (Test.isRunningTest()) {
            clubCode = AAA_GenerateMembershipIdTest.mockClubCode();
        } else {
            clubCode = boSettings.Club_Code__c;
        }

        String isoCode = getISOCode(clubCode);
        String membershipNum = isoCode + clubCode + input; 

        return membershipNum; 
    }
    
    // 12 digit:  ISOcode+Clubcode + membership# membership provided.
    public static String processTwelveDigit(String input) {
        String clubCode = extractFirstThreeDigits(input);
        String isoCode = getISOCode(clubCode);
        String membershipNum = isoCode + input; 

        return membershipNum; 
    }
    
    public static String extractFirstThreeDigits(String input) {
        if (input != null && input.length() == 12) {
            return input.substring(0, 3);
        } else {
            return null;
        }
    }
    
    public static String extractLastTwoDigits(String input) {
        if (input != null && input.length() == 12) {
            return input.substring(input.length() - 2, input.length()); 
        } else {
            return null;
        }
    }
    
    public static String getISOCode(String clubCode) {
        List<AAA_ISO_Code__mdt> aaaISOCode;

        if (Test.isRunningTest()) {
            aaaISOCode = AAA_GenerateMembershipIdTest.mockISOCodeMdt();
        } else {
            aaaISOCode = [
                SELECT ISO_Code__c 
                FROM AAA_ISO_Code__mdt 
                WHERE Club_Code__c = :clubCode 
                LIMIT 1
            ];
        }

		if (!aaaISOCode.isEmpty()) {
    	  return String.valueOf(aaaISOCode[0].ISO_Code__c);
		}

        return null;
    }
    
    public static String calculateCheckCode(String input) {
      /* ===== Logic to create Check Digit =====
           Step 1: The first 15 digits are numbered 1 thru 15. Multiply each digit by 1 or 2  - odd digits are multiplied by 2. 
           Step 2: If the result of any of these multiplications is a 2-digit number, add the 2 digits together to get the result  
           Step 3: Now add the result of all the 15 digit's multiplication results together to get a total.
           Step 4: The check digit = (  (10 - (total modulus 10) Modulus 10)
                  Example: 620240284248200  Check digit:   3
      ============================================*/
        Integer totresult = 0; 
        Integer checkCode = 0;

        if (input != null && input.length() == 15) {
        	// Step 1 
            for (Integer i = 1; i <= 15; i++) {
                Integer result = 0;
                Integer digit = Integer.valueOf(input.substring(i - 1, i));

                if (Math.mod(i, 2) == 0) {   
                    digit *= 1;
                } else {
                    digit *= 2;
                }
                result += digit;
                
                // Step 2
                if (result > 9) {
                   result = result / 10 + Math.mod(result, 10);
                }

                // Step 3
                totresult += result;
            }
        }

        // Step 4
        checkCode = Math.mod(10 - (Math.mod(totresult, 10)) ,10);

        if (checkCode != 0) {
            return String.valueOf(checkCode);
        }

        return null;
    }
     
    public static String generateMembershipId(String isoCode, String clubCode, String memberNum, String AssocCode) {
        return isoCode + clubCode + memberNum + AssocCode;
    }

}