public with sharing class tmDaoTemplate {
	public static List<tmTrialManagerTemplate__c> templatesWithProducts {
		get {
			if (templatesWithProducts == null) {
				templatesWithProducts = new List<tmTrialManagerTemplate__c>();
				try {
					for (tmTrialManagerTemplate__c tmt: [SELECT Id,
																Name, 
																Description__c, 
																(SELECT	EligibleForTrial__c,
																		Id,
																		Product__c, 
																		Product__r.Name,
																		Quantity__c, 
																		Product__r.CRM_Edition__c 
																	FROM TFR_Template_Products__r) 
																FROM tmTrialManagerTemplate__c 
																WHERE Status__c = 'Active']) {
						if (tmt.TFR_Template_Products__r.size() > 0)
							templatesWithProducts.add(tmt);
					}
				} catch (Exception ex) {
					// exception here
				}
			}
			return templatesWithProducts;
		}
		private set;
	}
}