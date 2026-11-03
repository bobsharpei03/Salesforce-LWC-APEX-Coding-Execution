/*
* [1] No change detection: every edit, even a typo fix, triggers a callout
* [2] One future call per record: fails at 51 records ("Too many future calls: 51")
*/
public with sharing class AccountSyncService {
    //
    public static void handleAfterSave(List<Account> newAccts, Map<Id, Account> oldMap) {
        Set<Id> toSync = new Set<Id>();
        for (Account a : newAccts) {
            Account old = (oldMap == null) ? null : oldMap.get(a.Id);
            // New Account, or a synced field changed. An update to only Erp_Id__c is skipped,
            // which also stops the job's own update from re-triggering the sync.
            if (old == null || a.Name != old.Name || a.BillingCity != old.BillingCity) {
                toSync.add(a.Id);
            }
        }
        if (!toSync.isEmpty()) {
            System.enqueueJob(new AccountSyncJob(toSync));   // one job for the whole batch
        }
    }
}