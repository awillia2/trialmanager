public with sharing class tmDomainTrialFeatureRequest {
    private Id accountId {get; set;}
    private Id tfrId {get; set;}
   
    public tmDomainTrialFeatureRequest(Id accountId, Id tfrId) {
        if (accountId == null && tfrId == null) {
            tmEx.errors.add(tmConstants.ERROR_ACCOUNT_TFRID_MISSING); 
            throw tmEx;
        }
        if (tfrId != null) {
            this.tfrId = tfrId;
            //tfrDomain is initiated to create,edit or submit for provisioning
            if (!canEdit && !canSubmitForProvisioning) 
                throw tmEx; 
        } else {
            this.accountId = accountId;
            if (!canCreate) 
                throw tmEx; 
        }  
        if (tfrDecorator == null) { 
            tmEx.errors.add(tmConstants.ERROR_INITIALIZE_TRIAL_FEATURE_REQUEST);
            throw tmEx; 
        } 
    }

    private Boolean canCreate {
        get {
            canCreate = true;

            if (isInternalAccount) {
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_INTERNAL_ACCOUNT);
            }

            if (!tenantDomain.hasATrialForceDotComTenant) {
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_TENANT_MISSING);
            } else if (!hasValidEdition) {
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_EDITION);
            }

            if (!isDemoAccount && !hasValidBillingAddress) {
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_BILLING_ADDRESS); 
            }

            if (!isDemoAccount && !hasValidIsoCountryCode) {
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_ISO_COUNTRY_CODE);
            }

            if (!isOrgValid) { 
                canCreate = false;
                tmEx.errors.add(tmConstants.ERROR_ORG_CHANGED);
            }

            return canCreate;
        }
        private set;        
    }

    private Boolean canEdit {
        get {
            canEdit = true;

            if (!tfrDecorator.canEdit) {
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_TFR_CANNOT_BE_EDITED);                
            }

            if (!tenantDomain.hasATrialForceDotComTenant) {
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_TENANT_MISSING);
            } else if (!hasValidEdition) {
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_EDITION);
            }            
            
            if (!hasValidBillingAddress) {
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_BILLING_ADDRESS); 
            }

            if (!hasValidIsoCountryCode) {
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_INVALID_ISO_COUNTRY_CODE);
            }

            if (!isOrgValid) { 
                canEdit = false;
                tmEx.errors.add(tmConstants.ERROR_ORG_CHANGED);
            }

            return canEdit;
        }
        private set;        
    }

    public Boolean isDemoAccount {
        get {
            if (isDemoAccount == null) {
                //NOTE: Demo accounts in Org62 are tagged as "Trial Org" record types
                isDemoAccount = acct.RecordType.Name.equalsIgnoreCase(tmConstants.ACCOUNT_RECORDTYPE_TRIALORG);
               }
               return isDemoAccount;
            }
        private set;
    }
    public String edition {
        get {
            if (edition == null) {
                edition = tenantDomain.tenantForceDotComEdition;
               }
               return edition;
            }
         set;
    }

    private Boolean isInternalAccount {
        get {
            if (isInternalAccount == null) {
                isInternalAccount = tmConstants.INTERNAL_ACCOUNTS.contains(accountId);
            }
            return isInternalAccount;
        }
        private set;
    }

    private Boolean hasValidEdition {
        get {
            if (hasValidEdition == null) {
                hasValidEdition = tmConstants.VALID_EDITIONS.contains(tenantDomain.tenantForceDotComEdition.toLowerCase());
            }
            return hasValidEdition;
        }
        private set;
    }    

    private Boolean hasValidBillingAddress {
        get {
            if (hasValidBillingAddress == null) {
                
                List<String> requiredFields = new List<String>{'BillingCity', 'BillingCountry', 'BillingStreet'};

                hasValidBillingAddress = true;
                if (acct.get('BillingCountry') != null) {
                    if (String.valueOf(acct.get('BillingCountry')).equalsIgnoreCase(tmConstants.US_COUNTRY_CODE)) {
                        requiredFields.addAll(new List<String>{'BillingPostalCode', 'BillingState'});
                    }
                }
                for (String s : requiredFields) {
                    if (acct.get(s) == null || String.isBlank((String)acct.get(s))) {
                        hasValidBillingAddress = false;
                        break;
                    }
                }
            }
            return hasValidBillingAddress;
        }
        private set;
    }

    public Boolean hasValidIsoCountryCode {
        get {
            hasValidIsoCountryCode = false;
            if (acct.get('BillingCountry') != null && String.valueOf(acct.get('BillingCountry')).length() == 2) {
                hasValidIsoCountryCode = true;
            } 
            return hasValidIsoCountryCode;
        }
        set;
    }

    public Boolean isOrgValid {
        get {
            isOrgValid = true;
            List<tmTrialFeatureRequest__c> accountRequests = accountTrialFeatureRequests;
            Map<String, String> accountTenantInfo = tenantDomain.tenantProviderMap;

            for (tmTrialFeatureRequest__c tfr : accountRequests) {
                if (!accountTenantInfo.containsKey(tfr.Tenant__r.CloudServiceProviderId)) {
                    isOrgValid = false;
                    break;
                }
                else if (!(accountTenantInfo.get(tfr.Tenant__r.CloudServiceProviderId) == tfr.Tenant__r.ExternalId)) {
                    isOrgValid = false;
                }
            }

            return isOrgValid; 
        }
        private set;
    }    

    private Boolean canSubmitForProvisioning {
        get {
            return tenantDomain.hasATrialForceDotComTenant;
        }
        private set;
    }   

    public String countryCode {
        get {
            if (countryCode == null) {
                if (hasValidIsoCountryCode) {
                    countryCode = String.valueOf(acct.get('BillingCountry'));
                } else {
                    countryCode = tmDaoTrialFeatureRequest.getUserCountry(UserInfo.getUserId());
                } 
                
                if (String.isBlank(countryCode)) {
                    countryCode = tmConstants.US_COUNTRY_CODE;
                }
            }
            return countryCode;
        }
        set;
    } 

    private Account acct {
        get {
            if (acct == null) {
                acct = tmDaoTrialFeatureRequest.getAccounts(new Set<Id>{accountId}).get(accountId);
            }
            return acct;
        }
        private set;
    }

    public Id priceBook2Id {
        get {
            return tmDaoProduct.getPriceBookForCurrency(tmDaoProvisioning.getCurrencyCode(countryCode));
        }
        set;
    }

    private tmException tmEx {
        get { 
            if (tmEx == null) { 
                tmEx = new tmException();
            }
            return tmEx;
       }
       private set; 
    }    

    public tmDomainTenant tenantDomain {
        get { 
            if (tenantDomain == null) { 
                tenantDomain = new tmDomainTenant(accountId);
            }
            return tenantDomain;
       }
       private set; 
    }

    public tmDomainProvisioning provisioningDomain {
        get { 
            if (provisioningDomain == null) { 
                provisioningDomain = new tmDomainProvisioning(accountId,tenantDomain.tenantForceDotComId);
            }
            return provisioningDomain;
       }
       private set; 
    }

    public tmDecoratorTrialFeatureRequest tfrDecorator {
        get {
            if (tfrDecorator == null) {
                tmTrialFeatureRequest__c tfr = new tmTrialFeatureRequest__c();
                if (tfrId == null) {
                    tfrDecorator = new tmDecoratorTrialFeatureRequest(acct,tenantDomain.tenantForceDotComId,tenantDomain.tenantForceDotComEdition);
                }
                else {
                    tfrDecorator = new tmDecoratorTrialFeatureRequest(tfrId);
                }
                this.accountId = tfrDecorator.accountId;
                tfrDecorator.trialExpirationDate = tenantDomain.trialExpirationDate;
                tfrDecorator.isSalesCloudTrial = tenantDomain.isSalesCloud;
                tfrDecorator.isServiceCloudTrial = tenantDomain.isServiceCloud;
            }
            return tfrDecorator;
        }
        set;
    } 

    public List<tmTrialProduct> productCatalog {
        get {
            List<Product2> trialProducts = tmDaoProduct.getTrialProductsForEdition(edition,priceBook2Id);
            productCatalog = new List<tmTrialProduct>();

            for (Product2 p : trialProducts) {
                tmTrialProduct tp = new tmTrialProduct(p);
                tp.isTrialEligible = true;
                tp.requiresApproval = (!tmConstants.PRODUCTS_EXCLUDED_FROM_APPROVAL.containsKey(p.sfbase__SKU__c));
                productCatalog.add(tp);
            }
            return productCatalog;
        }
        private set;
    }

    public List<tmTrialTemplate> templateCatalog {
        get {
            List<tmTrialManagerTemplate__c> templateCatalogItems = tmDaoTemplate.templatesWithProducts;
            templateCatalog = new List<tmTrialTemplate>();
            if (templateCatalogItems != null) {
                for (tmTrialManagerTemplate__c tt: templateCatalogItems) {
                    templateCatalog.add(new tmTrialTemplate(tt));
                }
            }
            return templateCatalog;
        }
        private set;
    }

    public List<tmTrialProduct> selectedProducts {
        get { 
            if (selectedProducts == null) { 
                selectedProducts = new List<tmTrialProduct>();
                for (tmTrialFeatureRequestItem__c tfrItem : tfrDecorator.tfrItems) {
                    tmTrialProduct tp = new tmTrialProduct(tfrItem.Product__c, tfrItem.Product__r.Name, tfrItem.Product__r.Description);
                    tp.additionalQuantity = (Integer)tfrItem.RequestedQuantity__c;
                    tp.isTrialEligible = (tfrItem.Product__r.Eligible_for_Trial__c == tmConstants.PRODUCT_ELIGIBLE_FOR_TRIAL_YES);
                    tp.isCoreLicense = (tfrItem.Product__r.Admin_Fulfillment__c == tmConstants.PRODUCT_ADMIN_FULFILLMENT_ADMIN);
                    tp.requiresApproval = (!tmConstants.PRODUCTS_EXCLUDED_FROM_APPROVAL.containsKey(tfrItem.Product__r.sfbase__SKU__c));
                    selectedProducts.add(tp);
                }
            }
            if(selectedProducts.isEmpty() && requestType == tmConstants.REQUEST_TYPE_UPGRADE) {
                if (tenantDomain.isServiceCloud) {
                    serviceCloud.additionalQuantity = tenantDomain.crmLicenseCount;
                    selectedProducts.add(serviceCloud);
                } 
                if (tenantDomain.isSalesCloud) {
                    salesCloud.additionalQuantity = tenantDomain.crmLicenseCount;
                    selectedProducts.add(salesCloud);
                }
            }
            return selectedProducts;
        }
        set;    
    }

    public List<tmTrialProduct> provisionedProducts {
        get { 
            if (provisionedProducts == null) { 
                provisionedProducts = new List<tmTrialProduct> ();
                if (requestType == tmConstants.REQUEST_TYPE_ADDON) {
                    provisionedProducts = provisioningDomain.provisionedOrderItems;
                }  
                if(requestType == tmConstants.REQUEST_TYPE_NEW) {
                    provisionedProducts = new List<tmTrialProduct> ();
                    if (tenantDomain.isServiceCloud) {
                        serviceCloud.provisionedQuantity = tenantDomain.crmLicenseCount;
                        provisionedProducts.add(serviceCloud);
                    } 
                    if (tenantDomain.isSalesCloud) {
                        salesCloud.provisionedQuantity = tenantDomain.crmLicenseCount;
                        provisionedProducts.add(salesCloud);
                    }
                }
            }
            return provisionedProducts;
        }
        set;    
    }

    private static boolean isCoreProductsFetched = false;
    public tmTrialProduct salesCloud { 
        get {
            if ((salesCloud == null || requestType == tmConstants.REQUEST_TYPE_UPGRADE) && !isCoreProductsFetched) {
                populateCoreProducts();
            }
           return  salesCloud;
        } 
        set;
    }

    public tmTrialProduct serviceCloud { 
        get {
            if ((serviceCloud == null || requestType == tmConstants.REQUEST_TYPE_UPGRADE) && !isCoreProductsFetched) {
                populateCoreProducts();
            }
            return serviceCloud;
        } 
        set;
    }

    private void populateCoreProducts() {
        List<PriceBookEntry> coreProducts = tmDaoProduct.getCoreProducts(edition, priceBook2Id);
        isCoreProductsFetched = true; // TO skip multiple calls to get core products.
        for (PriceBookEntry pbe : coreProducts) {
            if (String.isNotBlank(pbe.Product2.Sales_Edition__c)) {
                salesCloud = new tmTrialProduct(pbe.Product2.Id, pbe.Product2.Name, pbe.Product2.Description);
                salesCloud.isCoreLicense = true;
                salesCloud.isTrialEligible = true;
                salesCloud.requiresApproval = false;
            } else if (String.isNotBlank(pbe.Product2.Service_Edition__c)) {
                serviceCloud = new tmTrialProduct(pbe.Product2.Id, pbe.Product2.Name, pbe.Product2.Description);
                serviceCloud.isCoreLicense = true;
                serviceCloud.isTrialEligible = true;
                serviceCloud.requiresApproval = false;                        
            }
        }
    }

    public void deleteTFRItems() {
        if (!tfrDecorator.tfrItems.isEmpty()) {
            tfrDecorator.deleteItems();
        }

    }
    public String requestType {
        get {
            if (requestType == null) {
                if (provisioningDomain.hasProvisionedTrialOrders)
                    requestType = tmConstants.REQUEST_TYPE_ADDON;
                else  
                    requestType = tmConstants.REQUEST_TYPE_NEW;  
            } 
            return requestType;
        }    
        set;
    }
    
    public void save() { 

        if (!tmEx.errors.isEmpty())
            tmEx.errors.clear();
        List<tmTrialFeatureRequestItem__c> tfrItems = new List<tmTrialFeatureRequestItem__c>();
        Boolean isCoreProductCountDecreased = false;
        for (tmTrialProduct tp : selectedProducts) {
            if (tp.additionalQuantity > 0) {
                tmTrialFeatureRequestItem__c tfrItem = new tmTrialFeatureRequestItem__c();
                tfrItem.Product__c= tp.productId;
                tfrItem.RequestedQuantity__c = tp.additionalQuantity;
                tfrItem.ProvisionedQuantity__c =  tp.provisionedQuantity;
                tfrItem.IsCoreLicense__c = tp.isCoreLicense;
                tfrItem.RequiresApproval__c = tp.requiresApproval;
                tfrItems.add(tfrItem);                
            }
        }
        if (tfrItems.isEmpty()) {
            tmEx.errors.add(tmConstants.ERROR_MISSING_TRIAL_FEATURE_REQUEST_ITEMS);    
            throw tmEx;   
        } else {
            //Save the account's billing country
            if (String.isEmpty(String.valueOf(acct.get('BillingCountry')))) {
                acct.BillingCountry = countryCode;
                acct = tmDaoTrialFeatureRequest.updateAccount(acct);
            }
            //Save TFR             
            tfrDecorator.tfrItems = tfrItems;
            tfrDecorator.tfr.currencyIsoCode = tmDaoProvisioning.getCurrencyCode(countryCode);
            tfrDecorator.trialExpirationDate = tenantDomain.trialExpirationDate;
            tfrDecorator.tfr.TrialOrderType__c = requestType ;
            tfrDecorator.save();
        }            
    } 

    public void saveAndSubmitForApproval() {
            save();
            Approval.ProcessSubmitRequest tfrApprovalRequest = new Approval.ProcessSubmitRequest();
            tfrApprovalRequest.setObjectId(tfrDecorator.tfr.Id);
            Approval.ProcessResult tfrApprovalResult = Approval.process(tfrApprovalRequest);

            if (!tfrApprovalResult.isSuccess()) {
                tmEx.errors.add(tmConstants.ERROR_SUBMITTING_FOR_APPROVAL + ' ' + tfrApprovalResult.getErrors()); 
                throw tmEx;
            } 
    }  

    public List<tmTrialFeatureRequest__c> accountTrialFeatureRequests {
        get {
            if (accountTrialFeatureRequests == null) {
                accountTrialFeatureRequests = tmDaoTrialFeatureRequest.getFeatureRequestsByAccount(accountId);
            }
            return accountTrialFeatureRequests;
        }
        private set;
    }

    public with sharing class tmDecoratorTrialFeatureRequest {
        public tmTrialFeatureRequest__c tfr { get; private set;}
        public Id accountId {get; private set;}
        public Id tenantId {get; private set;}
        public Boolean isDraft { get; private set;}
        public Boolean isApproved { get; private set;}
        public Boolean isProvisioned { get; private set;}
        public Boolean isRejected { get; private set;}
        public Datetime trialExpirationDate {get; set;}
        public Boolean isSalesCloudTrial {get; set;}
        public Boolean isServiceCloudTrial {get; set;}
        public List<tmTrialFeatureRequestItem__c> tfrItems {get; set;}
        public String requestType {get; set;}
        

        public tmDecoratorTrialFeatureRequest(Id tfrId) {
            this(tmDaoTrialFeatureRequest.getTrialFeatureRequestAndItems(tfrId));
        }

        public tmDecoratorTrialFeatureRequest(Account acct, Id tenantId, String edition) {
            this(tmDaoTrialFeatureRequest.initialize(acct, tenantId, edition));
        }

        public tmDecoratorTrialFeatureRequest(tmTrialFeatureRequest__c tfr)  {
            this.tfr = tfr;
            populateTrialFeatureRequest();
        }

        private void populateTrialFeatureRequest() {
            accountId = tfr.Account__c;
            tenantId = tfr.Tenant__c;
            isDraft = (tfr.Status__c == tmConstants.TFR_STATUS_DRAFT);
            isApproved = (tfr.Status__c == tmConstants.TFR_STATUS_APPROVED);
            isProvisioned = (tfr.Status__c == tmConstants.TFR_STATUS_PROVISIONED);
            isRejected = (tfr.Status__c == tmConstants.TFR_STATUS_REJECTED);
            tfrItems = new List<tmTrialFeatureRequestItem__c>();
            if (tfr.TrialFeatureRequestItems__r != null) {
                for (tmTrialFeatureRequestItem__c tfrItem : tfr.TrialFeatureRequestItems__r) {
                    tfrItems.add(tfrItem);
                }
            }
            requestType =  tfr.TrialOrderType__c;

        }

        public Boolean canDelete {
            get {
                return this.isDraft;
            }
            private set;
        }

        public Boolean canEdit {
            get {
                return this.isDraft || this.isRejected;
            }
            private set;
        }

        public void save() {
            this.tfr = tmDaoTrialFeatureRequest.save(this.tfr,this.tfrItems);
            populateTrialFeatureRequest();
        }

        public void deleteItems() {
            tmDaoTrialFeatureRequest.deleteItems(this.tfrItems);
            tfrItems.clear();
        }

    }

    public with sharing class tmTrialTemplate {
        public tmTrialManagerTemplate__c template { get; private set; }
        public List<tmTrialManagerTemplateProduct__c> templateProducts {
            get {
                if (templateProducts == null) {
                    templateProducts = new List<tmTrialManagerTemplateProduct__c>();
                }
                return templateProducts;
            }
            private set;
        }

        public tmTrialTemplate(tmTrialManagerTemplate__c t) {
            this.template = t;
            if (t.TFR_Template_Products__r.size() > 0)
                this.templateProducts = t.TFR_Template_Products__r;
        }

        public String templateId {
            get {
                if (templateId == null) {
                    templateId = this.template.Id;
                }
                return templateId;
            }
            private set;
        }

        public String description {
            get {
                if (description == null) {
                    description = template.Description__c;
                }
                return description;
            }
            private set;
        }

        public String name {
            get {
                if (name == null) {
                    name = template.Name;
                }
                return name;
            }
            private set;
        }
    }

    public with sharing class tmTrialProduct {
        public Product2 prod { get;  private set;}

        public tmTrialProduct(Product2 p) {
            this.prod = p;
        }

        public tmTrialProduct(Id productId, String productName, String productDescription) {
            this.productId = productId;
            this.name = productName;
            this.description = productDescription;
        }

        public String productId {
            get {
                if (productId == null)
                    productId = prod.id;

                return productId;
            }
            private set;
        }

        public String name {
            get {
                if (name == null)
                    name = prod.name;

                return name;
            }
            private set;
        }

        public String description {
            get {
                if (description == null)
                    description = prod.Description;

                return description;
            }
            private set;
        }        

        public Boolean isTrialEligible { 
            get {
                if (isTrialEligible == null) {
                    isTrialEligible = false;
                }
                return isTrialEligible;
            }
            set;
        }        

        public Integer provisionedQuantity { 
            get {
                if (provisionedQuantity == null)
                    provisionedQuantity = 0;
                
                return provisionedQuantity;
            }
            set;
        }

        public Integer additionalQuantity {
            get {
                if (additionalQuantity == null)
                    additionalQuantity = 0;
                
                return additionalQuantity;
            }
            set;
        }

        public Boolean isCoreLicense {
            get {
                if (isCoreLicense == null)
                    isCoreLicense = (prod.Admin_Fulfillment__c == tmConstants.PRODUCT_ADMIN_FULFILLMENT_ADMIN);
                
                return isCoreLicense;
            }
            set;
        }
        public Boolean requiresApproval {
            get {
                if (requiresApproval == null)
                    requiresApproval = (!tmConstants.PRODUCTS_EXCLUDED_FROM_APPROVAL.containsKey(prod.sfbase__SKU__c));
                
                return requiresApproval;
            }
            set;
        }
    }
}
    