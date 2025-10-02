global without sharing class AAAReciprocalCostCalUtility {

 @InvocableMethod(label = 'Call Reciprocal CostCal Utility')
 global static List< CostOutput > runIntegrationServiceInvocable(List < CostInput > input) {
   
   List<Integer> lstDollarAmounts = input.get(0).lstAmounts;
   List<Integer> lstDollarLeadingZeroes = input.get(0).lstLeadingZeroes;
     
   List<CostOutput> lstOutput = new List<CostOutput>();
   CostOutput cOp = new CostOutput();
   List<String> lstModAmounts = new List<String>();
     
     for(Integer i=0;i<lstDollarAmounts.size();i++)
     /*for(Integer k=0;k<lstDollarLeadingZeroes.size();k++)*/{
         //for(Integer k=0;k<lstDollarLeadingZeroes[i];k++){
         String modAmount = String.valueOf(lstDollarAmounts[i]);
         if(!String.isBlank(modAmount)){
             for(Integer k=0;k<lstDollarLeadingZeroes[i];k++){
                 modAmount = '0'+modAmount;
             }
         }else{
             modAmount = '00000';
         }
         //}
         lstModAmounts.add(modAmount);
     }
   
   cOp.output = lstModAmounts;
   lstOutput.add(cOp); 
     
   return lstOutput;
 }
 global class CostInput
 {
  @InvocableVariable(label = 'Amounts') global List<Integer> lstAmounts;
  @InvocableVariable(label = 'Leading 0s') global List<Integer> lstLeadingZeroes;
 }
 global class CostOutput
 {
  @InvocableVariable(label = 'Final Amounts') global List<String> output;
 }

}