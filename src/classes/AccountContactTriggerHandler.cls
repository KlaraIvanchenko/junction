public without sharing class AccountContactTriggerHandler {

    public static void addCategory(Map<Id, AccountContact__c> newAccContactsMap) {

        List<AccountContact__c> accContactsList = [
        	SELECT Id, Account__c, Account__r.Category__c, Contact__c, Contact__r.Category__c
        	FROM AccountContact__c
        	WHERE Id IN: newAccContactsMap.keySet() AND Contact__r.Category__c != NULL
        ];
        
        Map<Id, Account> accountsMap = addCategories(new Map<Id, Account>(), accContactsList);
        
        update accountsMap.values();
    }

    public static Map<String, List<AccountContact__c>> prepareCategoriesMap(List<AccountContact__c> accountContactsList) {
    	Map<String, List<AccountContact__c>> categoriesMap = new Map<String, List<AccountContact__c>>();
    	for (AccountContact__c accCnt : accountContactsList) {
        	String key = accCnt.Account__c + accCnt.Contact__r.Category__c;
        	if (categoriesMap.containsKey(key)) {
        		categoriesMap.get(key).add(accCnt);
        	} else {
        		categoriesMap.put(key, new List<AccountContact__c> {accCnt});
        	}
        }
        return categoriesMap;
    }

    public static void removeCategory(List<AccountContact__c> deletedAccContacts) {
        Set<Id> accIds = new Set<Id>();
        Set<Id> accCntIds = new Set<Id>();

        for (AccountContact__c accCnt : deletedAccContacts) {
            accIds.add(accCnt.Account__c);
            accCntIds.add(accCnt.Id);
        }

        List<AccountContact__c> deletedAccountContacts = [
        	SELECT Id, Account__c, Account__r.Category__c, Contact__c, Contact__r.Category__c
        	FROM AccountContact__c
        	WHERE Id IN: accCntIds AND Contact__r.Category__c != NULL
        ];

        Map<String, List<AccountContact__c>> removedAccCategories = prepareCategoriesMap(deletedAccountContacts);

        List<AccountContact__c> allAccountContacts = [
        	SELECT Id, Account__c, Account__r.Category__c, Contact__c, Contact__r.Category__c
        	FROM AccountContact__c
        	WHERE Account__c IN: accIds AND Contact__r.Category__c != NULL
        ];
        
        Map<String, List<AccountContact__c>> accCategories = prepareCategoriesMap(allAccountContacts);
        updateAccountCategories(removedAccCategories, accCategories);
       
    }

    public static void updateAccountCategories(Map<String, List<AccountContact__c>> removedAccCategories, Map<String, List<AccountContact__c>> accCategories) {
    	 Map<Id, Account> accountsMap = new Map<Id, Account>();

        for (String key : removedAccCategories.keySet()) {
        	if (accCategories.get(key).size() - removedAccCategories.get(key).size() == 0) {
        		AccountContact__c accCnt = removedAccCategories.get(key).get(0);
    		    String category = accCnt.Contact__r.Category__c;
                Pattern categoryPatt = Pattern.compile('(;' + category + ')|(' + category + ';)|(' + category + ')');
                
        		if (accountsMap.containsKey(accCnt.Account__c)) {
        			String newMultiPckilistValue = categoryPatt.matcher(accountsMap.get(accCnt.Account__c).Category__c).replaceFirst('');
					accountsMap.get(accCnt.Account__c).Category__c = newMultiPckilistValue;
	        	} else {
	        		String newMultiPckilistValue = categoryPatt.matcher(accCnt.Account__r.Category__c).replaceFirst('');
                    accCnt.Account__r.Category__c = newMultiPckilistValue;
        			accountsMap.put(accCnt.Account__c, (Account)accCnt.getSObject('Account__r'));
	        	}
        	}
        }
        update accountsMap.values();
    }

    public static void updateCategory(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {

	    List<AccountContact__c> deletedAccountContacts = [
	    	SELECT Id, Account__c, Account__r.Category__c, Contact__c, Contact__r.Category__c
	    	FROM AccountContact__c
	    	WHERE Contact__c IN: oldContactMap.keySet() AND Contact__r.Category__c != NULL
	    ];

	    Set<Id> accIds = new Set<Id>();
	    for (AccountContact__c accCnt : deletedAccountContacts) {
	        accIds.add(accCnt.Account__c);
	    }

	    Map<String, List<AccountContact__c>> removedAccCategories = new Map<String, List<AccountContact__c>>();

	    for (AccountContact__c accCnt : deletedAccountContacts) {

	    	if (String.isNotBlank(oldContactMap.get(accCnt.Contact__c).Category__c)) {
	    		String key = accCnt.Account__c + oldContactMap.get(accCnt.Contact__c).Category__c;
		    	accCnt.Contact__r.Category__c = oldContactMap.get(accCnt.Contact__c).Category__c;
		    	if (removedAccCategories.containsKey(key)) {
		    		removedAccCategories.get(key).add(accCnt);
		    	} else {
		    		removedAccCategories.put(key, new List<AccountContact__c> {accCnt});
		    	}
	    	}
	    	
	    }

	    List<AccountContact__c> allAccountContacts = [
	    	SELECT Id, Account__c, Account__r.Category__c, Contact__c, Contact__r.Category__c
	    	FROM AccountContact__c
	    	WHERE Account__c IN: accIds AND Contact__r.Category__c != NULL
	    ];
	    
	    Map<String, List<AccountContact__c>> sortedAccCategories = new Map<String, List<AccountContact__c>>();

	    for (AccountContact__c accCnt : allAccountContacts) {
	    	if (String.isNotBlank(oldContactMap.get(accCnt.Contact__c).Category__c)) {
	    	//if (String.isNotBlank(oldContactMap.get(accCnt.Contact__c).get('Category__c'))) {
		    	String key = accCnt.Account__c + oldContactMap.get(accCnt.Contact__c).Category__c;
		    	accCnt.Contact__r.Category__c = oldContactMap.get(accCnt.Contact__c).Category__c;
		    	if (sortedAccCategories.containsKey(key)) {
		    		sortedAccCategories.get(key).add(accCnt);
		    	} else {
		    		sortedAccCategories.put(key, new List<AccountContact__c> {accCnt});
		    	}
		    }
	    }

	    Map<Id, Account> accountsMap = new Map<Id, Account>();
	    accountsMap = removeCategories(removedAccCategories, sortedAccCategories) ;
	    accountsMap = addCategories(accountsMap, deletedAccountContacts);
        update accountsMap.values();
    }

    public static Map<Id, Account> removeCategories(Map<String, List<AccountContact__c>> removedAccCategories,  Map<String, List<AccountContact__c>> sortedAccCategories) {
    	Map<Id, Account> accountsMap = new Map<Id, Account>();

    	for (String key : removedAccCategories.keySet()) {
	    	if (sortedAccCategories.get(key).size() - removedAccCategories.get(key).size() == 0) {
	    		AccountContact__c accCnt = removedAccCategories.get(key).get(0);
	    		String category = accCnt.Contact__r.Category__c;
                Pattern categoryPatt = Pattern.compile('(;' + category + ')|(' + category + ';)|(' + category + ')');               
	    		if (accountsMap.containsKey(accCnt.Account__c)) {
	    			String newMultiPckilistValue = categoryPatt.matcher(accountsMap.get(accCnt.Account__c).Category__c).replaceFirst('');
					accountsMap.get(accCnt.Account__c).Category__c = newMultiPckilistValue;
	        	} else {
	        		String newMultiPckilistValue = categoryPatt.matcher(accCnt.Account__r.Category__c).replaceFirst('');
	                accCnt.Account__r.Category__c = newMultiPckilistValue;
	    			accountsMap.put(accCnt.Account__c, (Account)accCnt.getSObject('Account__r'));
	        	}
	    	}
	    }

	    return accountsMap;
    }

    public static Map<Id, Account> addCategories(Map<Id, Account> accountsMap, List<AccountContact__c> accContactsList) {

    	for (AccountContact__c accCnt : accContactsList) {
        	//if ( String.isNotBlank(accCnt.Contact__r.Category__c)) {
        		if (accountsMap.containsKey(accCnt.Account__c)) {
	        		if (! accountsMap.get(accCnt.Account__c).Category__c.contains(accCnt.Contact__r.Category__c)) {
	        			accountsMap.get(accCnt.Account__c).Category__c += ';' + accCnt.Contact__r.Category__c;
	        		}
	        	} else {
	        		if (String.isNotBlank(accCnt.Account__r.Category__c) && ! accCnt.Account__r.Category__c.contains(accCnt.Contact__r.Category__c)) { 
	        			accCnt.Account__r.Category__c += ';' + accCnt.Contact__r.Category__c;
	        			//accountsMap.put(accCnt.Account__c, (Account)accCnt.getSObject('Account__r'));
	        		} else if (String.isBlank(accCnt.Account__r.Category__c)) {
	        			accCnt.Account__r.Category__c = accCnt.Contact__r.Category__c;
	        			//accountsMap.put(accCnt.Account__c, (Account)accCnt.getSObject('Account__r'));
	        		}
	        		accountsMap.put(accCnt.Account__c, (Account)accCnt.getSObject('Account__r'));
	        	}
        	//}       	
        	
        }

        return accountsMap;
    }
}