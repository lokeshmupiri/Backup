import { LightningElement, wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import OPPORTUNITY from '@salesforce/schema/Opportunity';
import CAMPAIGN_MEMBER from '@salesforce/schema/CampaignMember';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getCampaignMembers from '@salesforce/apex/CreateOpportunitiesHelper.getCampaignMembers';
import createOpportunities from '@salesforce/apex/CreateOpportunitiesHelper.createOpportunities';
import updateCampaignMembers from '@salesforce/apex/CreateOpportunitiesHelper.updateCampaignMembers';
import getCampaingMemberStatus from '@salesforce/apex/CreateOpportunitiesHelper.getCampaingMemberStatus';

const FIELDS = [
    'Campaign.Name',
    'Campaign.Term__c',
    'Campaign.Citizenship__c',
    'Campaign.Campus__c',
    'Campaign.Preferred_Language__c',
    'Campaign.Level_of_Study__c',
    'Campaign.Audience__c'
]
export default class CreateOpportunitiesLWC extends LightningElement {

    //schema of campaign memeber object
    @wire(getObjectInfo, { objectApiName : CAMPAIGN_MEMBER })
    campaignMemInfo;

    //schema of opportuntiy object
    @wire(getObjectInfo, {
        objectApiName: OPPORTUNITY
    }) opporutunityInfo;

    @api recordId; //current campaign id
    @track selectedValues = []; //selected values of campaign member status
    @track picklistValues = []; //status picklist field values from the campaign member
    @track Spinner = true;

    //get the necessary field information from the current campaign
    @wire(getRecord, {
        recordId : '$recordId',
        fields : FIELDS
    }) campaign;

    connectedCallback(){
        //get the dynamic picklist valuas for status field from the campaign member
        getCampaingMemberStatus({
            'campaignId': this.recordId
        }).then(result=>{
            for (let i = 0; i < result.length; i++) {
                let rec = {};
                rec.label = result[i];
                rec.value = result[i];
                this.picklistValues.push(rec);
            }
            this.Spinner = false;
        });
    }

    handleChange(e) {
        //add the selected picklist value to selectedValues array
        this.selectedValues = e.detail.value;
    }

    //close the popup
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    //once the user clicks on create button, create the opportunities and update the campaign members
    handleCreate() {
        console.log('selected', this.selectedValues);
        this.Spinner = true;
        var oppsToCreate = []; //array to store the new opportunies to insert
        var camMemToUpdate =[]; //array to store the campaing members to update with 'Opportunity created' checkbox to true
        
        //get the campaign memebers based on the status selected in the page
        getCampaignMembers({
            'campaignId' : this.recordId,
            'statusList' : this.selectedValues
        }).then(result => {
            console.log('result length :', result.length);

            //if there is no mathing campaign member found, then show warning message
            if (result.length === 0){
                this.dispatchEventMessage('Warning','No matches found, please change the criteria', 'warning');
                this.Spinner = false;
            } else {
                //create opportunity for each campaign member
                for(let r=0; r<result.length; r++) {
                    let campaignMem = result[r];

                    //campaging member to update
                    let camMem = {
                        'sobjectType': CAMPAIGN_MEMBER.objectApiName
                    }
                    camMem.Id = campaignMem.Id;
                    camMem.Opportunity_Created__c = true;
                    camMemToUpdate.push(camMem);

                    //opportuntiy record to insert
                    let opp = {
                        'sobjectType': OPPORTUNITY.objectApiName
                    };
                    opp.Contact_custom__c = campaignMem.ContactId;
                    opp.Term__c = this.campaign.Term__c ? this.campaign.Term__c : '';
                    opp.Citizenship__c = this.campaign.Citizenship__c ? this.campaign.Citizenship__c : '';
                    opp.Campus__c = this.campaign.Campus__c ? this.campaign.Campus__c : '';
                    opp.Preferred_Language__c = this.campaign.Preferred_Language__c ? this.campaign.Preferred_Language__c : '';
                    opp.Level_of_Study__c = this.campaign.Level_of_Study__c ? this.campaign.Level_of_Study__c : '';
                    opp.RecordTypeId = this.recordTypeId();
                    opp.AccountId = campaignMem.Contact.AccountId;
                    opp.CloseDate = new Date().toISOString();
                    opp.Name = campaignMem.Contact.LastName + (opp.Level_of_Study__c ? '-' + opp.Level_of_Study__c : '');
                    opp.OwnerId = userId;
                    opp.StageName = 'Qualify Interest';

                    //add to the new opportunity to list
                    oppsToCreate.push(opp);
                }

                //call the method to insert opportunity
                if (oppsToCreate.length > 0) {
                    this.createOpportunities(oppsToCreate, camMemToUpdate);
                }
            }
        }).catch(error=>{
            console.log(JSON.stringify(error));
            this.dispatchEventMessage('Error getting campaign members', error.message, 'error');
            this.Spinner = false;
        });
    }

    //helper method to create opportunities
    createOpportunities(oppsToCreate, camMemToUpdate) {
        console.log('oppsToinsert: ', oppsToCreate);
        //apex method to insert the opportunites
        createOpportunities({'oppListToInsert' : oppsToCreate})
        .then(result => {
            if(result === true) {
                //show success message on screen
                this.dispatchEventMessage('Success','Opportunities Successfully Created', 'success');
                //if opportunities are created successfully, updated the campaing members that opportunity created checkbox to true
                this.updateCampaignMembers(camMemToUpdate);
            } else {
                this.dispatchEventMessage('Something went wrong', 'Contact your system admin', 'warning');
                this.Spinner = false;
            }
        }).catch(error => {
            console.log('error on opp ', JSON.stringify(error));
            let message = error.body.message ? error.body.message : error.body ? error.body : error;
            //show error message on screen
            this.dispatchEventMessage('Error Creating Opportunities', message  , 'error');
            this.Spinner = false;
        });
    }

    //helper method to update the campagin member with 'opportunity created' checkbox to true
    updateCampaignMembers(camMemToUpdate) {
        updateCampaignMembers({
            'camMemsToUpdate': camMemToUpdate
        }).then(result=>{
            if (result === true) {
                this.dispatchEventMessage('Success','Campaign Members are successfully updated','success')
                this.dispatchEvent(new CustomEvent('close'));
            } else {
                this.dispatchEventMessage('Something went wrong', 'Contact your system admin', 'warning');
                this.Spinner = false;
            }
        }).catch(error=>{
            console.log('error on campaign', JSON.stringify(error));
            //show error toast on screen
            this.dispatchEventMessage('Error updating Campaign Members',error.body.message, 'error');
            this.Spinner = false;
        })
    }

    //get the record type Id from opportunity
    recordTypeId() {
        // Returns a map of record type Ids 
        const rtis = this.opporutunityInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'B2C Prospect');
    }

    //common method to show toast event
    dispatchEventMessage(title, error, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title : title,
                message : error,
                variant : type
            }),
        );
    }
}