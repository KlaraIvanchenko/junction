public with sharing class AccountExtension {

    private ApexPages.StandardController ctrl;
    private final Account account;
    private static Integer rLimit = 500;    
    public Boolean isEdit { get; set;}
    public Set<String> selectedContacts { get; set;}
    public String editedContacts { get; set;}
    public List<AccountContact__c> additionalContacts {
        get {
            return [SELECT Account__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Category__c  FROM AccountContact__c WHERE Account__c =: account.Id];
        }
        set; }

    public AccountExtension(ApexPages.StandardController stdController) {
        ctrl = stdController;
        this.account = (Account)stdController.getRecord();
        selectedContacts = setRelatedContacts();
        isEdit = false;
    }

    private Set<String> setRelatedContacts() {
        Set<String> options = new Set<String>();
        for (AccountContact__c cnt : additionalContacts) {
            options.add(cnt.Contact__c);
        }
        
        return options;
    }

    @RemoteAction
    public static String searchContacts(String pInvName) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName
            FROM Contact
            WHERE (LastName LIKE: pInvName + '%') OR (FirstName LIKE: pInvName + '%')
            LIMIT: rLimit
        ];

        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Contact cnt : contacts) {
        	Map<String, String> option = new Map<String, String>();
            option.put('id', cnt.Id);
            option.put('text', cnt.LastName + ' ' + cnt.FirstName);
            options.add(option);
        }

        return JSON.serialize(options);
    }

    public PageReference editCnts() {
        isEdit = true;
        return null;
    }

    public PageReference cancelEdit() {
        isEdit = false;
        return null;
    }

    public PageReference saveCnt() {
        Set<String> oldContactIds = setRelatedContacts();
        String errorMessage = '';
        
        if (editedContacts.equals('null')) {
            List<AccountContact__c> contactsToDelete = [
                SELECT Id
                FROM AccountContact__c
                WHERE Contact__c IN: oldContactIds
            ];

            try {
                delete contactsToDelete;
            } catch (System.DMLException ex) {
                errorMessage = ex.getMessage();
                System.debug('ERROR' + errorMessage);
                return null;
            }
        } else {
            Set<String> newContactIds = (Set<String>) JSON.deserialize(editedContacts, Set<String>.class);
            if (newContactIds.equals(oldContactIds)) {
                isEdit = false;
                return null;
            } else {
                List<String> listContactIdsToDelete = new List<String>();
                List<AccountContact__c> listContactsToInsert = new List<AccountContact__c>();

                for (String cntId : oldContactIds) {
                    if (!newContactIds.contains(cntId)) {
                        listContactIdsToDelete.add(cntId);
                    }
                }

                for (String cntId : newContactIds) {
                    if (!oldContactIds.contains(cntId)) {
                        listContactsToInsert.add(new AccountContact__c(Account__c = account.Id, Contact__c = cntId));
                    }
                }

                if (!listContactIdsToDelete.isEmpty()) {
                    List<AccountContact__c> contactsToDelete = [
                        SELECT Id
                        FROM AccountContact__c
                        WHERE Contact__c IN: listContactIdsToDelete AND Account__c =: account.Id
                    ];

                    try {
                        delete contactsToDelete;
                    } catch (System.DMLException ex) {
                        errorMessage = ex.getMessage();
                        System.debug('ERROR' + errorMessage);
                        return null;
                    }
                }

                try {
                    insert listContactsToInsert;
                } catch (System.DMLException ex) {
                    errorMessage = ex.getMessage();
                    System.debug('ERROR' +  errorMessage);
                    return null;
                }           
            }            
        }
        selectedContacts = setRelatedContacts();
        isEdit = false;
        return null;
    }

    public List<SelectOption> getAllContacts() {
        List<SelectOption> options = new List<SelectOption>();

        for (Contact cnt : [SELECT FirstName, LastName FROM Contact WHERE Id IN: selectedContacts ORDER BY LastName ASC LIMIT: rLimit]) {
            options.add(new SelectOption(cnt.Id, cnt.FirstName + ' ' + cnt.LastName));
        }

        if (options.size() < 100) {
            
            List<Contact> contactList = [SELECT FirstName, LastName FROM Contact WHERE Id NOT IN: selectedContacts ORDER BY LastName ASC LIMIT: rLimit];
            for (Integer i = 0; i < contactList.size() && options.size() < rLimit; i++) {
                options.add(new SelectOption( contactList.get(i).Id,  contactList.get(i).FirstName + ' ' + contactList.get(i).LastName));
            }
        }

        return options;
    }

    @RemoteAction
    public static String getContacts() {
    	List<Map<String, String>> options = new List<Map<String, String>>();
        for (Contact cnt : [SELECT LastName, FirstName FROM Contact ORDER BY LastName ASC LIMIT: rLimit]) {
            Map<String, String> option = new Map<String, String>();
            option.put('id', cnt.Id);
            option.put('text', cnt.LastName + ' ' + cnt.FirstName);
            options.add(option);
        }      
        return JSON.serialize(options);
    }

}