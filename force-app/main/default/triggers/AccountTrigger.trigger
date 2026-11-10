trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    /*
trigger AccountSyncTrigger on Account (after insert, after update) {
    // [1] No change detection: every edit, even a typo fix, triggers a callout
    for (Account a : Trigger.new) {
        // [2] One future call per record: fails at 51 records ("Too many future calls: 51")
        AccountSyncService.syncToErp(a.Id);
    }
*/
    switch on Trigger.operationType {
        when BEFORE_INSERT {
         //   AccountTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
          //  AccountTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.handleAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}