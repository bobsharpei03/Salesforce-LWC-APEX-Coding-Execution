/*
* IntegrationLogger stands in for a logging utility, typically one that writes to a custom
* log object so failures can be reported and retried. The point is that failures are
* recorded somewhere, not swallowed. One limit to mention if asked about scale: a transaction
* allows 100 callouts, so a 200-record batch would exceed it. For large volumes, you’d split
* the Ids across chained Queueable jobs, use Batch Apex with a small scope, or ask whether the
* ERP supports a bulk endpoint that accepts many Accounts in one request.
*/
public with sharing class AccountSyncService {

    private static final Integer CHUNK_SIZE = 50;
    private static Set<Id> queuedForSync = new Set<Id>();   // recursion guard

    public static Integer chunkSize() {
        return CHUNK_SIZE;
    }

    // Entry point for every caller: trigger handler, LWC button, batch job
    public static void requestSync(Set<Id> accountIds) {
        Set<Id> toQueue = new Set<Id>(accountIds);
        toQueue.removeAll(queuedForSync);
        if (toQueue.isEmpty()) return;

        queuedForSync.addAll(toQueue);
        System.enqueueJob(new AccountSyncJob(new List<Id>(toQueue)));
    }

    // The actual integration work for one chunk (callouts first, then DML)
    public static void syncChunk(List<Id> accountIds) {
        List<Account> toUpdate = new List<Account>();

        for (Account a : [SELECT Id, Name, BillingCity, Erp_Id__c
                          FROM Account WHERE Id IN :accountIds]) {
            Boolean isNew = String.isBlank(a.Erp_Id__c);
            try {
                HttpResponse res = new Http().send(buildRequest(a, isNew));
                Integer status = res.getStatusCode();
                if (status >= 200 && status < 300) {
                    if (isNew) {
                        Map<String, Object> body =
                            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        toUpdate.add(new Account(Id = a.Id, Erp_Id__c = (String) body.get('id')));
                    }
                } else {
                    IntegrationLogger.logFailure(a.Id, status, res.getBody());
                }
            } catch (CalloutException e) {
                IntegrationLogger.logFailure(a.Id, null, e.getMessage());
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

     private HttpRequest buildRequest(Account a, Boolean isNew) {
        //
        HttpRequest req = new HttpRequest();
        if (isNew) { // Named Credential holds URL + auth
            req.setMethod('POST');                                       // create in ERP
            req.setEndpoint('callout:ERP/api/accounts');
        } else {
            req.setMethod('PATCH');                                      // update existing ERP record
            req.setEndpoint('callout:ERP/api/accounts/' + EncodingUtil.urlEncode(a.Erp_Id__c, 'UTF-8'));
        }
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(20000);
        req.setBody(JSON.serialize(new Map<String, Object>{
            'name' => a.Name,
            'city' => a.BillingCity
        }));
        return req;
    }
}


/*
* [1] No change detection: every edit, even a typo fix, triggers a callout
* [2] One future call per record: fails at 51 records ("Too many future calls: 51")
*/

/*
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
}*/