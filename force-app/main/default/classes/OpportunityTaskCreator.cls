public with sharing class OpportunityTaskCreator {

    private static void processNewlyWon(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        /*
        * [Governor Limits]
        * the loop only collects totals in the map, the code bulkifies to one query and one update,
        * and multiple Opportunities on the same Account are combined into one record instead of
        * causing a duplicate-Id error
        */
        Map<Id, Decimal> amountByAccount = new Map<Id, Decimal>();
        List<Task> tasks = new List<Task>();

        for (Opportunity opp : newOpps) {
            /*
            * [No change detection]
            * If this is an update, use the current record’s Id to get its old version from oldMap,
            * and set wasWon to whatever IsWon was before the save.
            */
            Boolean wasWon = oldMap != null && oldMap.get(opp.Id).IsWon;            
            // [Avoids Runtime Error NullPointerException] && [Data Integrity]
            // Adding a null to a number in Apex throws a NullPointerException that would fail the whole save. 
            // so aif null we make it a 0.
            Decimal amt = opp.Amount == null ? 0 : opp.Amount;
            // [Avoids Runtime Error NullPointerException] && [No change detection] at the same time
            if (!opp.IsWon || wasWon || opp.AccountId == null) { 
            // prevents double-counting the amount because record isWon or wasWon at any point
            // it also prevents creating Task duplicates because change detection and skips records 
            // unless the Opportunity just became Won and has an Account. 
            continue; // take me to the top of the loop and start again with the next record
            }
            /*
             * [Avoids Runtime Error NullPointerException] && [Governor Limits]
             * Get the running total already collected for this Account in the current
             * batch. Several won Opportunities in the same batch can belong to the same
             * Account, so their Amounts are accumulated in a map (AccountId -> total)
             * instead of updating the Account once per Opportunity. If the Account is not
             * in the map yet, this is its first won Opportunity, so start from 0; calling
             * get() on a missing key returns null, and adding to null would throw a
             * NullPointerException
             */
            Decimal soFar = amountByAccount.containsKey(opp.AccountId) ? amountByAccount.get(opp.AccountId) : 0;
            // Now it is safe to put the <id, Decimal> in thee Map
            amountByAccount.put(opp.AccountId, soFar + amt);

            tasks.add(new Task(
                Subject = 'Send thank-you note',
                WhatId  = opp.Id,
                OwnerId = opp.OwnerId
            ));
        }

        if (amountByAccount.isEmpty()) return;
        // [Governor Limits] The limit is 100 SOQL queries per synchronous transaction, and this code uses 1 
        // regardless of batch size
        List<Account> accts = [SELECT Id, Total_Won__c FROM Account WHERE Id IN :amountByAccount.keySet()];
        
        for (Account a : accts) {
             // [Avoids Runtime Error NullPointerException]
            Decimal existing = a.Total_Won__c == null ? 0 : a.Total_Won__c;
            a.Total_Won__c = existing + amountByAccount.get(a.Id);
        }
        update accts;
        insert tasks;
    }
        /*
// [3] No sharing keyword declared (with / without / inherited sharing)
public class OpportunityTriggerHandler {
    public static void handle(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            // [4] Magic string; breaks if the stage is renamed. Use opp.IsWon
            // [5] No change detection: re-runs on every edit of an already-won Opp
            if (opp.StageName == 'Closed Won') {

                // [6] SOQL inside the loop (100-query limit)
                // [7] Assigning to a single Account throws QueryException if AccountId is null
                Account acc = [SELECT Id, Name, Total_Won__c FROM Account WHERE Id = :opp.AccountId];

                // [8] NullPointerException if Total_Won__c or Amount is null
                // [9] Fragile rollup: incrementing ignores deletes, Amount changes, reopens
                acc.Total_Won__c = acc.Total_Won__c + opp.Amount;

                // [10] DML inside the loop (150-DML limit); can also trigger recursion via Account automation
                update acc;

                Task t = new Task();
                t.Subject = 'Send thank-you to ' + acc.Name;
                // [11] In before insert, opp.Id is still null, so the Task has no WhatId
                t.WhatId = opp.Id;
                // [12] Hardcoded Id; differs between sandbox and production
                t.OwnerId = '0055g00000ABCDE';

                // [13] DML inside the loop again; with [5], creates a duplicate Task on every edit
                insert t;
            }
        }
    }
}
*/
}