/*
 *  Class       :   CreateOpportunitiesHelper
 *  References  :   CreateOpportunitiesHelperTest, CreateOpportunitiesLWC
 *  Description :   This class is used in CreateOpportunitiesLWC lightning web component    
 *                  To Create opportunities for each campaing memeber for the selected campaing
 */
public with sharing class CreateOpportunitiesHelper {

    //Get the related campaign members where opportunities are not created for the current campaign
    @AuraEnabled
    public static List<CampaignMember> getCampaignMembers(Id campaignId, List<String> statusList){
        System.debug('status'+ statusList);
        return [SELECT Id, ContactId, Contact.AccountId, Contact.LastName 
                FROM CampaignMember
                WHERE CampaignId =: campaignId
                AND Status IN: statusList
                AND Opportunity_Created__c = false];
    }

    //create opportunities
    @AuraEnabled
    public static Boolean createOpportunities(List<Opportunity> oppListToInsert){
        Boolean isSuccess = false;
        System.debug('opps to insert'+ oppListToInsert);
        try{
            if(oppListToInsert.size() > 0) {
                insert oppListToInsert;
                isSuccess = true;
            }
            return isSuccess;
        } catch(Exception err){
            System.debug(Logginglevel.ERROR, err.getMessage());
            throw new AuraHandledException(err.getMessage());
        }
    }

    //update the campagin members
    @AuraEnabled
    public static Boolean updateCampaignMembers(List<CampaignMember> camMemsToUpdate) {
        Boolean updateSuccess = false;
        System.debug('Campaign Members to update: '+camMemsToUpdate);
        try{
            if(camMemsToUpdate.size() > 0) {
                update camMemsToUpdate;
                updateSuccess = true;
            }
            System.debug('campaign members udpated'+updateSuccess);
            return updateSuccess;
        } catch(Exception err){
            System.debug(Logginglevel.ERROR, err.getMessage());
            throw new AuraHandledException(err.getMessage());
        }
    }

    //get the related campaign member status
    @AuraEnabled
    public static List<string> getCampaingMemberStatus(Id campaignId){
        List<String> cmsList = new List<String>();
        for(CampaignMemberStatus cms : [ SELECT CampaignID,label FROM CampaignMemberStatus  WHERE campaignId =: campaignId]) {
            cmsList.add(cms.label);
        }
        return cmsList;
    }
}
