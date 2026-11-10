/*
Requirement: An LWC uploads a list of new customers. Each customer is an Account
with one primary Contact. The method must allow partial success: if some customers
fail, the others should still be saved, and the user should see which ones failed
and why.

The accountRows and contactRows lists are the key technique. Database.insert returns
its SaveResult list in the same order as the records you passed in, so tracking which
original row each record came from lets you match every result back to the right customer.
That index matching is what makes partial success reportable.
Step 5 implements one policy, deleting half-created Accounts, so each customer either
fully succeeds or fully fails. The alternative is to keep the Account and report the
partial result. Either is defensible; the bug in the original was having no policy at all.

First, the code doesn’t meet the requirement: a plain insert is all-or-nothing, so one
bad row blocks every customer. Second, the Contacts are linked using acc.Id before the
Accounts are inserted, so every Contact is saved with no Account, and nothing errors.
I’d insert Accounts with Database.insert(list, false), link Contacts using the Ids from
the successful SaveResults, then insert Contacts the same way. I’d return a result per row
so the user sees exactly what failed, and decide with the business what happens to an
Account whose Contact fails. Then the smaller items: typed input instead of a Map, a
dynamic RecordType lookup, sharing and user mode, and input validation.
*/
public with sharing class CustomerOnboardingService {

    private static final Id CUSTOMER_RT_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

    @AuraEnabled
    public static List<CustomerResult> createCustomers(List<CustomerInput> customers) {
        //
        List<CustomerResult> results = new List<CustomerResult>();
        if (customers == null || customers.isEmpty()) {
            return results;
        }
        // 1. Validate input; build Accounts only for valid rows
        List<Account> accounts = new List<Account>();
        List<Integer> accountRows = new List<Integer>();   // accounts[i] belongs to customers[accountRows[i]]

        for (Integer i = 0; i < customers.size(); i++) {
            CustomerInput c = customers[i];
            CustomerResult r = new CustomerResult(i + 1);
            results.add(r);

            if (String.isBlank(c.companyName) || String.isBlank(c.lastName)) {
                r.errorMessage = 'Company name and last name are required.';
                continue;
            }
            accounts.add(new Account(Name = c.companyName.trim(), RecordTypeId = CUSTOMER_RT_ID));
            accountRows.add(i);
        }
        // 2. Insert Accounts with partial success, enforcing the user's permissions
        List<Database.SaveResult> accResults = Database.insert(accounts, false, AccessLevel.USER_MODE);

        // 3. Build Contacts only for Accounts that saved, linked with the real Account Id
        List<Contact> contacts = new List<Contact>();
        List<Integer> contactRows = new List<Integer>();

        for (Integer i = 0; i < accResults.size(); i++) {
            Integer row = accountRows[i];
            if (accResults[i].isSuccess()) {
                CustomerInput c = customers[row];
                results[row].accountId = accResults[i].getId();
                contacts.add(new Contact(
                    FirstName = c.firstName,
                    LastName  = c.lastName,
                    Email     = c.email,
                    AccountId = accResults[i].getId()
                ));
                contactRows.add(row);
            } else {
                results[row].errorMessage = accResults[i].getErrors()[0].getMessage();
            }
        }

        // 4. Insert Contacts with partial success
        List<Database.SaveResult> conResults = Database.insert(contacts, false, AccessLevel.USER_MODE);
        List<Account> halfCreated = new List<Account>();

        for (Integer i = 0; i < conResults.size(); i++) {
            CustomerResult r = results[contactRows[i]];
            if (conResults[i].isSuccess()) {
                r.contactId = conResults[i].getId();
                r.success = true;
            } else {
                r.errorMessage = conResults[i].getErrors()[0].getMessage();
                halfCreated.add(new Account(Id = r.accountId));
                r.accountId = null;
            }
        }

        // 5. Remove Accounts whose Contact failed, so no half-created customers remain
        if (!halfCreated.isEmpty()) {
            Database.delete(halfCreated, false);
        }

        // 6. Log all failures for admins in one call (no DML inside a loop)
        List<String> failures = new List<String>();
        for (CustomerResult r : results) {
            if (!r.success) {
                failures.add('Row ' + r.rowNumber + ': ' + r.errorMessage);
            }
        }
        if (!failures.isEmpty()) {
            ErrorLogger.logAll('CustomerOnboardingService', failures);
        }

        return results;
    }

       // Typed input instead of Map<String, String>
    public class CustomerInput {
        @AuraEnabled public String companyName { get; set; }
        @AuraEnabled public String firstName   { get; set; }
        @AuraEnabled public String lastName    { get; set; }
        @AuraEnabled public String email       { get; set; }
    }

    // One result per customer, so the LWC can show exactly which rows failed
    public class CustomerResult {
        @AuraEnabled public Integer rowNumber;
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String errorMessage;

        CustomerResult(Integer rowNumber) {
            this.rowNumber = rowNumber;
        }
    }
}


/*
public class CustomerOnboardingService {

    @AuraEnabled
    public static String createCustomers(List<Map<String, String>> customers) {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        for (Map<String, String> cust : customers) {
            Account acc = new Account();
            acc.Name = cust.get('companyName');
            acc.RecordTypeId = '0125g000000ABCDEF';
            accounts.add(acc);

            Contact con = new Contact();
            con.FirstName = cust.get('firstName');
            con.LastName = cust.get('lastName');
            con.Email = cust.get('email');
            con.AccountId = acc.Id;
            contacts.add(con);
        }

        try {
            insert accounts;
            insert contacts;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }

        return 'Success';
    }
}
*/