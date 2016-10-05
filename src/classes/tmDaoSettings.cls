public with sharing class tmDaoSettings {
    
    public static Map<String, tmProductsExcludedFromApproval__c> productsExcludedFromApproval {
        get {
            if (productsExcludedFromApproval == null) {
                 productsExcludedFromApproval = tmProductsExcludedFromApproval__c.getAll();
            }
            return  productsExcludedFromApproval;
        }
        private set;
    }

    public static Set<Id> internalAccounts {
        get {
            if (internalAccounts == null) {
                 internalAccounts = new Set<Id>();
                 List<tmInternalAccounts__c> accts = tmInternalAccounts__c.getAll().values();

                for (tmInternalAccounts__c acct : accts) {
                    internalAccounts.add(Id.valueOf(acct.Name));
                 }
            }
            return  internalAccounts;
        }
        private set;
    }    

    public static String pricebookClause {
        get {
            if (pricebookClause == null) {
                pricebookClause = tmSettings__c.getInstance(tmConstants.PRICEBOOK_CLAUSE).Value__c;
            }
            return String.escapeSingleQuotes(pricebookClause);
        }
        private set;
    }      
}