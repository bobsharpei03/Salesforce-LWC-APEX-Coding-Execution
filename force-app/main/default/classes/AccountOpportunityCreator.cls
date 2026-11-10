public with sharing class AccountOpportunityCreator {
    // Entry point: decides which Accounts qualify
    public static void onAfterSave(List<Account> newAccounts, Map<Id, Account> oldMap) {
        //List<Account> toProcess = new List<Account>();
        Set<Id> toProcess = new Set<Id>();

        for (Account acc : newAccounts) {
            // Get this Account's previous version.
            // On insert, oldMap is null, so ?. returns null instead of throwing an error.
            Account old = oldMap?.get(acc.Id);
            // New Account, or Rating changed
            if (old == null || acc.Rating != old.Rating) {
                toProcess.add(acc);
            }
        }
        createIfNeeded(toProcess);
    }

    private static void createIfNeeded(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }
        List<Opportunity> oppList = new List<Opportunity>();

        for (Account acc : [SELECT Id, Name, (SELECT Id FROM Opportunities LIMIT 1)
                            FROM Account
                            WHERE Id IN :accountIds
                            WITH USER_MODE]) {
            if (acc.Opportunities.isEmpty()) {
                oppList.add(new Opportunity(
                    Name      = acc.Name + ' Auto Trigger Opportunity',
                    StageName = 'Prospecting',
                    CloseDate = System.today().addMonths(1),
                    AccountId = acc.Id
                ));
            }
        }
        if (!oppList.isEmpty()) {
            insert as user oppList;
        }
    }
    /*
    //
    public static void markAsReviewed(Set<Id> accountIds) {
    List<Account> toUpdate = new List<Account>();
    for (Id accId : accountIds) {
        toUpdate.add(new Account(Id = accId, Reviewed__c = true));
    }
    update toUpdate;
}
    */
/*
    private static void createIfNeeded(List<Account> accountsToProcess) {
        if (accountsToProcess.isEmpty()) {
            return;
        }

        Map<Id, Account> acctsWithOpps = new Map<Id, Account>([
            SELECT Id, Name, (SELECT Id FROM Opportunities)
            FROM Account
            WHERE Id IN :accountsToProcess
            WITH USER_MODE
        ]);

        List<Opportunity> oppList = new List<Opportunity>();
        for (Account acc : accountsToProcess) {
            Account accountWithOpps = acctsWithOpps.get(acc.Id);

            if (accountWithOpps != null && accountWithOpps.Opportunities.isEmpty()) {
                oppList.add(new Opportunity(
                    Name      = acc.Name + ' Auto Trigger Opportunity',
                    StageName = 'Prospecting',
                    CloseDate = System.today().addMonths(1),
                    AccountId = acc.Id
                ));
            }
        }

        if (!oppList.isEmpty()) {
            insert as user oppList;
        }
    }
        */
}