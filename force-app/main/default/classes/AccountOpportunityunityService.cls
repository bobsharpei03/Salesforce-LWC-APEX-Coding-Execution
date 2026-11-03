public class AccountOpportunityService {

    public static void processAccounts(Map<Id, Account> accountMap) {

        Set<Id> accountIds = accountMap.keySet();

        List<Opportunity> opportunities = [SELECT Id, Name, AccountId, StageName
                                           FROM Opportunity WHERE AccountId IN :accountIds
                                           WITH USER_MODE];

                                           /*
        OR
        List<Opportunity> opportunities = [SELECT Id, Name, AccountId
                                            FROM Opportunity WHERE AccountId IN :accountMap.keySet()
                                            WITH USER_MODE];
                                           */

        for (Opportunity opp : opportunities) {
            System.debug('Opportunity: ' + opp.Name + ', Account: ' + opp.AccountId);
        }
    }
}