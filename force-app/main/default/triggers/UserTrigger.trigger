trigger UserTrigger on User (After insert,After update) {
    if(trigger.isAfter && trigger.isInsert){
     UserTriggerHelper.afterInsert(trigger.newMap); 
    }
    If(trigger.isAfter && trigger.isUpdate){
        UserTriggerHelper.afterUpdate(trigger.new,trigger.oldMap);
    }
}