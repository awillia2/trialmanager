public virtual with sharing class tmConstants {
    public static String CSP_TENANT_TYPE_FORCEDOTCOM { get {return 'force.com';} private set;}
    public static Set<String> VALID_EDITIONS {
        get {
            if (VALID_EDITIONS == null)
                VALID_EDITIONS = new Set<String> {'unlimited','enterprise','professional','group','performance'};

            return VALID_EDITIONS;
        }
        private set;
    }

    public static String ACCOUNT_RECORDTYPE_TRIALORG { get {return 'Trial Org';} private set;}
    public static String DEFAULT_ACCOUNT_BILLING_STREET { get {return 'Trial Demo';} private set;}
    public static String DEFAULT_ACCOUNT_BILLING_CITY { get {return 'Trial Demo';} private set;}
    public static String DEFAULT_ACCOUNT_BILLING_STATE { get {return 'Trial Demo';} private set;}
    public static String DEFAULT_ACCOUNT_BILLING_ZIP { get {return '97124';} private set;}

    public static String TFR_STATUS_DRAFT { get {return 'Draft';} private set;}
    public static String TFR_STATUS_IN_APPROVAL { get {return 'In Approval';} private set;}
    public static String TFR_STATUS_APPROVED { get {return 'Approved';} private set;}
    public static String TFR_STATUS_PROVISIONED { get {return 'Provisioned';} private set;}
    public static String TFR_STATUS_REJECTED { get {return 'Rejected';} private set;}
    public static String TFR_DEFAULT_CURRENCY { get {return 'USD';} private set;}

    public static String PRODUCT_ELIGIBLE_FOR_TRIAL_YES { get {return 'Yes';} private set;}
    public static String PRODUCT_ELIGIBLE_FOR_TRIAL_DEMO { get {return 'Demo';} private set;}
    public static String PRODUCT_ADMIN_FULFILLMENT_ADMIN { get {return 'Admin';} private set;}
    public static String US_COUNTRY_CODE { get { return 'US'; } private set; }

    public static String CONTRACT_STATUS_ACTIVATED { get {return 'Activated';} private set;}
    public static String CONTRACT_TYPE_COURTSEY_CONTRACT { get {return 'Courtesy Contract';} private set;}
    public static String CONTRACT_RECORD_TYPE_SALES { get {return 'Sales';} private set;}
    public static String CONTRACT_AUTO_RENEWAL { get {return 'No';} private set;}
    public static String CONTRACT_BILLING_LANGUAGE { get {return 'en_US';} private set;}
    public static String CONTRACT_SOURCE_TRIAL_MANAGER { get {return 'Trial Manager';} private set;}
    public static String CONTRACT_PAYMENT_METHOD { get {return 'WireTransfer';} private set;}
    public static String CONTRACT_PAYMENT_TERM { get {return 'NET30';} private set;}
    public static String CONTRACT_VAT_NUMBER_NA { get {return 'N/A';} private set;}
    public static Integer CONTRACT_ORDER_PREBILL_DAYS { get {return 30;} private set;}
    public static String CONTRACT_BILLING_FREQUENCY { get {return '1';} private set;}
    public static Integer CONTRACT_TERM_12_MONTHS {get {return 12;} private set;}
    public static String CONTRACT_SELFSERVICE_QUOTING {get {return 'No';} private set;}
    public static String ORDER_STATUS_DRAFT { get {return 'Draft';} private set;}
    public static String ORDER_STATUS_ACTIVATED { get {return 'Activated';} private set;}
    public static String ORDER_STATUS_PROVISIONED { get {return 'Provisioned';} private set;}
    public static String ORDER_TYPE_TRIAL { get {return 'Trial';} private set;}
    public static String ORDER_CUSTOMER_PO_REQUIRED { get {return 'N/A';} private set;}
    public static String ORDER_RECORD_TYPE_NB { get {return 'New Business';} private set;}

    // Constants that can be configured using custom settings
    public static Map<String, tmProductsExcludedFromApproval__c> PRODUCTS_EXCLUDED_FROM_APPROVAL { get { return tmDaoSettings.productsExcludedFromApproval; } private set;}
    public static Set<Id> INTERNAL_ACCOUNTS {get { return tmDaoSettings.internalAccounts; } private set;}
    public static String PRICEBOOK_CLAUSE { get {return 'PriceBookLikeClause';} private set;}
    public static Boolean CAN_USE_TEMPLATES { get { return tmTrialManagerTemplate__c.SObjectType.getDescribe().isAccessible(); } private set; }
    public static Boolean TEMPLATES_ENABLED { get { return (tmSettings__c.getInstance('tmTemplatesEnabled') != null && tmSettings__c.getInstance('tmTemplatesEnabled').Value__c.equalsIgnoreCase('true')); } private set; }

    //Labels
    public static String ERROR_ACCOUNT_TFRID_MISSING {get {return Label.tmAccountTFRRequired;} private set;}
    public static String ERROR_ACCOUNT_TENANT_MISSING {get {return Label.tmAccountTenantRequired;} private set;}
    public static String ERROR_TENANT_MISSING {get {return Label.tmTenantRequired;} private set;}
    public static String ERROR_INITIALIZE_TRIAL_FEATURE_REQUEST {get {return Label.tmTFRInitializeFailed;} private set;}
    public static String ERROR_SUBMITTING_FOR_PROVISIONING {get {return Label.tmTFROrderCreationFailed;} private set;}
    public static String ERROR_SAVING_TRIAL_FEATURE_REQUEST {get {return Label.tmTFRSaveFailed;} private set;}
    public static String ERROR_SUBMITTING_FOR_APPROVAL {get {return Label.tmTFRSubmitForApprovalFailed;} private set;}
    public static String ERROR_ORG_CHANGED {get {return Label.tmOrgChanged;} private set;}
    public static String ERROR_TFR_DELETE_LABEL {get {return Label.tmTFRDeleteMsg;} private set;}
    public static String ERROR_TFR_CANNOT_BE_EDITED {get {return Label.tmCannotEditMsg;} private set;}
    public static String ERROR_INVALID_BILLING_ADDRESS {get { return Label.tmInvalidBillingAddress; } private set; }
    public static String ERROR_INTERNAL_ACCOUNT {get { return Label.tmInternalAccount; } private set; }
    public static String ERROR_INVALID_EDITION {get { return Label.tmInvalidEdition; } private set; }
    public static String ERROR_INVALID_ISO_COUNTRY_CODE {get { return Label.tmInvalidISOCountryCode; } private set; }
    public static String ERROR_MISSING_TRIAL_FEATURE_REQUEST_ITEMS {get { return Label.tmMissingTFRItems; } private set; }
    public static String ERROR_UPGRADE_TFR_CORE_PRODUCT_COUNT {get { return Label.tmUpgradeTFRCoreProductCount; } private set; }

     public static Map<Integer, String> EDITION_ORDER_MAP {
        get {
            if (Edition_ORDER_MAP == null)
                EDITION_ORDER_MAP = new Map<Integer, String> { 1 => 'Group',
                                                              2 => 'Professional',
                                                              3 => 'Enterprise',
                                                              4 => 'Unlimited',
                                                              5 => 'Performance' };
            return EDITION_ORDER_MAP;
           }
        private set;
    }
   
     public static String NON_UPGRADE_EDITION_LIST {get { return 'Unlimited,Performance'; } private set; }
     public static String REQUEST_TYPE_UPGRADE {get { return 'Upgrade'; } private set; }
     public static String REQUEST_TYPE_ADDON {get { return 'Addon'; } private set; }
     public static String REQUEST_TYPE_NEW {get { return 'New'; } private set; }
     public static String CHATTER_GROUP_NAME {get { return 'Trial Manager'; } private set; }
 
 }