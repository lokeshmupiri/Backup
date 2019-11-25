@isTest
public with sharing class OpportunityTriggerHelperTest {
    
    @IsTest
    static void updateCustomerCategoryOnContactTest(){

         //get the 'Academic Program' account record type 
        Id academicAccRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Academic_Program').getRecordTypeId();
        //get the 'Application' opportunity record type
        Id applicantRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Application').getRecordTypeId();
        //create account 
        List<Account> accList = TestDataFactory.createAccounts(1, academicAccRecordType, true);

        //create two contacts
        List<Contact> conList = TestDataFactory.createContactsForAccounts(2, accList, true);
        List<Contact> conListForOpp = new List<Contact>();
        conListForOpp.add(conList[0]);

        //get the opportunites to insert, we should have 6 opps to create 
        List<Opportunity> oppList = TestDataFactory.createOpportunityForContacts(1, conListForOpp, applicantRecTypeId, true);

        
        Test.startTest();

        //get the opp
        Opportunity opp = [SELECT Id, Stagename, Contact_custom__c FROM Opportunity LIMIT 1];

        //get the contact which has a b2cApplicant opportunity 
        Contact con = [SELECT Id, Prospect__c, Applicant__c FROM Contact WHERE Id =:opp.Contact_custom__c LIMIT 1];
        System.assertEquals(false, con.Prospect__c);
        System.assertEquals(true, con.Applicant__c);

        //get the contact which don't have any opportunity 
        Contact con2 = [SELECT Id, Prospect__c, Applicant__c FROM Contact WHERE Id !=:con.Id LIMIT 1];
        System.assertEquals(false, con2.Prospect__c);
        System.assertEquals(false, con2.Applicant__c);

        //change the contact for the opportunity
        opp.Contact_custom__c = con2.Id;
        update opp;

        //now con2 has a b2cApplicant opportunity 
        con2 = [SELECT Id, Prospect__c, Applicant__c FROM Contact WHERE Id =:con2.Id LIMIT 1];
        System.assertEquals(false, con2.Prospect__c);
        System.assertEquals(true, con2.Applicant__c);

        //now con has no related opportunity
        con = [SELECT Id, Prospect__c, Applicant__c FROM Contact WHERE Id =:con.Id LIMIT 1];
        System.assertEquals(true, con.Prospect__c);
        System.assertEquals(false, con.Applicant__c);

        //close the opportunity
        opp.StageName = 'Closed Won';
        update Opp;

        //related contact applcant should ba false, becuase the b2cApplicant is closed
        Contact cont  = [SELECT Id, Prospect__c, Applicant__c FROM Contact WHERE Id =: con2.Id LIMIT 1];
        System.assertEquals(false, cont.Prospect__c);
        System.assertEquals(false, cont.Applicant__c);

        //delete the opportunity
        delete opp;

        //if there no are no B2C_Applicant opportunity found for contact then the prospect__c field on the contact shuld be true
        Contact contact = [SELECT Id, Prospect__c, Applicant__c FROM Contact  WHERE Id =: con2.Id  LIMIT 1];
        System.assertEquals(true, contact.Prospect__c);
        System.assertEquals(false, contact.Applicant__c);

        Test.stopTest();
        
    }

    static testMethod void createInterestForNewOpportunity_Test() {
        
        //get the 'Academic Program' account record type 
        Id academicAccRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Academic_Program').getRecordTypeId();
        //get the 'B2C Prospect' opportunity record type
        Id b2cOppRecordType  = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('B2C_Prospect').getRecordTypeId();
        Id applicantRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Application').getRecordTypeId();
        //create account 
        List<Account> accList = TestDataFactory.createAccounts(1, academicAccRecordType, true);

        //create two contacts
        List<Contact> conList = TestDataFactory.createContactsForAccounts(1, accList, true);

        //get the opportunites to insert, we should have 6 opps to create 
        List<Opportunity> oppList = TestDataFactory.createOpportunityForContacts(2, conList, b2cOppRecordType, false);
        
        oppList[0].RecordTypeId =  applicantRecTypeId;
        oppList[0].Level_of_Study__c = 'PhD';
        oppList[0].Campus__c = 'Bergen;Oslo';

        oppList[1].Level_of_Study__c = 'PhD';
        oppList[1].Campus__c = 'Stavanger;Trondheim;Online studies';

        test.startTest();
        insert oppList;
        test.stopTest();
        
        System.assertEquals(7, [SELECT Count() FROM Interest__c]);
    }
}
