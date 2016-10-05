public with sharing class tmDaoProvisioning {
     public static List<OrderItem> getTrialOrderLineItems(Id accountId, Id tenantId) {
         List<OrderItem> trialOrderItems = [SELECT Order.ContractId, Pricebookentry.Product2Id, sfbase__OrderItemEndDate__c,id 
                                        FROM OrderItem
                                        WHERE Order.IsTrialOrder = true
                                        AND Order.AccountId = :accountId
                                        AND ProvisioningTargetId = :tenantId
                                        AND Order.Contract.Status = :tmConstants.CONTRACT_STATUS_ACTIVATED                                        
                                        ];
         return trialOrderItems;
    }
    public static List<AggregateResult> getTrialOrderItems(Id accountId, Id tenantId) {
         List<AggregateResult> trialOrderItems = [SELECT Order.ContractId, Pricebookentry.Product2Id, SUM(Quantity)TotalQuantity
                                        FROM OrderItem
                                        WHERE Order.IsTrialOrder = true
                                        AND Order.AccountId = :accountId
                                        AND ProvisioningTargetId = :tenantId
                                        AND Order.Status = :tmConstants.ORDER_STATUS_PROVISIONED
                                        AND Order.Contract.Status = :tmConstants.CONTRACT_STATUS_ACTIVATED                                 
                                        GROUP BY Order.ContractId, Pricebookentry.Product2Id];
         return trialOrderItems;
    }

    public static List<OrderItem> getTrialContracts(Id accountId, Id tenantId) {
        List<OrderItem> ordItems  = [SELECT Order.ContractId, Order.Contract.EndDate
                                        FROM OrderItem
                                        WHERE Order.IsTrialOrder = true
                                        AND Order.AccountId = :accountId
                                        AND ProvisioningTargetId = :tenantId
                                        AND Order.Contract.Status = :tmConstants.CONTRACT_STATUS_ACTIVATED
                                        ORDER BY Order.Contract.EndDate DESC];
        return ordItems;
    }

    public static List<Contract> getCustomerSignedContract(Id accountId, Id tenantId) {
        List<Contract> customerContracts = new List<Contract>();
        List<OrderItem> ordItems  = [SELECT Order.ContractId, Order.Contract.StartDate
                                        FROM OrderItem
                                        WHERE Order.IsTrialOrder = false
                                        AND Order.AccountId = :accountId
                                        AND ProvisioningTargetId = :tenantId
                                        AND Order.Contract.Status = :tmConstants.CONTRACT_STATUS_ACTIVATED
                                        AND Order.Contract.StartDate >= :System.Today() 
                                        ORDER BY Order.Contract.StartDate ASC];
        if (!ordItems.isEmpty()) {
            customerContracts.add(ordItems.get(0).Order.Contract);
        }
        return customerContracts;
    }

    public static Map<String, sfbase__CountryRevenueMap__c> getCountryRevMap() {
        Map<String, sfbase__CountryRevenueMap__c> countryRevMap = new Map<String, sfbase__CountryRevenueMap__c> ();
        List<sfbase__CountryRevenueMap__c> countryRevList = [SELECT Id, sfbase__CountryISOCode__c, sfbase__CountryName__c, sfbase__PrimaryCurrency__c, sfbase__RevenueOwner__c
                            FROM sfbase__CountryRevenueMap__c ORDER BY sfbase__CountryName__c];
        for (sfbase__CountryRevenueMap__c countryMap : countryRevList) {
            countryRevMap.put(countryMap.sfbase__CountryISOCode__c, countryMap);
        }                       
        return countryRevMap;
    }

    public static List<sfbase__CountryRevenueMap__c> getISOCountryList() {
        Map<String, sfbase__CountryRevenueMap__c> countryRevMap = getCountryRevMap();
        return countryRevMap.Values();
    }

    public static String getCurrencyCode(String countryIsoCode) {
        String currencyCode = tmConstants.TFR_DEFAULT_CURRENCY;
        Map<String, sfbase__CountryRevenueMap__c> countryRevMap = getCountryRevMap();
        if(countryIsoCode != null) {
            if(countryRevMap.size() > 0 && countryRevMap.get(countryIsoCode) != null) {
                currencyCode = countryRevMap.get(countryIsoCode).sfbase__PrimaryCurrency__c;
            }
        } 
        return currencyCode;
    }

    public static String getPaymentTerm(String countryIsoCode) {
        String paymentTerm = tmConstants.CONTRACT_PAYMENT_TERM;
        sfbase__CountryRevenueMap__c revMapping = getcountryRevMap().get(countryIsoCode);
        if (revMapping != null) {
            String revOwner = revMapping.sfbase__RevenueOwner__c;        

            List<sfbase__SOBPaymentMethodMap__c> paymentMethodMapping = [SELECT sfbase__DefaultPaymentTerm__c
                                                        FROM sfbase__SOBPaymentMethodMap__c
                                                        WHERE sfbase__PaymentMethod__c = :tmConstants.CONTRACT_PAYMENT_METHOD
                                                        AND sfbase__RevenueOwner__c = :revOwner
                                                        LIMIT 1];
            if (paymentMethodMapping.size() > 0) {
                paymentTerm = paymentMethodMapping.get(0).sfbase__DefaultPaymentTerm__c;
            }                                                   
        }
        return paymentTerm;
    }  

    public static Id createOrderOnNewContract(Contract c, Order ord, List<OrderItem> ordItems, Id priceBookId) {
        return provisioningHelper.doCreateOrderOnNewContractWithoutSharing(c, ord, ordItems, priceBookId);
    }

    public static Id createOrderOnExistingContract(Id contractId, Order ord, List<OrderItem> ordItems) {
        return provisioningHelper.doCreateOrderOnNewContractWithoutSharing(contractId, ord, ordItems);
    }
    public static id upgradeOrderOnExistingContract(Id contractId, Order ord, List<OrderItem> ordItems, List<OrderItem> oldOrdItems) {
        provisioningHelper.updateOrderItems(oldOrdItems);
        return provisioningHelper.doCreateOrderOnNewContractWithoutSharing(contractId, ord, ordItems);
    }
    private static tmDaoProvisioningHelper provisioningHelper {
        get {
            if (provisioningHelper == null) {
                provisioningHelper = new tmDaoProvisioningHelper();
            }
            return provisioningHelper;
        }
        private set;
    }

    private without sharing class tmDaoProvisioningHelper {
        public Id doCreateOrderOnNewContractWithoutSharing(Contract c, Order ord, List<OrderItem> ordItems, Id pbId) {
            c.RecordTypeId = recordTypeIds.get('Contract');
            insert c;

            //Activate contract
            c.Status = tmConstants.CONTRACT_STATUS_ACTIVATED;
            update c;

            Id orderId = doCreateOrderOnNewContractWithoutSharing(c.Id, ord, ordItems);
            return orderId;
        }

        public Id doCreateOrderOnNewContractWithoutSharing(Id contractId, Order ord, List<OrderItem> ordItems) {
            ord.contractId = contractId;
            ord.RecordTypeId = recordTypeIds.get('Order');

            //1.Insert order
            insert ord;
            Id orderId = ord.Id;

            //2.Insert order items
            for (OrderItem oi : ordItems) {
                oi.OrderId = orderId;
            }
            insert ordItems;

            //3.Activate order
            ord.Status = tmConstants.ORDER_STATUS_ACTIVATED;
            ord.sfbase__IsAutoActivated__c = true;
            update ord;

            return orderId;
        }
        
        public void updateOrderItems(List<OrderItem> oldOrdItems) {
            if(oldOrdItems.size() > 0)
                update oldOrdItems;  
         }
        
        private Map<String,Id> recordTypeIds {
            get {
                if (recordTypeIds == null) {
                    recordTypeIds = new Map<String, Id>();
                    List<RecordType> recordTypes = [SELECT Id, SobjectType
                                                        FROM RecordType
                                                        WHERE SobjectType IN ('Contract','Order')
                                                        AND NAME IN (:tmConstants.CONTRACT_RECORD_TYPE_SALES, :tmConstants.ORDER_RECORD_TYPE_NB)];
                    for (RecordType r : recordTypes) {
                        recordTypeIds.put(r.SobjectType, r.Id);
                    } 
                }
                return recordTypeIds;
            }
            private set;                                 
        }
    }

}