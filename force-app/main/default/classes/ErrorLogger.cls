public without sharing class ErrorLogger {

    public static void logAll(String source, List<String> messages) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        for (String msg : messages) {
            logs.add(new Error_Log__c(
                Source__c  = source,
                Message__c = msg
            ));
        }
        Database.insert(logs, false);   // one DML; a logging failure shouldn't break the caller
    }
}