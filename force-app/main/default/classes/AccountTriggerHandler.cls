public class AccountTriggerHandler {
    /*
trigger AccountSyncTrigger on Account (after insert, after update) {
    //
    AccountSyncService.handleAfterSave(Trigger.new, Trigger.oldMap);
}*/
    // Lets tests or data loads switch the handler off
    @TestVisible private static Boolean bypassed = false;

    public void beforeInsert(List<Account> newAccts) {
        // Same-record work: defaults, normalization, validation (no DML)
    }

    public void beforeUpdate(List<Account> newAccts, Map<Id, Account> oldMap) {
        // Same-record work on update
    }

    public static void handleAfterInsert(List<Account> newAccounts) {
    if(isBypassed()) {
        return;
    }
        AccountOpportunityCreator.onAfterSave(newAccounts, null);
        AccountErpSyncTrigger.onAfterSave(newAccounts, null);
    }

    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        if(isBypassed()) {
            return;
        }
        AccountOpportunityCreator.onAfterSave(newAccounts, oldMap);
        AccountErpSyncTrigger.onAfterSave(newAccounts, oldMap);
    }

    private static Boolean isBypassed() {
        return bypassed || FeatureManagement.checkPermission('Bypass_Account_Triggers');
    }

    // Decides WHICH Accounts need a sync; the service decides how
    /*private void requestErpSync(List<Account> newAccts, Map<Id, Account> oldMap) {
        if (isBypassed()) {
            return;
        }

        Set<Id> changed = new Set<Id>();
        for (Account a : newAccts) {
            Account old = oldMap?.get(a.Id);
            if (old == null
                || a.Name != old.Name
                || a.BillingCity != old.BillingCity) {
                changed.add(a.Id);
            }
        }

        if (!changed.isEmpty()) {
            AccountSyncService.requestSync(changed);
        }
    }
*/


/*
trigger AccountSyncTrigger on Account (after insert, after update) {
    // [1] No change detection: every edit, even a typo fix, triggers a callout
    for (Account a : Trigger.new) {
        // [2] One future call per record: fails at 51 records ("Too many future calls: 51")
        AccountSyncService.syncToErp(a.Id);
    }
*/
}
    /*
    for (Database.SaveResult result : results) {
        if (result.isSuccess()) {
            System.debug('Opportunity created: ' + result.getId());
        } 
        else {
            for (Database.Error error : result.getErrors()) {
                System.debug(error.getMessage());
            }
        }
    }*/
/*
trigger AddRelatedRecord on Account(after insert, after update) {

    List<Opportunity> oppList = new List<Opportunity>();

    // Get the related opportunities for the accounts in this trigger
    Map<Id,Account> acctsWithOpps = new Map<Id,Account>(
        [SELECT Id,(SELECT Id FROM Opportunities)
         FROM Account
         WHERE Id IN :Trigger.new
         WITH USER_MODE]);

    // Add an opportunity for each account if it doesn't already have one.
    // Iterate through each account.

    for(Account a : Trigger.new) {
        System.debug('acctsWithOpps.get(a.Id).Opportunities.size()=' + acctsWithOpps.get(a.Id).Opportunities.size());
        // Check if the account already has a related opportunity.
        if (acctsWithOpps.get(a.Id).Opportunities.size() == 0) {
            // If it doesn't, add a default opportunity
            oppList.add(new Opportunity(Name=a.Name + ' Opportunity',
                                       StageName='Prospecting',
                                       CloseDate=System.today().addMonths(1),
                                       AccountId=a.Id));
        }
    }
    if (oppList.size() > 0) {
        insert as user oppList;
    }
}
*/