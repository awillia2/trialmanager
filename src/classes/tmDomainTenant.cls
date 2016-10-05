public with sharing class tmDomainTenant {
    public tmDomainTenant(Id acctId) {
    	 this.accountId = acctId;
    }

    private Id accountId {get; set;}

    public List<CspTenant> accountTenants {
       get { 
            if (accountTenants == null) { 
                accountTenants = CspTenantFactory.getCspTenantsForAccount(this.accountId);
                if (accountTenants == null) {
                  accountTenants = new List<CspTenant>();
                }
            }
            return accountTenants;
       }
       private set;
    }

    public CspTenantForceDotCom tenantForceDotCom {
        get { 
            if (tenantForceDotCom == null) { 
                for (CspTenant tnt : accountTenants) {
                  if (tnt.getTenantType() == CspTenantType.forceDotCom) {
                    tenantForceDotCom = (CspTenantForceDotCom)tnt;
                    break;
                  }
                }
            }
            return tenantForceDotCom;
        }
        private set;	
    }

    
    public Map<String, String> tenantProviderMap {
        get {
            if (tenantProviderMap == null) {
                tenantProviderMap = new Map<String, String>();
                List<Tenant> tenants = CspTenant.getTenants(new Set<Id>{accountId});
                for (Tenant t: tenants) {
                    tenantProviderMap.put(t.cloudServiceProviderId, t.externalId);
                }
            }
            return tenantProviderMap;
        }
        private set;
    }

    public Boolean hasATrialForceDotComTenant {
        get { 
            if (hasATrialForceDotComTenant == null) { 
                hasATrialForceDotComTenant = false;
                if (tenantForceDotCom != null && tenantForceDotCom.getStatus() == CspTenant.CspTenantStatus.TRIAL) {
                    hasATrialForceDotComTenant = true;
                }
            }
            return hasATrialForceDotComTenant;
        }
        private set;
    }    

    public String tenantForceDotComEdition {
       get { 
            if (tenantForceDotComEdition == null) { 
            	if (tenantForceDotCom != null) {
                    tenantForceDotComEdition = tenantForceDotCom.edition;
                }
            }
            return tenantForceDotComEdition;
       }
       private set;
    }

    public String tenantForceDotComExternalId {
        get { 
            if (tenantForceDotComExternalId == null) { 
            	if (tenantForceDotCom != null) {
                    tenantForceDotComExternalId = tenantForceDotCom.externalId;
                }
            }
            return tenantForceDotComExternalId;
        }
        private set;
    }

    public String tenantForceDotComId {
        get { 
            if (tenantForceDotComId == null) { 
                if (tenantForceDotCom != null) {
                    tenantForceDotComId = tenantForceDotCom.tenantRecord.Id;
                }
            }
            return tenantForceDotComId;
        }
        private set;
    }
    
    public Datetime trialExpirationDate {
        get { 
            if (trialExpirationDate == null) { 
                if (tenantForceDotCom != null) {
                    trialExpirationDate = tenantForceDotCom.trialExpirationDate;
                }
            }
            return trialExpirationDate;
        }
        private set;
    }

    public Boolean isServiceCloud {
        get { 
            if (isServiceCloud == null) { 
                if (tenantForceDotCom != null) {
                    isServiceCloud = tenantForceDotCom.provisionedPerms.containsIgnoreCase('Entitlements') && tenantForceDotCom.provisionedPerms.containsIgnoreCase('Support');
                }
            }
            return isServiceCloud;
        }
        private set;        
    }

    public Boolean isSalesCloud {
        get { 
            if (isSalesCloud == null) { 
                if (tenantForceDotCom != null) {
                    isSalesCloud = !isServiceCloud;  // if it is not ServiceCloud then it is Sales Cloud (Service Cloud is a superset of Sales Cloud)
                }
            }
            return isSalesCloud;
        }
        private set;        
    }    

    public Integer crmLicenseCount {
        get { 
            if (crmLicenseCount == null) { 
                if (tenantForceDotCom != null) {
                    crmLicenseCount = tenantForceDotCom.crmLicenseCount;
                }
            }
            return crmLicenseCount;
        }
        private set; 
    }
    
}