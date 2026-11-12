// Intentionally without sharing: the rollup must stay accurate even when
// the running user can't edit the Account.
public without sharing class OpportunityTriggerHandler {

    public static void afterInsert(List<Opportunity> newOpps) {
        OpportunityTaskCreator.processNewlyWon(newOpps, null);
    }

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        OpportunityTaskCreator.processNewlyWon(newOpps, oldMap);
    }
}