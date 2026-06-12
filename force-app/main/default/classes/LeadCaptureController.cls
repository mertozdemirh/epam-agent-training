public with sharing class LeadCaptureController {

    @AuraEnabled
    public static Id createLead(
        String firstName,
        String lastName,
        String email,
        String phone,
        String company,
        String leadSource,
        String notes,
        Id sourceAccountId
    ) {
        try {
            Lead newLead = new Lead(
                FirstName      = firstName,
                LastName       = lastName,
                Email          = email,
                Phone          = phone,
                Company        = company,
                LeadSource     = leadSource,
                Capture_Notes__c   = notes,
                Source_Account__c  = sourceAccountId
            );

            insert newLead;
            return newLead.Id;

        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
