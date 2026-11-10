//
@RestResource(urlMapping='/v1/customers/*')
global with sharing class CustomerApi {

    private static final Integer MAX_RECORDS = 200;

    // Input: only the fields a caller is allowed to set
    public class CustomerInput {
        public String name;
        public String industry;
    }

    // Output: a stable contract, decoupled from the Account schema
    public class CustomerDto {
        public Id id;
        public String name;
        public String industry;

        CustomerDto(Account a) {
            id = a.Id;
            name = a.Name;
            industry = a.Industry;
        }
    }

    public class CreateResult {
        public Integer row;
        public Boolean success;
        public Id id;
        public String error;
    }

    @HttpGet
    global static void getCustomers() {
        RestResponse res = RestContext.response;
        try {
            String industry = RestContext.request.params.get('industry');

            // Bind variables, not concatenation; user mode enforces the integration user's access
            Map<String, Object> binds = new Map<String, Object>{
                'industry'   => industry,
                'maxRecords' => MAX_RECORDS
            };
            String soql = 'SELECT Id, Name, Industry FROM Account'
                + (String.isBlank(industry) ? '' : ' WHERE Industry = :industry')
                + ' ORDER BY Name LIMIT :maxRecords';

            List<CustomerDto> customers = new List<CustomerDto>();
            for (Account a : Database.queryWithBinds(soql, binds, AccessLevel.USER_MODE)) {
                customers.add(new CustomerDto(a));
            }
            sendJson(res, 200, customers);
        } catch (Exception e) {
            handleUnexpected(res, 'getCustomers', e);
        }
    }

    @HttpPost
    global static void createCustomers() {
        RestResponse res = RestContext.response;
        try {
            RestRequest req = RestContext.request;
            if (req.requestBody == null || String.isBlank(req.requestBody.toString())) {
                sendError(res, 400, 'Request body is required.');
                return;
            }

            List<CustomerInput> inputs;
            try {
                inputs = (List<CustomerInput>) JSON.deserialize(
                    req.requestBody.toString(), List<CustomerInput>.class);
            } catch (JSONException e) {
                sendError(res, 400, 'Request body must be a JSON array of customers.');
                return;
            }
            if (inputs == null || inputs.isEmpty() || inputs.size() > MAX_RECORDS) {
                sendError(res, 400, 'Send between 1 and ' + MAX_RECORDS + ' customers.');
                return;
            }

            // Map only the allowed fields: the caller can't set OwnerId or anything else
            List<Account> accounts = new List<Account>();
            for (CustomerInput c : inputs) {
                accounts.add(new Account(Name = c.name?.trim(), Industry = c.industry));
            }

            // One DML, partial success, user mode
            List<Database.SaveResult> saveResults =
                Database.insert(accounts, false, AccessLevel.USER_MODE);

            List<CreateResult> results = new List<CreateResult>();
            for (Integer i = 0; i < saveResults.size(); i++) {
                CreateResult r = new CreateResult();
                r.row = i + 1;
                r.success = saveResults[i].isSuccess();
                if (r.success) {
                    r.id = saveResults[i].getId();
                } else {
                    r.error = saveResults[i].getErrors()[0].getMessage();
                }
                results.add(r);
            }
            sendJson(res, 200, results);   // per-row results tell the caller exactly what succeeded
        } catch (Exception e) {
            handleUnexpected(res, 'createCustomers', e);
        }
    }

    @HttpDelete
    global static void deleteCustomer() {
        RestResponse res = RestContext.response;
        try {
            String idParam = RestContext.request.requestURI.substringAfterLast('/');

            Id accountId;
            try {
                accountId = Id.valueOf(idParam);
            } catch (StringException e) {
                sendError(res, 400, 'Invalid customer id.');
                return;
            }
            if (accountId.getSObjectType() != Account.SObjectType) {
                sendError(res, 400, 'Id is not a customer id.');
                return;
            }

            List<Account> accts = [SELECT Id FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
            if (accts.isEmpty()) {
                sendError(res, 404, 'Customer not found.');
                return;
            }

            Database.DeleteResult dr = Database.delete(accts[0], false, AccessLevel.USER_MODE);
            if (dr.isSuccess()) {
                res.statusCode = 204;   // deleted, no body
            } else {
                sendError(res, 409, dr.getErrors()[0].getMessage());
            }
        } catch (Exception e) {
            handleUnexpected(res, 'deleteCustomer', e);
        }
    }

    // ---- Helpers ----

    private static void sendJson(RestResponse res, Integer status, Object body) {
        res.statusCode = status;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(body));
    }

    private static void sendError(RestResponse res, Integer status, String message) {
        sendJson(res, status, new Map<String, String>{ 'error' => message });
    }

    // Log full details internally; give the caller only a generic message
    private static void handleUnexpected(RestResponse res, String operation, Exception e) {
        ErrorLogger.logAll('CustomerApi.' + operation,
            new List<String>{ e.getMessage() + '\n' + e.getStackTraceString() });
        sendError(res, 500, 'An unexpected error occurred.');
    }
}

/*
@RestResource(urlMapping='/customers/*')
global without sharing class CustomerApi {

    @HttpGet
    global static List<Account> getCustomers() {
        RestRequest req = RestContext.request;
        String industry = req.params.get('industry');

        String query = 'SELECT Id, Name, Industry, AnnualRevenue, Tax_Id__c, ' +
                       'Bank_Account_Number__c FROM Account';
        if (industry != null) {
            query += ' WHERE Industry = \'' + industry + '\'';
        }
        return Database.query(query);
    }

    @HttpPost
    global static String createCustomers() {
        RestRequest req = RestContext.request;
        System.debug('Incoming payload: ' + req.requestBody.toString());

        try {
            List<Account> accounts = (List<Account>) JSON.deserialize(
                req.requestBody.toString(), List<Account>.class);

            for (Account acc : accounts) {
                insert acc;
            }
            return 'Created ' + accounts.size() + ' accounts';
        } catch (Exception e) {
            return e.getMessage() + '\n' + e.getStackTraceString();
        }
    }

    @HttpDelete
    global static void deleteCustomer() {
        String accountId = RestContext.request.requestURI.substringAfterLast('/');
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId];
        delete acc;
    }
}
    */

/*
* Mass assignment on POST. This is the headline miss. The JSON is deserialized straight
* into Account, so the caller can set any field: OwnerId, RecordTypeId, internal flags,
* even sensitive fields. Deserialize into an input wrapper class with only the allowed
* fields, then map them to the Account yourself.
* DML inside a loop. insert acc runs once per record, so a payload of 151 Accounts hits
* the DML limit. And because it’s all-or-nothing, a failure partway through rolls back
* everything already inserted, while the caller gets a 200.
* Logging the full payload. System.debug writes the request body, including any personal
* data, into debug logs that admins can read and that are retained. Don’t log sensitive
* payloads.
* Leaking internals. Returning e.getStackTraceString() exposes class names, line numbers,
* and field names to an outside party, which helps an attacker map your org. Return a
* generic message and log the details internally.
* No input validation on POST. An empty body, invalid JSON, or 50,000 records all go
* straight to processing. Validate size and shape, and return 400 for bad input.
* No LIMIT or pagination on GET. With 3 million Accounts, the query hits the 50,000-row
* limit, heap limits, or the response size limit. Cap the page size and support paging.
* Returning raw sObjects. The API’s response format is tied directly to your Account
* schema. Rename a field and the external system breaks. Return response wrapper classes
* so the API contract is stable.
* No API version in the URL. /customers/* gives you no way to change the API later
* without breaking consumers. Use /v1/customers/*.
* Dangerous DELETE. Deleting an Account can cascade to its Contacts, Opportunities, and
* Cases. An external system probably shouldn’t hard-delete customers at all. Consider a
* soft delete (marking the record inactive), or at least restrict which callers may delete.
* No user-mode enforcement on DML. Inserts and deletes should also respect the integration
* user’s permissions.
*/