public with sharing class tmDaoProduct {

    public static List<Product2> getTrialProductsForEdition(String editionName, Id pricebook2Id) {
        Set<Product2> products = new Set<Product2>();

        List<String> eligibleForTrial = new List<String>{ tmConstants.PRODUCT_ELIGIBLE_FOR_TRIAL_YES };

        tmAllowDemoProductAccess__c pAccess = tmAllowDemoProductAccess__c.getInstance(UserInfo.getProfileId());

        if (pAccess.AllowDemoAccess__c) {
          eligibleForTrial.add(tmConstants.PRODUCT_ELIGIBLE_FOR_TRIAL_DEMO);
        }

        for (PricebookEntry pe : [
                select Product2.Id, Product2.Name, Product2.Description, Product2.Admin_Fulfillment__c,
                       Product2.sfbase__SKU__c, Product2.Edition_Visibility__c, Product2.Fulfillment_Provider__r.Name
                  from PricebookEntry
                 where Product2.IsActive = true
                   and Product2.Edition_Visibility__c includes (:editionName)
                   and Pricebook2Id = :pricebook2Id
                   and Product2.Fulfillment_Provider__r.Name = :tmConstants.CSP_TENANT_TYPE_FORCEDOTCOM
                   and Product2.Eligible_for_Trial__c in :eligibleForTrial]) {
              products.add(pe.Product2);
         }
        return new List<Product2>(products);
    }

    public static Id getPriceBookForCurrency(String currencyIsoCode) {
        if (currencyIsoCode == null) {
            currencyIsoCode = tmConstants.TFR_DEFAULT_CURRENCY;
        }

        String priceBookLikeClause = tmDaoSettings.pricebookClause;

        PriceBook2 priceBook = getPriceBookWithName(priceBookLikeClause + currencyIsoCode);

        //If there is no pricelist for the specified currency, then we'll revert to using the default currency.
        if (priceBook == null) {
            priceBook = getPriceBookWithName(priceBookLikeClause + tmConstants.TFR_DEFAULT_CURRENCY);
        }
        return priceBook.Id;
    }

    @TestVisible
    private static PriceBook2 getPriceBookWithName(String priceBookName) {
      List<Pricebook2> priceBooks = [SELECT Id
                                        FROM Pricebook2
                                        WHERE isActive = true
                                        AND Name LIKE :priceBookName];
        if (priceBooks != null && priceBooks.size() == 1) {
           return priceBooks.get(0);
        }
      return null;
    }

	public static Map<Id,Product2> getProductInfo(set<Id> productIds) {
        Map<Id,Product2> products = new Map<Id,Product2>([SELECT Id, Name, Description, Eligible_for_Trial__c, Admin_Fulfillment__c, sfbase__SKU__c, Edition_Visibility__c
					                    FROM Product2
					                    WHERE Id = :productIds]);
        return products;
    }

	public static List<PriceBookEntry> getCoreProducts(string editionName, Id pricebook2Id) {
        List<PriceBookEntry> coreProducts = [SELECT Id, Product2.Id, Product2.Name, Product2.Description, Product2.Sales_Edition__c, Product2.Service_Edition__c
											FROM PriceBookEntry
										WHERE Product2.IsActive = true
										AND BillingFrequency = 1
										AND Pricebook2Id = :pricebook2Id
										AND Product2.Edition_Visibility__c = :editionName
					                    AND Product2.License_Filter__c = 'User License'
										And Product2.Eligible_for_Trial__c = :tmConstants.PRODUCT_ELIGIBLE_FOR_TRIAL_YES
										And Product2.Admin_Fulfillment__c = :tmConstants.PRODUCT_ADMIN_FULFILLMENT_ADMIN
										AND (Product2.Sales_Edition__c = :editionName
									    OR Product2.Service_Edition__c = :editionName)];
        return coreProducts;
  }

  public static Map<Id,Id> getPriceBookEntriesForProducts(List<Id> productIds, Id priceBook2Id) {
    Map<Id, Id> productPriceBookEntries = new Map<Id, Id>();

    List<PriceBookEntry> pbes =  [SELECT Id, Product2Id
                    FROM PriceBookEntry
                    WHERE Pricebook2Id = :priceBook2Id
                    AND Product2Id IN :productIds
                    AND BillingFrequency = 1];

    for (PriceBookEntry pbe : pbes) {
      productPriceBookEntries.put (pbe.Product2Id, pbe.Id);
    }
    return productPriceBookEntries;
  }

}
