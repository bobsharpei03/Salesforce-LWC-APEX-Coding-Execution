public class AccountTriggerHandler {
    public static void handleBeforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {

        // Convert newList into a Map<Id, Account>
        Map<Id, Account> newMap = new Map<Id, Account>(newList);

        for (Id accId : newMap.keySet()) {
            Account newAcc = newMap.get(accId);
            Account oldAcc = oldMap.get(accId);

            if (newAcc.Rating != oldAcc.Rating) {
                // do something
            }
        }
    }
/*
 public static void handleBeforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {

        for (Id accId : oldMap.keySet()) {
            Account newAcc = newListMap().get(accId);
            Account oldAcc = oldMap.get(accId);

            if (newAcc.Rating != oldAcc.Rating) {
                // do something
            }
        }
    }

    private static Map<Id, Account> newListMap(List<Account> newList) {
        return new Map<Id, Account>(newList);
    }*/
}