trigger AccountContactTrigger on AccountContact__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isBefore && Trigger.isDelete) {
			AccountContactTriggerHandler.removeCategory(Trigger.old);	    
		} else if (Trigger.isAfter && Trigger.isInsert) {
	    	AccountContactTriggerHandler.addCategory(Trigger.newMap);
		}
}