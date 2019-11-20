/##############################################
Apex can be invoked by using triggers. Apex triggers enable you to perform custom actions before or after changes to Salesforce records, such as insertions, updates, or deletions.
A trigger is Apex code that executes before or after the following types of operations:

insert
update
delete
merge
upsert
undelete

/##############################################
Trigger Best Practices:

One Trigger per Object
Logic-less trigger
Context-specific handler methods

/##############################################
Why Use a Framework?
Now, we have some best practices you must be thinking that what if I am following all the best practices do I need to use the trigger framework. The simple answer is No.

A framework may, however, greatly simplify your development efforts when your code base gets large. In a nutshell, your framework should have the following goals:

Help you to conform to best practices
Make implementing new logic and new context handlers very easy
Simplify testing and maintenance of your application logic
Enforces consistent implementation of Trigger logic
Implement tools, utilities, and abstractions to make your handler logic as lightweight as possible
Assure the Order of execution of the code
Prevent the recursion.
Ensure that trigger will do not create any issue while working with large datasets.
 


/*********************************************
TriggerInterface

The apex interface which contains the methods that needs to be implemented while developing the handler class even if there is no logic for those methods. Using the interface we are assuring that developer will follow all the best practice.
*********************************************/

public interface TriggerInterface{
   
    void beforeInsert(List<sObject> newRecordsList);
    
    void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
    
    void beforeUpdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap);

    void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap);
               
    void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap);
    
    void afterDelete(Map<Id, sObject> oldRecordsMap);
    
    void afterUnDelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
}


/*********************************************
TriggerDispatcher

This class is the heart of the framework which contains 2 methods a) run and b) execute. The developer needs to call the run method from the trigger and pass the parameters then the call will do the trick and will redirect to the correct method of the handler class.

we are making a SOQL on Trigger Setting by which we will control the trigger events and also trigger is disabled or Not.  if(triggerSetting[0].Disabled__c ) return; checks if the trigger is disabled from the UI if yes then return the trigger and do not execute.
*********************************************/

public with sharing class TriggerDispatcher{

    public static void run(TriggerInterface handler, String ObjectName){
    
       /*
        * Fetch the Trigger Settings Records and check in which context Trigger can be executed.
        */ 
        List<Trigger_Setting__c> triggerSettingList = new List<Trigger_Setting__c>();
        triggerSettingList = [Select Id, Name, Disabled__c, Object_Name__c, Before_Update__c, Before_Insert__c, Before_Delete__c,
                                After_Update__c, After_Undelete__c, After_Insert__c, After_Delete__c, Prevent_Recursion__c
                                From Trigger_Setting__c  Where Object_Name__c =: objectName];
        
        execute(handler, triggerSettingList);
    }

    private static void execute(TriggerInterface handler, List<Trigger_Setting__c> triggerSetting){

        if(triggerSetting !=null && triggerSetting.size() > 0){
            if(triggerSetting[0].Disabled__c  ) return ; 
        }else{
            throw new TriggerException('No Trigger Setting found! Please create an entry for '+
                ' Trigger Settings Object. Contact your administrator');
        }
        
        /*
         * If trigger is executing in before context then route to the befor context methods
         */
        if(Trigger.isBefore){
            if(Trigger.isInsert && triggerSetting[0].Before_Insert__c){
                handler.BeforeInsert(Trigger.New);
            }
            if(Trigger.isUpdate && triggerSetting[0].Before_Update__c){
                handler.BeforeUpdate(Trigger.NewMap, Trigger.oldMap);
            }
            if(Trigger.isDelete && triggerSetting[0].Before_Delete__c){
                handler.BeforeDelete(Trigger.old, Trigger.oldMap);
            }
        }
        
       /*
        * If trigger is executing in after context then route to the after context methods
        */
        If(Trigger.isAfter){
            if(Trigger.isInsert && triggerSetting[0].After_Insert__c){
                handler.AfterInsert(Trigger.new, Trigger.newMap);
            }
            
            /* If trigger is executing in After Update Context then Check 
               if the field have been changed or not if not do not call the hanlder
               in order to prevent the recursion
           */
           
            If(Trigger.isUpdate && triggerSetting[0].After_Update__c){
                Map<Id, sObject> newItemsMap = new map<Id, sObject>();
                Map<Id, sObject> oldItemsMap = new map<Id, sObject>();
                List<String> fieldAPINameList = new List<String>();
                if(triggerSetting[0].Prevent_Recursion__c !=null)
                    fieldAPINameList = triggerSetting[0].Prevent_Recursion__c.split(',');
                
                for(sObject obj : Trigger.NewMap.Values()){
                    for(String field : fieldAPINameList){
                        if(obj.get(field.trim()) != Trigger.oldMap.get(obj.Id).get(field.trim())){
                            
                            if(!newItemsMap.containsKey(obj.Id))
                                newItemsMap.put(obj.Id, obj);
                            if(!oldItemsMap.containsKey(obj.Id))
                                oldItemsMap.put(obj.id, Trigger.oldMap.get(obj.Id));
                        }
                    }
                }
                handler.AfterUpdate(newItemsMap, oldItemsMap);
            }
            If(Trigger.isDelete && triggerSetting[0].After_Delete__c){
                handler.AfterDelete(Trigger.oldMap);
            }
            If(Trigger.isUndelete && triggerSetting[0].After_Undelete__c){
                handler.AfterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }
}

/*********************************************
TriggerHandler

The developer needs to develop the handler class and must implement the TriggerInterface with it’s all methods. Here is the sample handler class. Implementation of the TriggerInterface interface is must.

In the handler class method use try and catch where required and in catch method call doHandleException method of TransactionLogHandler class to catch the exception.
*********************************************/

public class AccountTriggerHandler implements TriggerInterface{
 
    public void BeforeInsert(List<SObject> newItems) { }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(List<sObject> oldRecordsList , Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        Try{
        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            TransactionLogHandler.doHandleException(ex , 'AccountTriggerHandler');
        }
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        /* Update the AccountNumber */
        List<Account> accountToUpdateList = new List<Account>();
        Try{           
        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            
            TransactionLogHandler.doHandleException(ex , 'AccountTriggerHandler');
        }
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}
    
}

/*********************************************
Trigger

In the final steps, create the trigger and put a single line of code and rest is magic. See example trigger on account object.
*********************************************/

trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(new AccountTriggerHandler() , 'Account');
}

/*********************************************
TransactionLogHandler

The class which is responsible for catching the exception and then inserting into the Transaction Log Object.
*********************************************/
public with sharing class TransactionLogHandler{

    public static void doHandleException(System.Exception ex , String processName){
        Transaction_Log__c transactionLog = new Transaction_Log__c(
            Error_Log__c = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName(),
            Exception_Time__c = System.Now(),
            Process_Name__c = processName,
            Class_Name__c = processName
        );
        if(Schema.sObjectType.Transaction_Log__c.isCreateable()){
            insert transactionLog;
        }
        
    }

}
