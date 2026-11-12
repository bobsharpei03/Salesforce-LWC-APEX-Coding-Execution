// Intentionally without sharing: the rollup must stay accurate even when
// the running user can't edit the Account.
public with sharing class OpportunityTaskCreatorOption1 {
    // Trigger side: uses oldMap to find Opportunities that JUST became won
    public static void onAfterSave(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> newlyWonIds = new Set<Id>();

        for (Opportunity opp : newOpps) {
            Boolean wasWon = oldMap != null && oldMap.get(opp.Id).IsWon;
            if (opp.IsWon && !wasWon && opp.AccountId != null) {
                newlyWonIds.add(opp.Id);
            }
        }
        if (!newlyWonIds.isEmpty()) {
            processNewlyWon(newlyWonIds);
        }
    }

    // Work side: takes Ids and queries what it needs
    private static void processNewlyWon(Set<Id> opportunityIds) {
        Set<Id> accountIds = new Set<Id>();
        List<Task> tasks = new List<Task>();

        for (Opportunity opp : [SELECT Id, AccountId, OwnerId
                                FROM Opportunity
                                WHERE Id IN :opportunityIds]) {
            accountIds.add(opp.AccountId);
            tasks.add(new Task(
                Subject = 'Send thank-you note',
                WhatId  = opp.Id,
                OwnerId = opp.OwnerId
            ));
        }
        recalculateTotalWon(accountIds);
        insert tasks;
    }

    // Recalculate from the source instead of adding to a running total
    private static void recalculateTotalWon(Set<Id> accountIds) {
        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (Id accId : accountIds) {
            totals.put(accId, 0);
        }

        for (AggregateResult ar : [SELECT AccountId accId, SUM(Amount) total
                                   FROM Opportunity
                                   WHERE AccountId IN :accountIds AND IsWon = true
                                   GROUP BY AccountId]) {
            Decimal total = (Decimal) ar.get('total');
            totals.put((Id) ar.get('accId'), total ?? 0);
        }

        List<Account> toUpdate = new List<Account>();
        for (Id accId : totals.keySet()) {
            toUpdate.add(new Account(Id = accId, Total_Won__c = totals.get(accId)));
        }
        update toUpdate;
    }

}