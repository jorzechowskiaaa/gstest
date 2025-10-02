/**
 * @File Name          : FSL_ShiftTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:52:12 AM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    3/9/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ShiftTrigger on Shift (Before Insert, Before Update, After insert, After Update, After Delete) {
    FSL_TriggerDispatcher.run(new FSL_ShiftTriggerHandler());
}