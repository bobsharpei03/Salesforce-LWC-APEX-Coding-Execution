@isTest
private class OpportunityTriggerHandlerTest {

    @testSetup
    static void setup() {
        insert new Account(Name = 'Test Account');
    }

    @isTest
    static void newlyWonOpportunity_updatesTotalAndCreatesTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(Name = 'Won Opp', StageName = 'Closed Won',
            CloseDate = Date.today(), AccountId = acc.Id, Amount = 100);

        Test.startTest();
        insert opp;
        Test.stopTest();

        acc = [SELECT Total_Won__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(100, acc.Total_Won__c, 'Total should equal the won Amount');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id],
            'One thank-you Task should be created');
    }

    @isTest
    static void editingWonOpportunity_doesNotDoubleCount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity();
        opp.Name = 'Won Opp';
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        opp.Amount = 100;
        
        insert opp;

        Test.startTest();
        opp.Name = 'Renamed';
        update opp;
        Test.stopTest();

        acc = [SELECT Total_Won__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(100, acc.Total_Won__c, 'Editing a won Opportunity must not re-add its Amount');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id],
            'Editing must not create a duplicate Task');
    }

    @isTest
    static void bulkInsert_200WonOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(Name = 'Bulk ' + i, StageName = 'Closed Won',
                CloseDate = Date.today(), AccountId = acc.Id, Amount = 10));
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        acc = [SELECT Total_Won__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(2000, acc.Total_Won__c, 'All 200 Amounts should be summed');
        Assert.areEqual(200, [SELECT COUNT() FROM Task], 'One Task per Opportunity');
    }

    @isTest
    static void openOpportunity_doesNotChangeTotal() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        insert new Opportunity(Name = 'Open Opp', StageName = 'Prospecting',
            CloseDate = Date.today(), AccountId = acc.Id, Amount = 100);
        Test.stopTest();

        acc = [SELECT Total_Won__c FROM Account WHERE Id = :acc.Id];
        Assert.isNull(acc.Total_Won__c, 'An open Opportunity should not affect the total');
        Assert.areEqual(0, [SELECT COUNT() FROM Task], 'No Task for an open Opportunity');
    }

    @isTest
    static void wonOpportunityWithoutAccount_doesNotThrow() {
        Test.startTest();
        insert new Opportunity(Name = 'No Account', StageName = 'Closed Won',
            CloseDate = Date.today(), Amount = 100);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Task], 'No Task without an Account');
    }
}
/*
// [1] SeeAllData=true: the test depends on whatever data exists in the org
@isTest(SeeAllData=true)
private class OpportunityTriggerHandlerTest {

    // [2] One method tests everything; vague name says nothing about the scenario
    @isTest
    static void testHandle() {

        // [3] Queries real org data; throws QueryException in an org with no Accounts
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // [4] Only one record: no bulk test of 200
        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Amount = 100
        );

        // [5] No Test.startTest() / Test.stopTest() around the code under test
        insert opp;

        // [6] Edits an already-won Opportunity (the double-counting scenario) but never checks the result
        opp.Amount = 200;
        update opp;

        // [7] Always passes: no assertion on the Account total
        // [8] No assertion that the Task was created
        System.assert(true);
    }

    // [9] No negative tests: open Opportunity, missing Account, already-won edit
    // [10] No System.runAs test for a user with limited permissions
    // This test was written for code coverage, not verification. It depends
    // on org data, can never fail, and only tests one record, so it hides the exact bugs it should catch
}
*/