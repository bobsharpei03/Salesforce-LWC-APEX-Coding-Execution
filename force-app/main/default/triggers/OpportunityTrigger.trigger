trigger OpportunityTrigger on Opportunity (after insert, after update) {

    if (Trigger.isInsert) OpportunityTriggerHandler.afterInsert(Trigger.new);

    if (Trigger.isUpdate) OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);

}
/*
// [1] Fires in all 4 contexts with no context check, so the handler runs twice per save
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    // [2] Passes only Trigger.new; no oldMap, so there's no way to detect what changed
    OpportunityTriggerHandler.handle(Trigger.new);
}
    */