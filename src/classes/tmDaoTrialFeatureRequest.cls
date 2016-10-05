public with sharing class tmDaoTrialFeatureRequest {
    
    public static tmTrialFeatureRequest__c getTrialFeatureRequestAndItems(Id trialFeatureRequestId) { 
        tmTrialFeatureRequest__c tfr = [SELECT Account__r.BillingCity, Account__r.BillingCountry, Account__r.BillingPostalCode, Account__r.BillingState, Account__r.BillingStreet,
                                        Account__c, Contact__c, Id, Name, Order__c, Status__c, StartDate__c, Tenant__c, TrialOrderStatus__c, CurrencyIsoCode,TrialOrderType__c, Edition__c,AutoApprove__c,
                                            (SELECT Id, Product__c, Product__r.Name, Product__r.Description, Product__r.Eligible_for_Trial__c, Product__r.Admin_Fulfillment__c, Product__r.sfbase__SKU__c, 
                                                RequestedQuantity__c, ProvisionedQuantity__c, IsCoreLicense__c, RequiresApproval__c
                                                FROM TrialFeatureRequestItems__r)
                                        FROM tmTrialFeatureRequest__c 
                                        WHERE Id =: trialFeatureRequestId];
        return tfr;
    }

    public static tmTrialFeatureRequest__c initialize(Account acct, Id tenantId, String edition) {
        //Initialize TFR
        tmTrialFeatureRequest__c tfr = new tmTrialFeatureRequest__c();
        tfr.Account__c = acct.Id;
        tfr.Tenant__c = tenantId;
        tfr.Edition__c = edition;
        tfr.Status__c = tmConstants.TFR_STATUS_DRAFT;
        tfr.StartDate__c = Date.today();
        if (acct.BillingCountry != null) {
            tfr.CurrencyIsoCode = tmDaoProvisioning.getCurrencyCode(acct.BillingCountry);
        }
        return tfr;
    }


    public static List<tmTrialFeatureRequest__c> getFeatureRequestsByAccount(Id accountId) {
        return [select tenant__r.CloudServiceProviderId, tenant__r.ExternalId from tmTrialFeatureRequest__c where account__r.Id = :accountId];
    }

    public static Map<Id, Account> getAccounts(Set<Id> accountIds) {
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, RecordType.Name
            FROM Account
            WHERE id IN :accountIds]);
        return accounts;
    }

    public static String getUserCountry(Id userId) {
        List<User> u = [SELECT Id, ISO_Country__c FROM user WHERE Isactive = true AND Id = :userId];
        if (!u.isEmpty() && !String.isEmpty(u[0].ISO_Country__c)) {
            return u[0].ISO_Country__c;
        } else {
            return '';
        }
    }

    public static Account updateAccount(Account acct) {
        tmDaoTrialFeatureRequestHelper tfrHelper = new tmDaoTrialFeatureRequestHelper();
        return tfrHelper.doUpdateAccountWithoutSharing(acct);
    }

    public static tmTrialFeatureRequest__c save(tmTrialFeatureRequest__c tfr, List<tmTrialFeatureRequestItem__c> tfrItems) {
        tmDaoTrialFeatureRequestHelper tfrHelper = new tmDaoTrialFeatureRequestHelper();
        return tfrHelper.doUpsertTrialFeatureRequestWithoutSharing(tfr, tfrItems);
    }

    public static void deleteItems(List<tmTrialFeatureRequestItem__c> tfrItems) {
        tmDaoTrialFeatureRequestHelper tfrHelper = new tmDaoTrialFeatureRequestHelper();
        tfrHelper.doDeleteTrialFeatureItems(tfrItems);
    }


    private without sharing class tmDaoTrialFeatureRequestHelper {
        public tmTrialFeatureRequest__c doUpsertTrialFeatureRequestWithoutSharing(tmTrialFeatureRequest__c tfr, List<tmTrialFeatureRequestItem__c> tfrItems) {
            tfr.AutoApprove__c = isUserProfileInAutoApprovalList();
            upsert tfr;

            if (tfrItems != null && tfrItems.size() > 0) {
                delete [SELECT Id FROM tmTrialFeatureRequestItem__c WHERE TrialFeatureRequest__c = :tfr.Id];

                for (tmTrialFeatureRequestItem__c tfrItem : tfrItems) {
                    tfrItem.TrialFeatureRequest__c = tfr.Id;
                }
                insert tfrItems;
            }
            return tfr;
        }

        public void doDeleteTrialFeatureItems(List<tmTrialFeatureRequestItem__c> tfrItems) {
            if (tfrItems != null && tfrItems.size() > 0) {
                delete tfrItems;
            }
        }

        public Account doUpdateAccountWithoutSharing(Account acct) {
            Account a = new Account();
            if (acct != null) {
                a.Id = acct.Id;
                a.BillingCountry = acct.BillingCountry;
                if (String.isEmpty(acct.BillingStreet)) {
                    a.BillingStreet = tmConstants.DEFAULT_ACCOUNT_BILLING_STREET;
                }
                if (String.isEmpty(acct.BillingCity)) {
                    a.BillingCity = tmConstants.DEFAULT_ACCOUNT_BILLING_CITY;
                }                
                if (String.isEmpty(acct.BillingState)) {
                    a.BillingState = tmConstants.DEFAULT_ACCOUNT_BILLING_STATE;
                }
                if (String.isEmpty(acct.BillingPostalCode)) {
                    a.BillingPostalCode = tmConstants.DEFAULT_ACCOUNT_BILLING_ZIP;
                }
                update a;
            }
            return a;
        }

        private boolean isUserProfileInAutoApprovalList() {
            String profileName = [Select Id, Name from Profile where Id =  :UserInfo.getprofileId()] .Name;
            for(tmAutoApprovalProfileList__c tmAprovalProfile : tmAutoApprovalProfileList__c.getall().values()) {
                if(profileName == tmAprovalProfile.ProfileName__c){
                    return true;
                }
            }
            return  false;
        }
    }
}
