// Intentionally without sharing: an org-wide cleanup job must see every Contact,
// regardless of who schedules it.
public without sharing class DeactivateStaleContactsBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    // Database.Stateful keeps these values across chunks
    private Integer deactivatedCount = 0;
    private Integer errorCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoff = Date.today().addDays(-365);
        // Filter in the query: only active Contacts that are stale or never had activity
        return Database.getQueryLocator([
            SELECT Id, AccountId
            FROM Contact
            WHERE Inactive__c = false
              AND (LastActivityDate < :cutoff OR LastActivityDate = null)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        for (Contact c : scope) {
            c.Inactive__c = true;
        }

        // Partial success: good records save, failures are logged individually
        List<Database.SaveResult> results = Database.update(scope, false);

        Set<Id> affectedAccountIds = new Set<Id>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                deactivatedCount++;
                if (scope[i].AccountId != null) {
                    affectedAccountIds.add(scope[i].AccountId);
                }
            } else {
                errorCount++;
                ErrorLogger.log(scope[i].Id, results[i].getErrors()[0].getMessage());
            }
        }

        if (!affectedAccountIds.isEmpty()) {
            recalculateActiveContactCounts(affectedAccountIds);
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems,
                                   CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ job.CreatedBy.Email });
        mail.setSubject('Deactivate Stale Contacts: ' + job.Status);
        mail.setPlainTextBody(
            'Contacts deactivated: ' + deactivatedCount + '\n' +
            'Records that failed to update: ' + errorCount + '\n' +
            'Chunks processed: ' + job.JobItemsProcessed + ' of ' + job.TotalJobItems + '\n' +
            'Chunks that failed entirely: ' + job.NumberOfErrors
        );
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    // Recalculate instead of decrementing, so the count corrects itself
    private void recalculateActiveContactCounts(Set<Id> accountIds) {
        //
        Map<Id, Integer> countByAccount = new Map<Id, Integer>();
        for (Id accId : accountIds) {
            countByAccount.put(accId, 0);   // Accounts with no active Contacts left get 0
        }

        for (AggregateResult ar : [SELECT AccountId accId, COUNT(Id) total
                                   FROM Contact
                                   WHERE AccountId IN :accountIds AND Inactive__c = false
                                   GROUP BY AccountId]) {
            countByAccount.put((Id) ar.get('accId'), (Integer) ar.get('total'));
        }

        List<Account> accts = new List<Account>();
        for (Id accId : countByAccount.keySet()) {
            accts.add(new Account(Id = accId, Contact_Count__c = countByAccount.get(accId)));
        }
        update accts;   // one DML per chunk
    }
}
/*global class DeactivateStaleContactsBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        //
        return Database.getQueryLocator(
            'SELECT Id, LastActivityDate, Inactive__c, AccountId FROM Contact');
    }

    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        for (Contact c : scope) {
            if (c.LastActivityDate < Date.today().addDays(-365)) {
                c.Inactive__c = true;
            }
            Account acc = [SELECT Id, Contact_Count__c FROM Account WHERE Id = :c.AccountId];
            acc.Contact_Count__c = acc.Contact_Count__c - 1;
            update acc;
        }
        update scope;
    }

    global void finish(Database.BatchableContext bc) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'admin@company.com' });
        mail.setSubject('Batch done');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}*/