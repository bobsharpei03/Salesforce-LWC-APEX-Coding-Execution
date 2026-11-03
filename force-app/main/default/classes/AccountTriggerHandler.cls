public class AccountTriggerHandler {

    public static void handleAfterInsert(List<Account> newAccounts) {
        createOpportunityIfNeeded(newAccounts);
    }

    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Account> changedAccounts = new List<Account>();

        for (Account newAcc : newAccounts) {

            Account oldAcc = oldMap.get(newAcc.Id);

            if (newAcc.Rating != oldAcc.Rating) {
                changedAccounts.add(newAcc);
            }
        }

        createOpportunityIfNeeded(changedAccounts);
    }


    private static void createOpportunityIfNeeded(List<Account> accountsToProcess) {

        if (accountsToProcess.isEmpty()) {
            return;
        }

        Map<Id, Account> acctsWithOpps = new Map<Id, Account>([
                SELECT Id, Name,
                    (SELECT Id FROM Opportunities)
                FROM Account
                WHERE Id IN :accountsToProcess
                WITH USER_MODE
            ]);

        List<Opportunity> oppList = new List<Opportunity>();

        for (Account acc : accountsToProcess) {

            Account accountWithOpps = acctsWithOpps.get(acc.Id);

            if (accountWithOpps.Opportunities.isEmpty()) {

                oppList.add(
                    new Opportunity(
                        Name =
                            acc.Name +
                            ' Auto Trigger Opportunity',
                        StageName = 'Prospecting',
                        CloseDate =
                            System.today().addMonths(1),
                        AccountId = acc.Id
                    )
                );
            }
        }

        if (!oppList.isEmpty()) {
            insert as user oppList;
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
}
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
}