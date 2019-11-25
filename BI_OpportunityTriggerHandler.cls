/*******************************************************
* Class         : OpportunityTriggerHandler
* Description   : This is the handler method for Opportunity trigger.
                  OpportunityTriggerHelper.cls is the helper class for this class
* Methods       : afterInsert() -> to handle the after inser logic
*                 afterUpdate() -> to handle the after inser logic 
*                 afterDelete() -> to handle the after delete logic
*
*******************************************************/
public with sharing class OpportunityTriggerHandler {

    public static void afterInsert(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap) {
        System.debug('## After Insert ##');
        /*
         * When ever opportunity is created, set the “Prospect__c” and “Applicant__c” checkbox on the related contact based on below conditions
         * 1. If there are no related Opportunities with the Record Type = Applicant Opportunity, the checkbox “Prospect__c” on the related contact shall be checked.
         * 2. If there are related Opportunities with the Record Type = Applicant Opportunity that are not Closed, the checkbox “Applicant__c” on the related contact shall be checked.
         */
        OpportunityTriggerHelper.updateCustomerCategoryOnContact(newOppList, newOppMap , null, null);
        /* 
         * whenever opportujnity is created, create insert records based on level_of_study__c and campus__c
         */
        OpportunityTriggerHelper.createInterestForNewOpportunity(newOppList);
        /*
         *Whenever opportunity is created, if any of the academic interest is checked then create a interest record for the related contact on opportunity
         
        OpportunityTriggerHelper.createIntrestForContacts(newOppMap, null);
        */
    }

    public static void afterUpdate(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap) {
        System.debug('## After Update ##');
        /*
         * When ever opportunity is updated, set the “Prospect__c” and “Applicant__c” checkbox on the related contact based on below conditions
         * 1. If there are no related Opportunities with the Record Type = Applicant Opportunity, the checkbox “Prospect__c” on the related contact shall be checked.
         * 2. If there are related Opportunities with the Record Type = Applicant Opportunity that are not Closed, the checkbox “Applicant__c” on the related contact shall be checked.
         */
        OpportunityTriggerHelper.updateCustomerCategoryOnContact(newOppList, newOppMap, oldOppList, oldOppMap);
        
        /*
         *Whenever opportunity is created, if any of the academic interest is checked then create a interest record for the related contact on opportunity
        
        OpportunityTriggerHelper.createIntrestForContacts(newOppMap, oldOppMap);
         */
    }

    public static void afterDelete(List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap) {
        /*
         * When ever opportunity is deleted,set the “Prospect__c” and “Applicant__c” checkbox on the related contact based on below conditions
         * 1. If there are no related Opportunities with the Record Type = Applicant Opportunity, the checkbox “Prospect__c” on the related contact shall be checked.
         * 2. If there are related Opportunities with the Record Type = Applicant Opportunity that are not Closed, the checkbox “Applicant__c” on the related contact shall be checked.
         */
        OpportunityTriggerHelper.updateCustomerCategoryOnContact(null, null, oldOppList, oldOppMap);
    }
}
