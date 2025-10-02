global without sharing class AAAServiceRequestOSHelper implements omnistudio.VlocityOpenInterface2 {
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    public Boolean invokeMethod(
        String methodName, 
        Map<String, Object> input, 
        Map<String, Object> output, 
        Map<String, Object> options
    ) {
        Boolean result = true;

        try {
            if (methodName.equals('IPInvoked')) {
                methodName = (String) input.get('method');
            }

            if (methodName.equals('getSvcTerritoryInfo')) {
                getSvcTerritoryInfo(input, output);
            } else if (methodName.equals('setDefaultResAndClearCode')) {
                setDefaultResAndClearCode(input, output);
            } else if (methodName.equals('getMemberServiceContractDetails')) {
                getMemberServiceContractDetails(input, output);
            } else if (methodName.equals('getBreakdownLocation')) {
                getBreakdownLocation(input, output);
            } else if (methodName.equals('getTowLocation')) {
                getTowLocation(input, output);
            } else if (methodName.equals('getTroubleCodes')) {
                getTroubleCodes(input, output);
            } else if (methodName.equals('setChargeToAccount')) {
                setChargeToAccount(input, output);
            } else if (methodName.equals('validateInput')) {
                validateInput(input, output);
            } else if (methodName.equals('processSvcReqInfo')) {
                processSvcReqInfo(input, output);
            } else if (methodName.equals('getProducts')) {
                getProducts(input, output);
            } else if (methodName.equals('getSLIs')) {
                getSLIs(input, output);
            } else if (methodName.equals('createSLIs')) {
                createSLIs(input, output);
            } else if (methodName.equals('updateSLI')) {
                updateSLI(input, output);
            } else if (methodName.equals('deleteSLI')) {
                deleteSLI(input, output);
            } else if (methodName.equals('createComment')) {
                createComment(input);
            }
        } catch(Exception e) {
            result = false;
            System.debug(e);
        }
        
        return result;
    }

    public void getSvcTerritoryInfo(Map<String, Object> input, Map<String, Object> output) {
        String svcTerritoryId = (String) input.get('ContextId');

        if (String.isNotBlank(svcTerritoryId)) {
            String username = (String) input.get('userName');
            ServiceTerritory svcTerritory = [
                SELECT
                    Id, Comm_Ctr__c, Facility_Number__c, State
                FROM ServiceTerritory
                WHERE Id = :svcTerritoryId
            ];
            Date today = System.today();
            String batchId = username + svcTerritory.Facility_Number__c 
                + today.month() + today.day() + today.year();

            output.put('svcTerritoryInfo', new Map<String, Object>{
                'ServiceTerritory' => svcTerritory,
                'BatchId' => batchId,
                'clubCode' => boSettings.Club_Code__c,
                'isTypeTow' => false,
                'hasError' => false,
                'errMsg' => null
            });
        }
    }

    public void setDefaultResAndClearCode(Map<String, Object> input, Map<String, Object> output) {
        String club = boSettings.Club_Code__c;
        String resCode = club == '240' ? 'N590' : 'N380';
        String clearCode = club == '240' ? 'RR' : '2T';

        output.put('Add Service Request', new Map<String, Object>{
            'Call Information' => new Map<String, Object>{
                'Resolution Code' => resCode,
                'Clear Code' => clearCode
            }
        });
    }

    public void getMemberServiceContractDetails(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> svcReqForm = (Map<String, Object>) input.get('Add Service Request');
        Map<String, Object> svcReqInfo = (Map<String, Object>) svcReqForm?.get('Service Request Information');
        String callDate = (String) svcReqInfo?.get('Call Date');
        String queryStr = '%' + (String) input.get('membershipId') + '%';
        List<ServiceContract> scList = [
            SELECT 
                Id,
                Name,
                AAA_Battery_Consumed__c,
                AAA_Total_of_Calls_Consumed__c,
                AAA_Total_of_Calls_Remaining__c,
                AAA_Long_Tow_Consumed__c,
                AAA_Total_of_Calls_Allowed__c,
                AAA_Home_Lockout_Consumed__c,
                AAA_Total_of_Reciprocals__c,
                AAA_ACA_Club_Code__c,
                EndDate,
                Status,
                Account.Id,
                Account.ACG_Billing_State_and_Zip__c,
                Account.BillingAddress,
                Account.BillingCity,
                Account.BillingPostalCode,
                Account.BillingState,
                Account.BillingStreet,
                Account.FirstName,
                Account.LastName,
                Account.Member_ID__c,
                Account.Membership_Level__pc,
                Account.Membership_Expiration_Date__c,
                Account.Name,
                Account.Phone,
                Account.Club_Code__c
            FROM ServiceContract 
            WHERE AAA_ACA_Membership16ID__c LIKE :queryStr
            AND EndDate >= :System.today()
            ORDER BY EndDate DESC
            LIMIT 20
        ];
        List<String> scIds = new List<String>();
        List<Map<String, Object>> respList = new List<Map<String, Object>>();
        Map<String, ServiceContract> svcContMap = new Map<String, ServiceContract>();
        List<Account> acctList = new List<Account>();

        for (ServiceContract svcCont : scList) {
            String acctId = svcCont.Account.Id;

            if (svcContMap.get(acctId) == null) {
                svcContMap.put(acctId, svcCont);
            }

            scIds.add(svcCont.Id);
            acctList.add(svcCont.Account);
        }

        List<WorkOrder> woList = [
            SELECT Id, ServiceContractId
            FROM WorkOrder
            WHERE Call_Date__c = :callDate
            AND ServiceContractId IN :scIds
        ];
        Map<String, WorkOrder> woSvcContMap = new Map<String, WorkOrder>();

        for (WorkOrder wo : woList) {
            if (wo != null) {
                woSvcContMap.put(wo.ServiceContractId, wo);
            }
        }

        if (scList.size() == 0) {
            acctList = [
                SELECT 
                    Id,
                    ACG_Billing_State_and_Zip__c,
                    BillingAddress,
                    BillingCity,
                    BillingPostalCode,
                    BillingState,
                    BillingStreet,
                    FirstName,
                    LastName,
                    Member_ID__c,
                    Membership_Level__pc,
                    Membership_Expiration_Date__c,
                    Name,
                    Phone,
                    Membership_Status__pc,
                    Club_Code__c
                FROM Account 
                WHERE Member_ID__c LIKE :queryStr
                AND Member_ID__c != null
                LIMIT 20
            ];
        }

        for (Account acct : acctList) {
            if (acct != null) {
                ServiceContract svcCont = svcContMap.get(acct.Id);
                WorkOrder wo = woSvcContMap.get(svcCont?.Id);
    
                respList.add(
                    new Map<String, Object>{
                        'ServiceContractId' => svcCont?.Id,
                        'ServiceContractName' => svcCont?.Name,
                        'MemberStatus' => String.isNotBlank(svcCont?.Status) ? 
                            svcCont.Status : acct.Membership_Status__pc,
                        'MemberExpiration' => acct.Membership_Expiration_Date__c,
                        'ACG_Billing_State_and_Zip__c' => acct.ACG_Billing_State_and_Zip__c,
                        'Address' => acct.BillingAddress,
                        'City' => acct.BillingCity,
                        'Zip' => acct.BillingPostalCode,
                        'State' => acct.BillingState,
                        'Street' => acct.BillingStreet,
                        'FirstName' => acct.FirstName,
                        'Id' => acct.Id,
                        'LastName' => acct.LastName,
                        'Member_ID__c' => acct.Member_ID__c,
                        'MemberLevel' => acct.Membership_Level__pc,
                        'FullName' => acct.Name,
                        'Phone' => acct.Phone,
                        'BatteryConsumed' => svcCont?.AAA_Battery_Consumed__c,
                        'AAA_Total_of_Calls_Consumed__c' => svcCont?.AAA_Total_of_Calls_Consumed__c,
                        'AAA_Total_of_Calls_Remaining__c' => svcCont?.AAA_Total_of_Calls_Remaining__c,
                        'LongTowConsumed' => svcCont?.AAA_Long_Tow_Consumed__c,
                        'AAA_Total_of_Calls_Allowed__c' => svcCont?.AAA_Total_of_Calls_Allowed__c,
                        'HomeLockoutConsumed' => svcCont?.AAA_Home_Lockout_Consumed__c,
                        'AAA_Total_of_Reciprocals__c' => svcCont?.AAA_Total_of_Reciprocals__c,
                        'AbbrevClubCode' => String.isNotBlank(svcCont?.AAA_ACA_Club_Code__c) ? 
                            svcCont?.AAA_ACA_Club_Code__c : acct.Club_Code__c,
                        'hasEntitlement' => svcCont?.AAA_Total_of_Calls_Consumed__c != null,
                        'hasSameDayWO' => wo != null
                    }
                );
            }
        }

        output.put('ServiceContract', respList);
    }

    public void getBreakdownLocation(Map<String, Object> input, Map<String, Object> output) {
        String address = (String) input.get('breakdownAddress');

        output.put('breakdownLocations', getLocations(address, false));
    }

    public void getTowLocation(Map<String, Object> input, Map<String, Object> output) {
        String address = (String) input.get('towAddress');

        output.put('towLocations', getLocations(address, true));
    }

    public void getTroubleCodes(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> facWrapper = (Map<String, Object>) input.get('svcTerritoryInfo');
        Map<String, Object> svcTerritory = (Map<String, Object>) facWrapper.get('ServiceTerritory');
        String facState = (String) svcTerritory.get('State');
        String tCodeInput = (String) input.get('problemCode');
        String query = '%' + tCodeInput + '%';
        List<Taxation_State_by_Problem_Codes__mdt> tCodes = new List<Taxation_State_by_Problem_Codes__mdt>();
        List<Map<String, Object>> respList = new List<Map<String, Object>>();

        if (Test.isRunningTest()) {
            tCodes = AAAServiceRequestOSHelperTest.mockTCodeWorkTypeMDT();
        } else {
            facState = facState == null ? '' : facState;
            tCodes = [
                SELECT Id, Problem_Code__c
                FROM Taxation_State_by_Problem_Codes__mdt
                WHERE Problem_Code__c LIKE :query
                AND Problem_Code__c != null
                AND State__c = :facState
            ];
        }

        for (Taxation_State_by_Problem_Codes__mdt tCode : tCodes) {
            respList.add(new Map<String, Object>{
                'problemCode' => tCode.Problem_Code__c
            });
        }

        output.put('troubleCodes', respList);
    }

    public void setChargeToAccount(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> svcReqForm = (Map<String, Object>) input.get('Add Service Request');
        Map<String, Object> mbrWrapper = (Map<String, Object>) svcReqForm.get('Member Information');
        Map<String, Object> mbrInfo = (Map<String, Object>) mbrWrapper.get('Membership Id-Block');
        Map<String, String> mbrLevelMap = new Map<String, String>{
            'plus' => 'P',
            'premier' => 'E',
            'plus rv' => 'R',
            'basic' => 'B',
            'premier rv' => 'R'
        };
        String mbrLevel = (String) mbrInfo.get('MemberLevel');
        String chargeAcct = mbrLevelMap.get(mbrLevel.toLowerCase());

        output.put('AddServiceLineItems', new Map<String, Object>{
            'ServiceLineItemDetails' => new Map<String, Object>{
                'ChargeToAccount' => chargeAcct != null ? chargeAcct : 'O'
            }
        });
    }

    public void validateInput(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> reqForm = (Map<String, Object>) input.get('Add Service Request');
        Map<String, Object> svcReqInfo = (Map<String, Object>) reqForm.get('Service Request Information');
        String ticketNum = (String) svcReqInfo.get('Ticket Number');
        String svcTerritoryId = (String) input.get('ContextId');
        List<WorkOrder> woWithTicketNum = [
            SELECT Id
            FROM WorkOrder
            WHERE Ticket_Number__c = :ticketNum
            AND ServiceTerritoryId = :svcTerritoryId
        ];
        
        output.put('processedRes', woWithTicketNum.size() > 0 ? 'hasTicket' : 'good');
    }

    public void processSvcReqInfo(Map<String, Object> input, Map<String, Object> output) {
        try {
            Map<String, Object> facInfoWrapper = (Map<String, Object>) input.get('svcTerritoryInfo');
            Map<String, Object> svcTerritory = (Map<String, Object>) facInfoWrapper.get('ServiceTerritory');
            Map<String, Object> svcReqWrapper = (Map<String, Object>) input.get('Add Service Request');
            Map<String, Object> svcReqInfo = (Map<String, Object>) svcReqWrapper.get('Service Request Information');
            Map<String, Object> mbrWrapper = (Map<String, Object>) svcReqWrapper.get('Member Information');
            Map<String, Object> mbrInfo = (Map<String, Object>) mbrWrapper.get('Membership Id-Block');
            Map<String, Object> vehInfo = (Map<String, Object>) svcReqWrapper.get('Vehicle Information');
            Map<String, Object> callInfo = (Map<String, Object>) svcReqWrapper.get('Call Information');
            Map<String, Object> tCodeWrapper = (Map<String, Object>) callInfo.get('problemCode-Block');
            String svcTerritoryId = (String) input.get('ContextId');
            String svcContId = (String) mbrInfo.get('ServiceContractId');
            String batchId = (String) svcReqInfo.get('BatchID');
            String ticketNum = (String) svcReqInfo.get('Ticket Number');
            String problemCode = (String) tCodeWrapper?.get('problemCode');
            String problemDesc = (String) callInfo?.get('ProblemDescription');
            Boolean chargeEntitlement = (Boolean) mbrWrapper.get('Charge entitlement');
            Boolean isProblem = String.isNotBlank(problemCode) && String.isNotBlank(problemDesc);
            Boolean isTow = isProblem && (problemCode == '5' || problemCode.toLowerCase() == '5f');
            String woType = isTow ? 'Tow' : 'Light_Service';
            Map<String, Object> breakdownWrapper = (Map<String, Object>) svcReqWrapper.get('Breakdown Information');
            Map<String, Object> towWrapper = (Map<String, Object>) svcReqWrapper.get('Tow Destination');
            String acctId = (String) mbrInfo.get('Id');
            String boEditableMbrLevel = (String) mbrInfo.get('MemberLevel');
            Contact contact;
            RecordType woRecType = [
                SELECT Id
                FROM RecordType
                WHERE SobjectType = 'WorkOrder'
                AND DeveloperName = :woType
            ];
            
            if (String.isNotBlank(acctId)) {
                contact = [
                    SELECT Id
                    FROM Contact
                    WHERE AccountId = :acctId
                ];
            }

            WorkOrder newWO = new WorkOrder(
                Call_Type__c = (String) callInfo.get('Call Type'),
                Clearing_Code__c = (String) callInfo.get('Clear Code'),
                Resolution_Code__c = (String) callInfo.get('Resolution Code'),
                T_Code__c = problemCode,
                AAA_Charge_Entitlement__c = chargeEntitlement != null ? chargeEntitlement : false,
                Member_Account__c = acctId,
                AccountId = acctId,
                BO_Editable_WO_Specific_Membership_Level__c = boEditableMbrLevel != null ? boEditableMbrLevel : 'Basic',
                WO_Member_Phone_Number__c = (String) mbrInfo.get('Phone'),
                Call_Date__c = (String) svcReqInfo.get('Call Date'),
                Batch_Number__c = batchId,
                Ticket_Number__c = ticketNum,
                ServiceTerritoryId = svcTerritoryId,
                RecordTypeId = woRecType.Id,
                Status = 'In Progress',
                ServiceContractId = svcContId,
                ContactId = contact != null ? contact.Id : null
            );

            if (breakdownWrapper != null) {
                Map<String, Object> breakdownInfo = (Map<String, Object>) breakdownWrapper.get('Breakdown Location Address-Block');
                String street = (String) breakdownInfo.get('breakdownStreet');

                if (street == null) {
                    street = (String) breakdownInfo.get('Breakdown Location Address');
                }

                newWO.Country = 'United States';
                newWO.Breakdown_Location__Latitude__s = (Decimal) breakdownInfo.get('Breakdown_Location__Latitude__s');
                newWO.Breakdown_Location__Longitude__s = (Decimal) breakdownInfo.get('Breakdown_Location__Longitude__s');
                newWO.Street = street;
                newWO.City = (String) breakdownInfo.get('breakdownCity');
                newWO.State = (String) breakdownInfo.get('breakdownState');
                newWO.PostalCode = (String) breakdownInfo.get('breakdownPostalCode');
            }

            if (towWrapper != null) {
                Map<String, Object> towInfo = (Map<String, Object>) towWrapper.get('Tow Destination Address-Block');
                String street = (String) towInfo.get('towStreet');

                if (street == null) {
                    street = (String) towInfo.get('Tow Destination Address');
                }

                newWO.Tow_Country__c = 'United States';
                newWO.Tow_Latitude__c = (Decimal) towInfo.get('Tow_Location__Latitude__s');
                newWO.Tow_Longitude__c = (Decimal) towInfo.get('Tow_Location__Longitude__s');
                newWO.Tow_Street__c = street;
                newWO.Tow_City__c = (String) towInfo.get('towCity');
                newWO.Tow_State__c = (String) towInfo.get('towState');
                newWO.Tow_Postal_Code__c = (String) towInfo.get('towPostalCode');
            }

            insert newWo;

            WorkOrder woQuery = [
                SELECT 
                    Id,
                    Cleared_Timestamp__c,
                    WorkOrderNumber, 
                    CreatedDate, 
                    Status
                FROM WorkOrder
                WHERE Id = :newWO.Id 
            ];

            if (String.isNotBlank(problemCode) && String.isNotBlank(problemDesc)) {
                insert new FSL_TroubleCode__c(
                    Code__c = problemCode,
                    Description__c = problemDesc,
                    Work_Order__c = woQuery.Id,
                    Type__c = 'PROBLEM'
                );
            }

            if (vehInfo != null) {
                String make = (String) vehInfo.get('Vehicle Make');
                String model = (String) vehInfo.get('Vehicle Model');
                String tag = (String) vehInfo.get('Vehicle Tag');
                String year = (String) vehInfo.get('Vehicle Year');
                String plate = (String) vehInfo.get('Vehicle Plate');//EMI
                String mbrId = (String) mbrInfo.get('Id');
                String mbrName = (String) mbrInfo.get('FullName');

                if (
                    make != null 
                    || model != null 
                    || tag != null 
                    || year != null
                ) {
                    insert new FSL_Member_Vehicle__c(
                        Name = mbrName,
                        ACG_Member__c = mbrId,
                        Vehicle_Make__c = make,
                        Vehicle_Model__c = model,
                        Vehicle_Tag__c = tag,
                        Vehicle_Year__c = year,
                        Vehicle_Plate__c = plate,//EMI
                        Work_Order__c = woQuery.Id
                    );
                }
            }

            woQuery.Cleared_Timestamp__c = woQuery.CreatedDate;
            woQuery.Status = 'Cleared';
            update woQuery;

            output.put('AddServiceLineItems', new Map<String, Object>{
                'ServiceLineItemDetails' => new Map<String, Object>{
                    'WorkOrderNbr2' => woQuery.WorkOrderNumber,
                    'woId' => woQuery.Id
                }
            });
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

            insert new FSL_Application_Log__c(
                Operation__c = 'AAAServiceRequestOSHelper.processSvcReqInfo()',
                Error_Message__c = 'Service Request Exception:\n' + errMsg
            );

            output.put('svcTerritoryInfo', new Map<String, Object>{
                'hasError' => true,
                'errMsg' => e.getMessage()
            });
        }
    }

    public void getProducts(Map<String, Object> input, Map<String, Object> output) {
        String query = (String) input.get('code');
        String prodCode = '%' + query + '%';
        List<Product2> prod2List = [
            SELECT Id, Name, ProductCode
            FROM Product2 
            WHERE ProductCode != 'BA'
            AND IsActive = true
            AND Family != 'Trouble Code'
            AND ProductCode LIKE :prodCode
            ORDER BY ProductCode ASC
            LIMIT 20
        ];
        List<Map<String, Object>> respList = new List<Map<String, Object>>();

        for (Product2 prod2 : prod2List) {
            respList.add(new Map<String, Object>{
                'ProductId' => prod2.Id,
                'ProductCode' => prod2.ProductCode,
                'ProductName' => prod2.Name
            });
        }

        output.put('productList', respList);
    }

    public void getSLIs(Map<String, Object> input, Map<String, Object> output) {
        String woId = (String) input.get('WorkOrderId');
        String errMsg;
        List<FSL_Service_Line_Item__c> sliList = [
            SELECT
                Id,
                Name,
                Product_Code__c,
                Override_Pricing__c,
                Calculated_Unit__c,
                Unit__c,
                Cost__c,
                Tax__c
            FROM FSL_Service_Line_Item__c 
            WHERE Work_Order__c = :woId
        ];

        output.put('sli', sliList);
    }

    public void createSLIs(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> sliWrapper = (Map<String, Object>) input.get('CreateServiceLineItem');
        Map<String, Object> prodData = (Map<String, Object>) sliWrapper.get('ProductLookup-Block');
        String woId = (String) input.get('WorkOrderId');
        String chargeAccount = (String) sliWrapper.get('ChargeToAccount');
        String prodId = (String) prodData.get('ProductId');
        Decimal cost = (Decimal) sliWrapper.get('Cost');
        Decimal tax = (Decimal) sliWrapper.get('Tax');
        Decimal qty = (Decimal) sliWrapper.get('Quantity');
        Boolean overridePrice = (Boolean) sliWrapper.get('OverridePricing');
        Boolean fetchSLIs = (Boolean) input.get('fetchSLIs');

        FSL_Service_Line_Item__c sli = new FSL_Service_Line_Item__c(
            Charge_to_Account__c = chargeAccount,
            Cost__c = cost,
            Override_Pricing__c = overridePrice,
            Product__c = prodId,
            Unit__c = qty,
            Tax__c = tax,
            Work_Order__c = woId
        );
        insert sli;

        try {
            if (fetchSLIs == true) {
                output.put('sli', 
                    [
                        SELECT
                            Id,
                            Name,
                            Product_Code__c,
                            Override_Pricing__c,
                            Calculated_Unit__c,
                            Unit__c,
                            Cost__c,
                            Tax__c
                        FROM FSL_Service_Line_Item__c
                        WHERE Work_Order__c = :woId
                    ]
                );
            } else {
                output.put('sli',
                    [
                        SELECT
                            Id,
                            Name,
                            Product_Code__c,
                            Override_Pricing__c,
                            Calculated_Unit__c,
                            Unit__c,
                            Cost__c,
                            Tax__c
                        FROM FSL_Service_Line_Item__c
                        WHERE Id = :sli.Id
                        LIMIT 1
                    ]
                );
            }
        } catch (Exception e) {
            output.put('sli', e.getMessage());
        }
    }

    public void updateSLI(Map<String, Object> input, Map<String, Object> output) {
        Boolean ovrdPrice = (Boolean) input.get('newOvrd');
        Decimal qty = (Decimal) input.get('newQty');
        Decimal cost = (Decimal) input.get('newCost');
        Decimal tax = (Decimal) input.get('newTax');
        String sliId = (String) input.get('sliId');

        try {
            FSL_Service_Line_Item__c sli = [
                SELECT
                    Id,
                    Override_Pricing__c,
                    Unit__c,
                    Cost__c,
                    Tax__c,
                    Ready_for_Invoicing__c
                FROM FSL_Service_Line_Item__c
                WHERE Id = :sliId
            ];

            sli.Override_Pricing__c = ovrdPrice;
            sli.Unit__c = qty;
            sli.Cost__c = cost;
            sli.Tax__c = tax;
            sli.Ready_for_Invoicing__c = false;
            update sli;

            sli = [
                SELECT
                    Id,
                    Override_Pricing__c,
                    Unit__c,
                    Cost__c,
                    Tax__c
                FROM FSL_Service_Line_Item__c
                WHERE Id = :sliId
            ];

            output.put('sli', new List<FSL_Service_Line_Item__c>{sli});
        } catch (Exception e) {
            output.put('sli', e.getMessage());
        }
    }

    public void deleteSLI(Map<String, Object> input, Map<String, Object> output) {
        String sliId = (String) input.get('sliId');
        String woId = (String) input.get('WorkOrderId');
        String msg = 'success';

        try {
            FSL_Service_Line_Item__c sli = [
                SELECT Id
                FROM FSL_Service_Line_Item__c
                WHERE Id = :sliId
                AND Work_Order__c = :woId
            ];

            delete sli;
        } catch (Exception e) {
            msg = e.getMessage();
        }

        output.put('sli', msg);
    }

    public void createComment(Map<String, Object> input) {
        Map<String, Object> sliWrapper = (Map<String, Object>) input.get('AddServiceLineItems');
        Map<String, Object> sliDetails = (Map<String, Object>) sliWrapper.get('ServiceLineItemDetails');
        String woId = (String) sliDetails.get('woId');
        String callComments = (String) sliWrapper.get('CallComments');

        if (String.isNotBlank(callComments)) {
            insert new FSL_Call_Comments__c(
                FSL_Comment__c = callComments,
                FSL_Work_Order__c = woId
            );
        }
    }

    private List<Map<String, Object>> getLocations(String address, Boolean isTowLocation) {
        String queryStr = '%' + address + '%';
        List<WorkOrder> woLocations = new List<WorkOrder>();

        if (isTowLocation) {
            woLocations = [
                SELECT
                    Tow_Address__c,
                    Tow_Location__Latitude__s,
                    Tow_Location__Longitude__s,
                    Street,
                    City,
                    State,
                    PostalCode,
                    Tow_Street__c,
                    Tow_City__c,
                    Tow_State__c,
                    Tow_Postal_Code__c
                FROM WorkOrder
                WHERE Tow_Address__c LIKE :queryStr
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } else {
            woLocations = [
                SELECT
                    Breakdown_Address__c,
                    Breakdown_Location__Latitude__s,
                    Breakdown_Location__Longitude__s,
                    Street,
                    City,
                    State,
                    PostalCode,
                    Tow_Street__c,
                    Tow_City__c,
                    Tow_State__c,
                    Tow_Postal_Code__c
                FROM WorkOrder
                WHERE Breakdown_Address__c LIKE :queryStr
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        }
        Map<String, WorkOrder> addressMap = new Map<String, WorkOrder>();
        List<Map<String, Object>> resList = new List<Map<String, Object>>();

        for (WorkOrder woLocation : woLocations) {
            String key;
        
            if (isTowLocation) {
                key = woLocation.Tow_Address__c.toLowerCase();
            } else {
                key = woLocation.Breakdown_Address__c.toLowerCase();
            }

            if (String.isBlank(key)) {
                break;
            }

            addressMap.put(key, woLocation);
        }

        for (String key : addressMap.keySet()) {
            WorkOrder woLocation = addressMap.get(key);

            if (isTowLocation) {
                resList.add(
                    new Map<String, Object>{
                        'Tow_Location__Latitude__s' => woLocation.Tow_Location__Latitude__s,
                        'Tow_Location__Longitude__s' => woLocation.Tow_Location__Longitude__s,
                        'towAddress' => woLocation.Tow_Address__c,
                        'towStreet' => woLocation.Tow_Street__c,
                        'towCity' => woLocation.Tow_City__c,
                        'towState' => woLocation.Tow_State__c,
                        'towPostalCode' => woLocation.Tow_Postal_Code__c
                    }
                );
            } else {
                resList.add(
                    new Map<String, Object>{
                        'Breakdown_Location__Latitude__s' => woLocation.Breakdown_Location__Latitude__s,
                        'Breakdown_Location__Longitude__s' => woLocation.Breakdown_Location__Longitude__s,
                        'address' => woLocation.Breakdown_Address__c,
                        'breakdownStreet' => woLocation.Street,
                        'breakdownCity' => woLocation.City,
                        'breakdownState' => woLocation.State,
                        'breakdownPostalCode' => woLocation.PostalCode
                    }
                );
            }
        }

        return resList;
    }
}