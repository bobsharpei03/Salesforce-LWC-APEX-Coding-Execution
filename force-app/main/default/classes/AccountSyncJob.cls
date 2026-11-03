/*
* IntegrationLogger stands in for a logging utility, typically one that writes to a custom
* log object so failures can be reported and retried. The point is that failures are
* recorded somewhere, not swallowed. One limit to mention if asked about scale: a transaction
* allows 100 callouts, so a 200-record batch would exceed it. For large volumes, you’d split
* the Ids across chained Queueable jobs, use Batch Apex with a small scope, or ask whether the
* ERP supports a bulk endpoint that accepts many Accounts in one request.
*/
public with sharing class AccountSyncJob implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public AccountSyncJob(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext ctx) {
        //
        List<Account> toUpdate = new List<Account>();

        for (Account a : [SELECT Id, Name, BillingCity, Erp_Id__c FROM Account
                          WHERE Id IN :accountIds]) {

            Boolean isNew = String.isBlank(a.Erp_Id__c);
            HttpRequest req = buildRequest(a, isNew);

            try {
                HttpResponse res = new Http().send(req);
                Integer status = res.getStatusCode();

                if (status >= 200 && status < 300) {
                    // Only a create returns a new ERP Id to store
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
            update toUpdate;   // one DML after all callouts
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