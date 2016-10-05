trigger tmTrialFeatureRequestTrigger on tmTrialFeatureRequest__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        // check to see if any of the updates are trial requests that have just been approved with this update
        Set<Id> approvedTrialRequests = new Set<Id>();
        for (Id tfrId : Trigger.newMap.keySet()){
            if (Trigger.newMap.get(tfrId).Status__c == tmConstants.TFR_STATUS_APPROVED && Trigger.oldMap.get(tfrId).Status__c != tmConstants.TFR_STATUS_APPROVED){
                approvedTrialRequests.add(tfrId);
            }
        }
        if (approvedTrialRequests.size() > 0){
            for (Id tfrId : approvedTrialRequests) {
                try {
                    tmDomainProvisioning tfrDomain =  new tmDomainProvisioning(tfrId);
                    tfrDomain.submitForProvisioning(); 
                } catch (tmException tmEx) {
                    throw new tmException(tmConstants.ERROR_SUBMITTING_FOR_PROVISIONING +','+ String.join(tmEx.errors,','));            
                } catch (Exception ex) {
                    throw new tmException(tmConstants.ERROR_SUBMITTING_FOR_PROVISIONING +','+ ex.getMessage());
                }
            }
        }
    }
    
    if (Trigger.isBefore) {
        if(Trigger.isDelete) {
            for(tmTrialFeatureRequest__c tfr: Trigger.oldMap.values()) {
                tmDomainTrialFeatureRequest trialFeatureRequestDomain = new tmDomainTrialFeatureRequest(tfr.Account__c, tfr.Id);
                if(!trialFeatureRequestDomain.tfrDecorator.canDelete) {
                    tfr.addError(tmConstants.ERROR_TFR_DELETE_LABEL);
                }
            }
        }
    }
}