/*
*   This class will manage the visualforce page for Trial Org Provisioning. 
*       @project: IT Commerce
*       @dev: creinke
*/
public with sharing class tmControllerTrialFeatureRequest {
    public Id tfrId { get; private set; }
    public Id tfrAccountId { get; private set; }
    public Boolean showSaved { get; private set; }
    public Boolean showForm { get; private set; }
    public String productToRemove { get; set; }
    public String productToAdd { get; set; }
    public String templateToAdd { get; set; }
    
    /*
    *   Class Constructor: If the record is new, no ID, then do not show the saved tag. If the page has
    *       an ID then show it until the user modifies anything on the page. If the tfrDomain is empty
    *       then throw an error to the page.
    */
    public tmControllerTrialFeatureRequest (ApexPages.StandardController controller) {
        try {
            displayUpgradeToEditionSection = false;
            showSaved = false;
            showForm = true;
            if (!Test.isRunningTest()) controller.addFields(new String[]{'Account__c'});
            tmTrialFeatureRequest__c tmTFR = (tmTrialFeatureRequest__c)controller.getRecord();
            if (tmTFR != null) {
                tfrId = tmTFR.Id;
                tfrAccountId = tmTFR.Account__c;
                if(tfrDomain != null && tfrDomain.tfrDecorator.tfr != null && tfrDomain.tfrDecorator.tfr.TrialOrderType__c == tmConstants.REQUEST_TYPE_UPGRADE ) {
                    displayUpgradeToEditionSection = true;
                    upgradeToEditionName = tfrDomain.tfrDecorator.tfr.Edition__c;
                    tfrDomain.edition = upgradeToEditionName;
                    tfrDomain.requestType = tmConstants.REQUEST_TYPE_UPGRADE;
                }
            }
            if (tfrDomain == null) { 
                showForm = false; 
            }
            if(apexPages.currentPage().getParameters().get('showSaveMsg') != null) {
                showSaved = true;
            }
        } catch (tmException tmEx) {
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
            showForm = false; 
            tmOrgLog.log(BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.tmControllerTrialFeatureRequest',tmEx.errorString ,tfrId);
        } catch (Exception ex) {
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.tmControllerTrialFeatureRequest',ex.getMessage(),tfrId);
        }
    }

    /*
    * Loads countries from Country Revenue Map object
    */
    private List<sfbase__CountryRevenueMap__c> countryList {
        get {
            if (countryList == null) {
                countryList = tmDaoProvisioning.getISOCountryList();
            }
            return countryList;
        }
        private set;
    }

    public List<SelectOption> countryOptions {
        get {
            if (countryOptions == null) {
                countryOptions = new List<SelectOption>();
                for (sfbase__CountryRevenueMap__c countryMap : countryList) {
                    countryOptions.add(new SelectOption(countryMap.sfbase__CountryISOCode__c,countryMap.sfbase__CountryName__c));       
                }
            }
            return countryOptions;
        }
        private set;
    }

    public Boolean isCountryEditable {
        get {
            return tfrDomain.isDemoAccount && !tfrDomain.hasValidIsoCountryCode;
        }
        private set;
    }

    public String selectedCountryName {
        get {
            for (sfbase__CountryRevenueMap__c countryMap : countryList) {
                if (tfrDomain.countryCode.equalsIgnoreCase(countryMap.sfbase__CountryISOCode__c)) {
                    selectedCountryName  = countryMap.sfbase__CountryName__c;
                    break;
                }
            }
            return selectedCountryName;
        }
        private set;        
    }

    private String objectIdForLog {
        get {

            return tfrDomain!= null && tfrDomain.tfrDecorator != null && tfrDomain.tfrDecorator.tfr !=null && tfrDomain.tfrDecorator.tfr.Id != null ?  tfrDomain.tfrDecorator.tfr.Id  : tfrAccountId ;
        }
        private set;        
    }

    /*
    *   Save the TFR and if it is an insert then take the user to the Edit page for that record. If
    *       The TFR already exists then only refresh page with a return null.
    */
    public PageReference saveTfr() {
        showSaved = true;
        try {
            updateUpgradeInfoToTFR();
            tfrDomain.selectedProducts = orgProducts;
            if (tfrDomain.tfrDecorator.canEdit) {
                tfrDomain.save();
            }
            
            if (String.isBlank(tfrId)) {
                tmTrialFeatureRequest__c t = new tmTrialFeatureRequest__c(Id = tfrDomain.tfrDecorator.tfr.Id);
                ApexPages.StandardController sc = new ApexPages.StandardController(t);
                PageReference p = sc.edit();
                p.getParameters().put('id', tfrDomain.tfrDecorator.tfr.Id);
                p.getParameters().put('showSaveMsg', 'True');
                return p;
            } else {
                return null;
            }
        } catch (tmException tmEx) {
            showSaved = false;
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
            tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.saveTfr',tmEx.errorString,objectIdForLog);
            return null;            
        } catch (Exception ex) {
            showSaved = false;
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,tmConstants.ERROR_SAVING_TRIAL_FEATURE_REQUEST));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,ex.getMessage()));
            tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.saveTfr',ex.getMessage(),objectIdForLog);

            return null;
        }           
    }

    private void updateUpgradeInfoToTFR() {
        if (upgradeToEditionName != null) {
            tfrDomain.requestType = tmConstants.REQUEST_TYPE_UPGRADE ;
            tfrDomain.tfrDecorator.tfr.Edition__c = upgradeToEditionName;
        }
    }
    /*
    *   Save and Submits will create the TFR and submit the record for approval.
    */
    public PageReference saveAndSubmitTfr() {
        showSaved = true;
        try {
            updateUpgradeInfoToTFR();
            tfrDomain.selectedProducts = orgProducts;
            tfrDomain.saveAndSubmitForApproval();
            return new PageReference('/' + tfrDomain.tfrDecorator.tfr.Id);
        } catch (tmException tmEx) {
            showSaved = false;
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
            tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.saveAndSubmitTfr',tmEx.errorString,objectIdForLog);
            return null;            
        } catch (Exception ex) {
            showSaved = false;
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,tmConstants.ERROR_SUBMITTING_FOR_PROVISIONING ));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,ex.getMessage()));
            tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.saveAndSubmitTfr',ex.getMessage(),objectIdForLog);
            return null;
        }   
    }

    /*
    *   When the user clicks Cancel on the page they should be taken to the Account if the TFR was not
    *       created. If it has an ID then take the user to the TFR for their review.
    */
    public PageReference cancel () {
        try {       
            if (tfrDomain.tfrDecorator.tfr.Id != null) {
                return new PageReference('/' + tfrDomain.tfrDecorator.tfr.Id);
            } else {
                return new PageReference('/' + tfrAccountId);
            }
        } catch (tmException tmEx) {
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
             tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.cancel',tmEx.errorString,objectIdForLog);
            return null;            
        } catch (Exception ex) {
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.cancel',ex.getMessage(),objectIdForLog);
            return null;
        }               
    }

    /*
    *
    */
    public PageReference addTemplate() {
        if (tfrDomain.tfrDecorator.canEdit && showTFRTemplates) {
            for (tmDomainTrialFeatureRequest.tmTrialTemplate t: templateCatalog) {
                if (t.templateId == templateToAdd && t.templateProducts.size() > 0) {
                    for (tmTrialManagerTemplateProduct__c p: t.templateProducts) {
                        Integer addQty = 1;
                        if (p.Quantity__c > 1) {
                            addQty = Integer.valueOf(p.Quantity__c);
                        }
                        productToAdd = p.Product__c;
                        addProductQuantity(addQty);
                    }
                }
            }
        }
        return null;
    }

    /*
    *   Adding a product will move a product from the productCatalog
    *       to the provisioning view with specified quantity.
    */
    public PageReference addProduct() { return addProductQuantity(1); }

    public PageReference addProductQuantity(Integer qty) {
        if (tfrDomain.tfrDecorator.canEdit) {
            for (Integer i = 0; i < productCatalog.size(); i++) {
                tmDomainTrialFeatureRequest.tmTrialProduct tp = productCatalog[i];
                if (tp.ProductId == productToAdd){
                    tp.additionalQuantity = qty;
                    tp.provisionedQuantity = 0;
                    productCatalog.remove(i);
                    orgProducts.add(tp);
                    break;
                }
            }
        }
        return null;
    }

    /*
    *   Removing the product will take the item from the provisioning view to the product
    *       productCatalog.
    */
    public PageReference removeProduct() {
        if (tfrDomain.tfrDecorator.canEdit) {
            for (Integer i = 0; i < orgProducts.size(); i++) {
                tmDomainTrialFeatureRequest.tmTrialProduct tp = orgProducts[i];
                if (tp.ProductId == productToRemove){
                    orgProducts.remove(i);
                    productCatalog.add(tp);
                    break;
                }
            }
        }
        return null;
    }

    /*
    *   Requeries and renders the product productCatalog based on the country picklist
    */
    public PageReference resetTFR() {
        try {           
            //delete tfr items
            tfrDomain.deleteTFRItems();

            //Refresh Product productCatalog
            refreshProductCatalog();
        } catch (tmException tmEx) {
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
         tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.resetTFR',tmEx.errorString,objectIdForLog);  
        } catch (Exception ex) {
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.resetTFR',ex.getMessage(),objectIdForLog);
    }
        return null;
    }

    public PageReference cancelUpgrade() {
        try {
            tfrDomain = null;
            tfrDomain.deleteTFRItems();
            refreshProductCatalog();
            tfrDomain.tfrDecorator.tfr.Edition__c = tfrDomain.tenantDomain.tenantForceDotComEdition;
            tfrDomain.edition = null;
            displayUpgradeToEditionSection = false;
            upgradeToEditionName = null;
            tfrDomain.requestType = null;
            tfrDomain.selectedProducts = null;
            tfrDomain.provisionedProducts = null;
        } catch (tmException tmEx) {
            for (String s: tmEx.errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
            }
            tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.cancelUpgrade',tmEx.errorString,objectIdForLog);  
        } catch (Exception ex) {
            showForm = false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            tmOrgLog.log(BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.cancelUpgrade',ex.getMessage(),objectIdForLog);
        }
        return null;
    }

    private void refreshProductCatalog() {
        productCatalog = null;
        orgProducts = null;
    }

    /*
    *   Getters and Setters associated with the custom VF Page
    */
    public tmDomainTrialFeatureRequest tfrDomain {
        get {
            if (tfrDomain == null) {
                tfrDomain = new tmDomainTrialFeatureRequest(tfrAccountId, tfrId);                                    
            }
            return tfrDomain;
        }
        private set;
    }

    public List<tmDomainTrialFeatureRequest.tmTrialProduct> productCatalog {
        get {
            if (productCatalog == null) {
                try {
                    productCatalog = tfrDomain.productCatalog;
                    //  Iterate thru selected/provisioned and remove from productCatalog
                    for (tmDomainTrialFeatureRequest.tmTrialProduct pProd: orgProducts) {
                        for (Integer i=0;i<productCatalog.size();i++) {
                            if (productCatalog[i].ProductId == pProd.ProductId) productCatalog.remove(i);
                        }
                    }
                } catch (tmException tmEx) {
                    for (String s: tmEx.errors) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
                    }
                    tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.productCatalog',tmEx.errorString ,objectIdForLog);    
                } catch (Exception ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
                     tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.productCatalog',ex.getMessage(),objectIdForLog);
                    showForm = false;
                }  
            }
            return productCatalog;
        }
        private set;
    }

    public List<tmDomainTrialFeatureRequest.tmTrialTemplate> templateCatalog {
        get {
            if (templateCatalog == null && tmConstants.CAN_USE_TEMPLATES) {
                try {
                    templateCatalog = tfrDomain.templateCatalog;
                    //System.debug('in catalog: ' + templateCatalog.size());
                } catch (tmException tmEx) {
                    for (String s: tmEx.errors) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
                    }
                    tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.templateCatalog',tmEx.errorString ,objectIdForLog);    
                } catch (Exception ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
                     tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.templateCatalog',ex.getMessage(),objectIdForLog);
                    showForm = false;
                }  
            }
            return templateCatalog;
        }
        private set;
    }

    public List<tmDomainTrialFeatureRequest.tmTrialProduct> orgProducts {
        get {
            if (orgProducts == null) {
                try {               
                    orgProducts = new List<tmDomainTrialFeatureRequest.tmTrialProduct>();
                    // first add all products that are already provisioned
                    for (tmDomainTrialFeatureRequest.tmTrialProduct tpProv : tfrDomain.provisionedProducts) {
                        orgProducts.add(tpProv);
                    }
                    // then add any products that may already have been selected for this specific TFR
                    for (tmDomainTrialFeatureRequest.tmTrialProduct tpSel : tfrDomain.selectedProducts) {
                        if (tpSel.provisionedQuantity == null) tpSel.provisionedQuantity = 0;
                        Boolean found = false;
                        for (tmDomainTrialFeatureRequest.tmTrialProduct tpProv : tfrDomain.provisionedProducts) {
                            if (tpSel.productId == tpProv.productId) {
                                tpProv.additionalQuantity = tpSel.additionalQuantity;
                                found = true;
                            }
                        }
                        if (!found) {
                            orgProducts.add(tpSel);
                        }
                    }
                } catch (tmException tmEx) {
                    for (String s: tmEx.errors) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,s));
                    }
                     tmOrgLog.log( BaseOrgLog.level.INFO,'tmControllerTrialFeatureRequest.orgProducts',tmEx.errorString,objectIdForLog);    
                } catch (Exception ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
                    tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerTrialFeatureRequest.orgProducts',ex.getMessage(),objectIdForLog);
                    showForm = false;
                } 
            }
            return orgProducts;
        }
        private set;
    }
    public void getProductInfoOnEditionChange() {        
        refreshProductCatalog(); 
        displayUpgradeToEditionSection = true;
        tfrDomain.requestType = tmConstants.REQUEST_TYPE_UPGRADE;
        tfrDomain.edition = upgradeToEditionName;
        tfrDomain.selectedProducts = new List<tmDomainTrialFeatureRequest.tmTrialProduct>();
        tfrDomain.provisionedProducts = new List<tmDomainTrialFeatureRequest.tmTrialProduct>();
    }     
    public void showUpgradeToEditionsList() {        
        displayUpgradeToEditionSection = true;   
    }
  
    public boolean displayUpgradeToEditionSection {get; set;}  
    
    public String upgradeToEditionName {get; set;}  
      
    public List<SelectOption> editionsOptions {
        get {
            if (editionsOptions == null) {
                editionsOptions = new List<SelectOption>();
                for (Integer i : tmConstants.EDITION_ORDER_MAP.keySet()) {
                   if (!tmConstants.NON_UPGRADE_EDITION_LIST.contains(tmConstants.EDITION_ORDER_MAP.get(i)) && i > currentEditionsOrder)
                      editionsOptions.add(new SelectOption(tmConstants.EDITION_ORDER_MAP.get(i), tmConstants.EDITION_ORDER_MAP.get(i)));
                }
            }
            return editionsOptions;
        }
        private set;
    }
    
    public boolean hasShowUpgradeLink {
       get { 
            return !editionsOptions.isEmpty() ;
        }
        private set;
    }
   
    public Integer currentEditionsOrder {
        get {
            if (currentEditionsOrder == null) {
                for(Integer i : tmConstants.EDITION_ORDER_MAP.keySet()) {
                   if(tfrDomain.tenantDomain.tenantForceDotComEdition == tmConstants.EDITION_ORDER_MAP.get(i)) {
                        currentEditionsOrder = i;
                        break;
                    }
                }
            }
            return currentEditionsOrder;
        }
        private set;
    }

     public String loadingImageUrl {
        get {
            return BaseUtil.getResourceUrl('loading');
        }
    }

    public Boolean showTFRTemplates {
        get {
            return (tmConstants.CAN_USE_TEMPLATES && tmConstants.TEMPLATES_ENABLED);
        }
    }
}