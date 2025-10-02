/**
 * @description			: Test Class for CallCommentsByDateRange_Scheduler.
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
@isTest
public class CallCommentsByDateRange_SchedulerTest {
    
    public testMethod static void positiveScheduleTest(){
        
        String schedule = '1 1 * * * ?';
        String jobTitle = 'Call Comments By Date Range Job';
        CallCommentsByDateRange_Scheduler scheduler = new CallCommentsByDateRange_Scheduler();
        String jobId = system.schedule(jobTitle, schedule, scheduler);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(schedule, ct.CronExpression, 'Schedue should match.');
        System.assert(ct.NextFireTime != null, 'NextFireTime should be defined.');        
    }
}