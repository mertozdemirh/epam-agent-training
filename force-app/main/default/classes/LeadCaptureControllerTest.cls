@isTest
private class LeadCaptureControllerTest {

    @TestSetup
    static void setupData() {
        Account testAccount = new Account(Name = 'Test Account Corp');
        insert testAccount;
    }

    @isTest
    static void testCreateLead_success() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Id leadId = LeadCaptureController.createLead(
            'John',
            'Doe',
            'john.doe@example.com',
            '5551234567',
            acc.Name,
            'Web',
            'Test notes',
            acc.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, leadId, 'Lead Id should not be null');

        Lead createdLead = [
            SELECT FirstName, LastName, Email, Phone, Company,
                   LeadSource, Capture_Notes__c, Source_Account__c
            FROM Lead
            WHERE Id = :leadId
        ];

        System.assertEquals('John',                    createdLead.FirstName);
        System.assertEquals('Doe',                     createdLead.LastName);
        System.assertEquals('john.doe@example.com',    createdLead.Email);
        System.assertEquals('5551234567',              createdLead.Phone);
        System.assertEquals(acc.Name,                  createdLead.Company);
        System.assertEquals('Web',                     createdLead.LeadSource);
        System.assertEquals('Test notes',              createdLead.Capture_Notes__c);
        System.assertEquals(acc.Id,                    createdLead.Source_Account__c);
    }

    @isTest
    static void testCreateLead_withoutOptionalFields() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Id leadId = LeadCaptureController.createLead(
            null,
            'Smith',
            'smith@example.com',
            null,
            acc.Name,
            'Partner Referral',
            null,
            acc.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, leadId, 'Lead Id should not be null');

        Lead createdLead = [SELECT LastName, FirstName, Phone, Capture_Notes__c FROM Lead WHERE Id = :leadId];
        System.assertEquals('Smith', createdLead.LastName);
        System.assertEquals(null,    createdLead.FirstName);
        System.assertEquals(null,    createdLead.Phone);
        System.assertEquals(null,    createdLead.Capture_Notes__c);
    }

    @isTest
    static void testCreateLead_sourceAccount() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Id leadId = LeadCaptureController.createLead(
            'Jane',
            'Brown',
            'jane@example.com',
            null,
            acc.Name,
            'Phone Inquiry',
            'Some notes',
            acc.Id
        );
        Test.stopTest();

        Lead createdLead = [SELECT Source_Account__c FROM Lead WHERE Id = :leadId];
        System.assertEquals(acc.Id, createdLead.Source_Account__c, 'Source Account should be linked');
    }

    @isTest
    static void testCreateLead_missingLastName() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LeadCaptureController.createLead(
                'NoLast',
                null,
                'nolast@example.com',
                null,
                acc.Name,
                'Web',
                null,
                acc.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for missing LastName');
    }

    @isTest
    static void testCreateLead_missingEmail() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Id leadId = LeadCaptureController.createLead(
            'No',
            'Email',
            null,
            null,
            acc.Name,
            'Other',
            null,
            acc.Id
        );
        Test.stopTest();

        // Email is not required at the DB level; validation is done on the LWC side
        System.assertNotEquals(null, leadId, 'Lead should be created even without email at DB level');
    }
}
