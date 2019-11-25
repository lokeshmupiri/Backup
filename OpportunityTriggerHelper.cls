/*****************************************************
 * Class            :   OpportunityTriggerHelper
 * References       :   OpportunityTriggerHandler
 * Description      :   This is the helper class for OpportunityTriggerHandler
 *                      All the OpportunityTrigger logic should be written here and then call it from OpportunityTriggerHandler
 * Change Log       :
 *      [Lokesh - Fluido]        [26th Sep, 2019]        [Initial Development]
 *****************************************************/
 public with sharing class OpportunityTriggerHelper {

    //can be reused
    public static final Id b2cApplicantRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
    public static Set<Id> contactsProcessed = new Set<Id>();
    
    /*
     * Helper method for OpportunityHandler
     * 1. If there are no related Opportunities with the Record Type = Applicant Opportunity, the checkbox “Prospect__c” on the related contact shall be checked.
     * 2. If there are related Opportunities with the Record Type = Applicant Opportunity that are not Closed, the checkbox “Applicant__c” on the related contact shall be checked.
     */
    public static void updateCustomerCategoryOnContact(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        List<Opportunity> oppListToProcess = new List<Opportunity>();

        //to store the opportunity related contact id
        Set<Id> contactIdSet = new Set<Id>();

        //to update the contacts
        List<Contact> contactsToUpdate =  new List<Contact>();

        //for after insert and after update events
        if(newOppList != null) {
            oppListToProcess = newOppList;
        } else if(oldOppList != null ) { //for after delete events
            oppListToProcess = oldOppList;
        }

        for(Opportunity opp : oppListToProcess) {
            //if contact exist on opportunity
            if(opp.Contact_custom__c != null) {
                contactIdSet.add(opp.Contact_custom__c);

                //this will be exected on update and delete events
                if(oldOppMap != null && oldOppMap.get(opp.Id) != null){
                    //If contact is changed, then add the contactid
                    if(oldOppMap.get(opp.Id).Contact_custom__c != opp.Contact_custom__c) {
                        contactIdSet.add(oldOppMap.get(opp.Id).Contact_custom__c);
                    }
                }
            }
        } 

        //get the contacts to update the Prospect__c and Applicant__c fields
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id,Prospect__c, Applicant__c, Enrolled_Applicant__c, (SELECT ID, IsClosed FROM Opportunities1__r WHERE RecordtypeId =: b2cApplicantRecTypeId) FROM Contact WHERE Id IN: contactIdSet]);
        
        for(Contact con : contactMap.values()) {
            //check if already exist in the update list 
            //this will avoid recursion of updating same record
            if(!contactsProcessed.contains(con.Id)){

                //to track contact needs to be update or not
                Boolean updateContact = false;

                //if there are any opportunities exist
                if(con.Opportunities1__r.size() > 0) {
                    boolean openOppFound = false;
                    //get the all the related opportunities for current contact
                    for(Opportunity opp : con.Opportunities1__r){
                        //if opportunity is not closed
                        if(!opp.isClosed ){
                            openOppFound = true;
                        }
                    }

                    //if contact has any open opportunity
                    if(openOppFound) {
                        if(!con.Applicant__c) {
                            con.Applicant__c =  true;
                            updateContact = true;
                        }
                    } else {
                        //if there is no open opportunity then set applicant__c field on contact to false
                        con.Applicant__c = false;
                        updateContact = true;
                    }

                    if(con.Prospect__c) {
                        con.Prospect__c = false;
                        updateContact = true;
                    }
                } else { // if there is no application opportunities 
                    if(!con.Prospect__c){
                        con.Prospect__c = true;
                        updateContact = true;
                    }
                    if(con.Applicant__c){
                        con.Applicant__c = false;
                        updateContact = true;
                    }
                }

                if(updateContact){
                    contactsToUpdate.add(con);
                }
            }
        }

        if(contactsToUpdate.size() > 0) {
            System.debug('ContactsToUpdate size:'+contactsToUpdate.size());
            update contactsToUpdate;
        }
    }

    /* This method will create the interest record for every new opportunity */
    public static void createInterestForNewOpportunity(List<Opportunity> newOppList) {
        Map<String, String> levelOfStudy = new Map<String, String>();

        for(Schema.PicklistEntry f : Opportunity.Level_of_Study__c.getDescribe().getPicklistValues()) {
            levelOfStudy.put(f.getValue() ,f.getLabel());
        }

        List<Interest__c> newInterest = new List<Interest__c>();
        for(Opportunity opp : newOppList) {
            //if Level_of_Study__c is filled, then create opportunity interest
            if(!String.isBlank(opp.Level_of_Study__c)) {
                String leveOfStudyLabel = levelOfStudy.get(opp.level_of_Study__c);
                newInterest.add(prepareNewInterest('Level', leveOfStudyLabel , opp.Contact_Custom__c));
            }
            //if campus__c is filled, then create interest of each campaus interested
            if(!String.isBlank(opp.Campus__c)) {
                for(String  curCampus : opp.Campus__c.split(';')) {
                    System.debug('level of curCampus'+ curCampus);
                    newInterest.add(prepareNewInterest('Campus', curCampus, opp.Contact_Custom__c));
                }
            }
        }
        if(newInterest.size() > 0) {
            insert newInterest;
        }
    }

    /* helper method for createInterestForNewOpportunity, prepare the new interest record to insert*/
    public static Interest__c prepareNewInterest(String category, String curInterest, Id conId) {
        Interest__c interest = new Interest__c();
        interest.Interest__c = curInterest;
        interest.Source_System__c = 'Salesforce';
        interest.Contact__c = conId;
        interest.Category__c = category;
        return interest;
    }
}
