trigger ContactTrigger on Contact (	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isAfter && Trigger.isUpdate) {
	    	AccountContactTriggerHandler.updateCategory(Trigger.oldMap, Trigger.newMap);
		}
}