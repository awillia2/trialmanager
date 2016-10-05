public with sharing class tmControllerDelTrialFeatureRequest {
	public tmTrialFeatureRequest__c tmTFR { get; private set; }
  
  	@TestVisible
  	public tmDomainTrialFeatureRequest tfrDomain { private set;
        get {
            if (tfrDomain == null) {
                tfrDomain = new tmDomainTrialFeatureRequest(tmTFR.Account__c, tmTFR.Id);
            } 
            return tfrDomain;
        }
    }

  	public tmControllerDelTrialFeatureRequest (ApexPages.StandardController controller) {
    	if (!Test.isRunningTest()) controller.addFields(new String[]{'Account__c'});
    	tmTFR = (tmTrialFeatureRequest__c)controller.getRecord();
    	isError = false;
  	}

  	public Boolean isError { get; private set; }

  	public PageReference canDelete() {
  		isError = true;
    	PageReference returnPageRef;
    	try {
      		if(tfrDomain.tfrDecorator.canDelete) {
        		Id tmTFRId = ApexPages.currentPage().getParameters().get('id');
        		tmTrialFeatureRequest__c tmTFRObj = new tmTrialFeatureRequest__c(Id = tmTFRId);
        		delete tmTFRObj;
        		isError = false;
        		Account account = new Account(Id = tmTFR.Account__c);
        		returnPageRef = new ApexPages.StandardController(account).view();
        		returnPageRef.setRedirect(true);
      		} else {
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, tmConstants.ERROR_TFR_DELETE_LABEL));
            tmOrgLog.log(BaseOrgLog.level.WARNING,'tmControllerDelTrialFeatureRequest.canDelete',tmConstants.ERROR_TFR_DELETE_LABEL,(tmTFR != null) ? 
            String.valueOf(tmTFR.id) : String.valueOf(account.id));
      		}
    	} catch (Exception ex) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, tmConstants.ERROR_TFR_DELETE_LABEL));
      		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
          tmOrgLog.log( BaseOrgLog.level.ERROR,'tmControllerDelTrialFeatureRequest.canDelete',ex.getMessage(),(tmTFR != null) ? 
            String.valueOf(tmTFR.id) : String.valueOf(account.id));
    	}
    	return returnPageRef;
  	}

  	public PageReference back() {
    	return new ApexPages.StandardController(tmTFR).view();
  	}
}