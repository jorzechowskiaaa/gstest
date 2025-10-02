/**
 * @File Name          : FSL_GanttListFilter.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:15:15 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_GanttListFilter on FSL__Gantt_Filter__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FSL_TriggerDispatcher.run(new FSL_GanttListFilterHandler());
}