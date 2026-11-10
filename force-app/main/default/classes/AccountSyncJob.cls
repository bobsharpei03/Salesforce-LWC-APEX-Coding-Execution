//
public with sharing class AccountSyncJob implements Queueable, Database.AllowsCallouts {

    private List<Id> remainingIds;

    public AccountSyncJob(List<Id> remainingIds) {
        this.remainingIds = remainingIds;
    }

    public void execute(QueueableContext ctx) {
        Integer size = AccountSyncService.chunkSize();
        List<Id> chunk = new List<Id>();
        List<Id> rest  = new List<Id>();
        for (Integer i = 0; i < remainingIds.size(); i++) {
            if (i < size) chunk.add(remainingIds[i]); else rest.add(remainingIds[i]);
        }

        AccountSyncService.syncChunk(chunk);

        if (!rest.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new AccountSyncJob(rest));
        }
    }
}
/*
*
* The most serious bug is recursion: the future method updates the Account, which re-fires the
* trigger and tries to call a future from a future, so the sync crashes every time. It also isn’t
* bulk-safe, with one future call per record, so a data load over 50 records fails. On the
* integration side, the API key is hardcoded and should be in a Named Credential, the JSON is
* hand-built and breaks on special characters, and there’s no status check or error handling,
* so failures either vanish or write bad data. I’d rewrite it as a single Queueable job with
* change detection, JSON.serialize, response checks, and failure logging.
*
// [3] No sharing declaration
public class AccountSyncService {
    @future(callout=true)
    public static void syncToErp(Id accountId) {
        // [4] Single-record design: no bulk version taking a Set<Id>
        Account a = [SELECT Id, Name, BillingCity, Erp_Id__c FROM Account WHERE Id = :accountId];

        HttpRequest req = new HttpRequest();
        // [5] Hardcoded endpoint and API key in source code and in the URL
        req.setEndpoint('https://erp.example.com/api/accounts?key=abc123SECRET');
        req.setMethod('POST');
        // [6] Hand-built JSON: breaks on quotes in the name; null city becomes the string "null"
        // [7] No Content-Type header and no timeout set
        req.setBody('{"name":"' + a.Name + '","city":"' + a.BillingCity + '"}');

        // [8] No try/catch: a timeout or connection error fails the job silently
        HttpResponse res = new Http().send(req);

        // [9] No status code check: an error page or "500 Internal Server Error" gets saved as the ERP Id
        // [10] Raw body stored, not parsed: if the ERP returns JSON, the whole JSON lands in the field
        a.Erp_Id__c = res.getBody();

        // [11] This update re-fires the trigger, which calls a future from inside a future: exception
}
*/