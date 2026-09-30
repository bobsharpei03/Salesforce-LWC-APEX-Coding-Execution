public with sharing class WizardController {

    @AuraEnabled
    public static WizardResult submitWizardData(String wizardData) {
        WizardResult result = new WizardResult();

        try {
            // Parse JSON
            Map<String, Object> data =  (Map<String, Object>) JSON.deserializeUntyped(wizardData);

            Map<String, Object> step1 = (Map<String, Object>) data.get('step1');
            Map<String, Object> step2 = (Map<String, Object>) data.get('step2');
            Map<String, Object> step3 = (Map<String, Object>) data.get('step3');

            // Create Account
            Account acc = new Account(
                Name = (String) step1.get('accountName'),
                Industry = (String) step1.get('industry')
            );
            insert acc;

            // Create Contact
            Contact con = new Contact(
                FirstName = (String) step2.get('contactName'),
                Email = (String) step2.get('email'),
                AccountId = acc.Id
            );
            insert con;

            // Create Preferences (Custom Object)
            Wizard_Preference__c pref = new Wizard_Preference__c(
                Preference_Value__c = (String) step3.get('preferences'),
                Contact__c = con.Id
            );
            insert pref;

            result.success = true;
            result.message = 'Wizard completed successfully.';
            result.accountId = acc.Id;
            result.contactId = con.Id;

        } catch (Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }

        return result;
    }

    public class WizardResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
    }
}