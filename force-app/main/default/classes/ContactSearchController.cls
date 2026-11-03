public without sharing class ContactSearchController {

        @AuraEnabled(cacheable=true)
        public static List<Contact> searchContacts(String searchTerm, Id accountId) {
            // Reject blank or very short searches instead of returning every Contact
            if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
                return new List<Contact>();
            }
            // Build the pattern in a variable and bind it: no string concatenation into the query
            String likeTerm = '%' + searchTerm.trim() + '%';

            try {
                if (accountId != null) {
                     return [SELECT Id, Name, Email, Phone
                             FROM Contact
                             WHERE Name LIKE :likeTerm
                             AND AccountId = :accountId
                             AND Email != null
                             WITH USER_MODE
                             ORDER BY Name
                             LIMIT 50];
                }
//
                return [SELECT Id, Name, Email, Phone
                        FROM Contact
                        WHERE Name LIKE :likeTerm
                        AND Email != null
                        WITH USER_MODE
                        ORDER BY Name
                        LIMIT 50];

            } catch (QueryException e) {
                // Thrown if the user lacks access to Contact or a queried field
                throw new AuraHandledException('Unable to search contacts. Please contact your administrator.');
            }
        }
/*
    @AuraEnabled
    public static List<Contact> searchContacts(String searchTerm, String accountId) {
        //
        try {
            String query = 'SELECT Id, Name, Email, Phone, SSN__c FROM Contact ' +
                           'WHERE Name LIKE \'%' + searchTerm + '%\'';

            if (accountId != null) {
                query += ' AND AccountId = \'' + accountId + '\'';
            }

            List<Contact> results = Database.query(query);

            List<Contact> filtered = new List<Contact>();

            for (Contact c : results) {
                if (c.Email != null) {
                    filtered.add(c);
                }
            }
            //
            return filtered;

        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
    }
}*/
}