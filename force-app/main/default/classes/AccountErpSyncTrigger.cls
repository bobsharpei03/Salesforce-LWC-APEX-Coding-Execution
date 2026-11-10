public with sharing class AccountErpSyncTrigger {
    // Called by AccountTriggerHandler after Accounts are inserted or updated.
    // newAccts: the Accounts being saved (Trigger.new).
    // oldMap:   their previous versions keyed by Id (Trigger.oldMap), or null on insert.
    public static void onAfterSave(List<Account> newAccts, Map<Id, Account> oldMap) {
        // Collects the Ids of Accounts that need to be sent to the ERP.
        // A Set ignores duplicates automatically.
        Set<Id> changedIds = new Set<Id>();
        // Look at each Account being saved, one at a time.
        for (Account a : newAccts) {
            // Get this Account's previous version.
            // On insert, oldMap is null, so ?. returns null instead of throwing an error.
            Account old = oldMap?.get(a.Id);
            // Sync if the Account is new (no previous version),
            // or if a field the ERP cares about has changed.
            if (old == null || a.Name != old.Name || a.BillingCity != old.BillingCity) {
                // Remember this Account's Id for syncing.
                changedIds.add(a.Id);
            }
        }
        // Only call the service if at least one Account qualified,
        // so no work is queued when nothing relevant changed.
        if (!changed.isEmpty()) {
            // Hand the Ids to the sync service, which skips any already queued
            // in this transaction and starts the asynchronous AccountSyncJob.
            AccountSyncService.requestSync(changedIds);
        }
    }
}