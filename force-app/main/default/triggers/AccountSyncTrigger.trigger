trigger AccountSyncTrigger on Account (after insert, after update) {
    //
    AccountSyncService.handleAfterSave(Trigger.new, Trigger.oldMap);
}
/*
trigger AccountSyncTrigger on Account (after insert, after update) {
    // [1] No change detection: every edit, even a typo fix, triggers a callout
    for (Account a : Trigger.new) {
        // [2] One future call per record: fails at 51 records ("Too many future calls: 51")
        AccountSyncService.syncToErp(a.Id);
    }
*/