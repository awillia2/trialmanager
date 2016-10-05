public with sharing class tmDomainProvisioning {
    private tmDomainTrialFeatureRequest tfrDomain {get; private set;}
    private tmDomainTrialFeatureRequest.tmDecoratorTrialFeatureRequest tfrDecorator {get; private set;}
    private Id accountId;
    private Id tenantId;

    public tmDomainProvisioning(Id accountId, Id tenantId) {
        if (accountId == null)
            throw new tmException(tmConstants.ERROR_ACCOUNT_TENANT_MISSING); 
        else {
            this.accountId = accountId;
            this.tenantId = tenantId;    
        }
    }

    public tmDomainProvisioning(Id tfrId) {
        if (tfrId == null) {
            throw new tmException(tmConstants.ERROR_INITIALIZE_TRIAL_FEATURE_REQUEST); 
        }
        else {
            this.tfrDomain = new tmDomainTrialFeatureRequest(null,tfrId);
            this.tfrDecorator = tfrDomain.tfrDecorator;
            this.accountId = tfrDecorator.accountId;
            this.tenantId = tfrDecorator.tenantId; 
        }
    }

    public Boolean hasProvisionedTrialOrders {
        get {
            if (hasProvisionedTrialOrders == null ) {
                hasProvisionedTrialOrders = false;
                populateProvisionedData();
            }
            return hasProvisionedTrialOrders;
        }
        private set;        
    } 

    public String existingOrderEdition {
        get {
            if (hasProvisionedTrialOrders && existingOrderEdition == null) {
                existingOrderEdition = '';
                populateProvisionedData();
            }
            return existingOrderEdition;
        }
        private set;        
    }

    public List<tmDomainTrialFeatureRequest.tmTrialProduct> provisionedOrderItems {
        get {
            if (provisionedOrderItems == null) {
                populateProvisionedData();            
            }
            return provisionedOrderItems;
        }
        private set;
    }

    private void populateProvisionedData() {
        List<AggregateResult> provisionedProducts = tmDaoProvisioning.getTrialOrderItems(accountId, tenantId);
        provisionedOrderItems = new List<tmDomainTrialFeatureRequest.tmTrialProduct> ();
        if (provisionedProducts != null && provisionedProducts.size() > 0) {
            hasProvisionedTrialOrders = true;

            Set<Id> provisionedProductIds = new Set<Id> ();
            for (AggregateResult ar : provisionedProducts) {
                provisionedProductIds.add((Id)ar.get('Product2Id'));
            }

            Map<Id,Product2> productInfo = tmDaoProduct.getProductInfo(provisionedProductIds);

            for (AggregateResult ar : provisionedProducts) {
                Product2 p = productInfo.get((Id)ar.get('Product2Id'));
                tmDomainTrialFeatureRequest.tmTrialProduct tp = new tmDomainTrialFeatureRequest.tmTrialProduct(p.Id, p.Name, p.Description);
                tp.provisionedQuantity = Integer.valueOf((Decimal)ar.get('TotalQuantity'));
                tp.isTrialEligible = (p.Eligible_For_Trial__c == tmConstants.PRODUCT_ELIGIBLE_FOR_TRIAL_YES);
                tp.isCoreLicense = (p.Admin_Fulfillment__c == tmConstants.PRODUCT_ADMIN_FULFILLMENT_ADMIN);
                tp.requiresApproval = (!tmConstants.PRODUCTS_EXCLUDED_FROM_APPROVAL.containsKey(p.sfbase__SKU__c));
                provisionedOrderItems.add(tp);

                if (tp.isCoreLicense) {
                    existingOrderEdition = p.Edition_Visibility__c;
                }
            }
        }
    }

    public String existingTrialContractId {
        get {
            if (existingTrialContractId == null) {
                populateContractData();
            }
            return existingTrialContractId;
        }
        private set;
    }

    public Date existingTrialContractEndDate {
        get {
            if (existingTrialContractEndDate == null) {
                populateContractData();
            }
            return existingTrialContractEndDate;
        }
        private set;
    }  

    private void populateContractData() {
        List<OrderItem> orderItems = tmDaoProvisioning.getTrialContracts(accountId, tenantId);
        if (orderItems != null && orderItems.size() > 0) {
            existingTrialContractId = orderItems[0].Order.Contract.Id;
            existingTrialContractEndDate = orderItems[0].Order.Contract.EndDate;
        } else {
            existingTrialContractId = '';
            existingTrialContractEndDate = Date.newInstance(1900,1,1);
        }
    }

    public Id submitForProvisioning() {
        Id orderId;
        if (tfrDecorator != null) {
            if (String.isBlank(existingTrialContractId)) {
                orderId = tmDaoProvisioning.createOrderOnNewContract(newTrialContract, newTrialOrder, newTrialOrderItems, tfrDomain.priceBook2Id);
            } else {
                 if(tfrDecorator.requestType == tmConstants.REQUEST_TYPE_UPGRADE)
                 {
                    //get All existing order products and update End date with today date -1
                    List<OrderItem> trialOrderExistingLineItems = tmDaoProvisioning.getTrialOrderLineItems(accountId,tenantId);
                    for(OrderItem item : trialOrderExistingLineItems) {
                        item.sfbase__OrderItemEndDate__c = Date.today().addDays(-1);
                    }
                    orderId = tmDaoProvisioning.upgradeOrderOnExistingContract(Id.valueOf(existingTrialContractId), newTrialOrder, newTrialOrderItems,trialOrderExistingLineItems);
                 }
                else {
                     orderId = tmDaoProvisioning.createOrderOnExistingContract(Id.valueOf(existingTrialContractId), newTrialOrder, newTrialOrderItems);  
                }    
               
            }
            if (String.isNotBlank(orderId)) {
                tfrDecorator.tfr.Order__c = orderId;
                tmDaoTrialFeatureRequest.save(tfrDecorator.tfr,null);
            } else {
                throw new tmException(tmConstants.ERROR_SUBMITTING_FOR_PROVISIONING); 
            }
        } else {
            throw new tmException(tmConstants.ERROR_SUBMITTING_FOR_PROVISIONING); 
        }
        return orderId;
    }
    private Boolean isOrgPendingActivation {
        get {
            if (isOrgPendingActivation == null) {
                isOrgPendingActivation = false;
                populateCustomerSignedContractData();
            }
            return isOrgPendingActivation;
        }
        set;
    }

    private Date customerSignedContractStartDate {
        get {
            if (customerSignedContractStartDate == null) {
                populateCustomerSignedContractData();
            }
            return customerSignedContractStartDate;
        }
        private set;        
    }

    private void populateCustomerSignedContractData() {
        List<Contract> customerSignedContracts = tmDaoProvisioning.getCustomerSignedContract(accountId, tenantId);
        if (!customerSignedContracts.isEmpty()) {
            isOrgPendingActivation = true;
            customerSignedContractStartDate = customerSignedContracts[0].StartDate;
        }        
    }

    private Contract newTrialContract {
        get {
            if (newTrialContract == null) {
                newTrialContract = new Contract();
                newTrialContract.accountId = tfrDecorator.tfr.Account__c;
                newTrialContract.StartDate = Date.today();
                newTrialContract.CurrencyIsoCode = tfrDecorator.tfr.CurrencyIsoCode;
                newTrialContract.Pricebook2Id = tfrDomain.priceBook2Id;
                newTrialContract.sfbase__PaymentType__c = tmConstants.CONTRACT_PAYMENT_METHOD;
                newTrialContract.PaymentTerm = tmDaoProvisioning.getPaymentTerm(tfrDecorator.tfr.Account__r.BillingCountry);
                newTrialContract.sfbase__Customer_VAT_Number__c = tmConstants.CONTRACT_VAT_NUMBER_NA;
                newTrialContract.sfbase__ContractType__c = tmConstants.CONTRACT_TYPE_COURTSEY_CONTRACT;
                newTrialContract.sfbase__Billing_Frequency__c = tmConstants.CONTRACT_BILLING_FREQUENCY;
                newTrialContract.ContractTerm = tmConstants.CONTRACT_TERM_12_MONTHS;
                newTrialContract.AutoRenewCode = tmConstants.CONTRACT_AUTO_RENEWAL;
                newTrialContract.BillingLanguage = tmConstants.CONTRACT_BILLING_LANGUAGE;
                newTrialContract.BillingLastName = tmConstants.CONTRACT_SOURCE_TRIAL_MANAGER;
                newTrialContract.OrderPrebillDays = tmConstants.CONTRACT_ORDER_PREBILL_DAYS;
                newTrialContract.BillingCountry = tfrDecorator.tfr.Account__r.BillingCountry;
                newTrialContract.BillingPostalCode = tfrDecorator.tfr.Account__r.BillingPostalCode;
                newTrialContract.BillingState = tfrDecorator.tfr.Account__r.BillingState;
                newTrialContract.BillingCity = tfrDecorator.tfr.Account__r.BillingCity;
                newTrialContract.BillingStreet = tfrDecorator.tfr.Account__r.BillingStreet;
                newTrialContract.ShippingCountry = tfrDecorator.tfr.Account__r.BillingCountry;
                newTrialContract.ShippingPostalCode = tfrDecorator.tfr.Account__r.BillingPostalCode; 
                newTrialContract.ShippingState = tfrDecorator.tfr.Account__r.BillingState;
                newTrialContract.ShippingCity = tfrDecorator.tfr.Account__r.BillingCity;        
                newTrialContract.ShippingStreet = tfrDecorator.tfr.Account__r.BillingStreet;
                newTrialContract.SelfServiceQuoting__c = tmConstants.CONTRACT_SELFSERVICE_QUOTING;
                newTrialContract.sfbase__ContractCreationSource__c = tmConstants.CONTRACT_SOURCE_TRIAL_MANAGER;
            }
            return newTrialContract;
        }
        private set;    
    }

    private Order newTrialOrder {
        get {
            if (newTrialOrder == null) {
                newTrialOrder = new Order();
                newTrialOrder.Status = tmConstants.ORDER_STATUS_DRAFT;
                newTrialOrder.Type = tmConstants.ORDER_TYPE_TRIAL;
                newTrialOrder.isTrialorder = true;
                newTrialOrder.EffectiveDate = Date.today();
                newTrialOrder.sfbase__CustomerPORequired__c = tmConstants.ORDER_CUSTOMER_PO_REQUIRED;
                newTrialOrder.DoNotCommission__c = true;
                if (isOrgPendingActivation) {
                    newTrialOrder.sfbase__OrderEndDate__c = customerSignedContractStartDate - 1;
                }
            }
            return newTrialOrder;
        }
        private set;
    }

    private List<OrderItem> newTrialOrderItems {
        get {
            if (newTrialOrderItems == null) {
                newTrialOrderItems = new List<OrderItem> ();
                List<Id> requestedTrialProducts = new List<Id>();
                List<tmTrialFeatureRequestItem__c> updatedTfrItems = new List<tmTrialFeatureRequestItem__c>();
                Boolean foundSalesCloud = false;
                Boolean foundServiceCloud = false;

                for (tmTrialFeatureRequestItem__c tfrItem : tfrDecorator.tfrItems) {
                    if (!hasProvisionedTrialOrders) {
                        if (tfrDomain.salesCloud != null && tfrItem.Product__c.equals(tfrDomain.salesCloud.productId)) {
                            foundSalesCloud = true;
                            tfrItem.RequestedQuantity__c = tfrItem.RequestedQuantity__c + tfrItem.ProvisionedQuantity__c;
                        }
                        if (tfrDomain.serviceCloud != null && tfrItem.Product__c.equals(tfrDomain.serviceCloud.productId)) {
                            foundServiceCloud = true;
                            tfrItem.RequestedQuantity__c = tfrItem.RequestedQuantity__c + tfrItem.ProvisionedQuantity__c;
                        }  
                    }  
                    updatedTfrItems.add(tfrItem);  
                    requestedTrialProducts.add(tfrItem.Product__c);
                }

                //First time requesting the trial feature request, add core license product
                if (tfrDecorator.requestType == tmConstants.REQUEST_TYPE_NEW) {
                    if (tfrDecorator.isServiceCloudTrial && !foundServiceCloud) {
                        tmTrialFeatureRequestItem__c tfrItemServiceCloud = new tmTrialFeatureRequestItem__c();
                        tfrItemServiceCloud.Product__c = tfrDomain.serviceCloud.productId;
                        tfrItemServiceCloud.RequestedQuantity__c = tfrDomain.tenantDomain.crmLicenseCount;
                        updatedTfrItems.add(tfrItemServiceCloud);
                        requestedTrialProducts.add(tfrDomain.serviceCloud.productId);
                    } 

                    if (tfrDecorator.isSalesCloudTrial && !foundSalesCloud) {
                        tmTrialFeatureRequestItem__c tfrItemSalesCloud = new tmTrialFeatureRequestItem__c();
                        tfrItemSalesCloud.Product__c = tfrDomain.salesCloud.productId;
                        tfrItemSalesCloud.RequestedQuantity__c = tfrDomain.tenantDomain.crmLicenseCount;
                        updatedTfrItems.add(tfrItemSalesCloud);
                        requestedTrialProducts.add(tfrDomain.salesCloud.productId);
                    }
                }                
                
                Map<Id,Id> productPriceBookEntries = tmDaoProduct.getPriceBookEntriesForProducts(requestedTrialProducts,tfrDomain.priceBook2Id);

                for (tmTrialFeatureRequestItem__c tfrItem : updatedTfrItems) {
                    OrderItem oi = new OrderItem();
                    oi.PricebookEntryId = productPriceBookEntries.get(tfrItem.Product__c);
                    oi.Quantity = tfrItem.RequestedQuantity__c;
                    oi.UnitPrice = 0;
                    oi.sfbill__DoNotBill__c = true;
                    oi.createAssetLine__c = false;
                    newTrialOrderItems.add(oi);
                }
            }
            return newTrialOrderItems;
        }
        private set;
    }
}
