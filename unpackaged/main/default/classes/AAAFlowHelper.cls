public class AAAFlowHelper {

    
    @InvocableMethod(label='Split Multi-Select' description='Iterate over multi-select list stored as string with delimeters, return list of strings')
    public static List<outputVariables> splitMultiSelect(List<inputVariables> lstMultiSelect){
        
        if(lstMultiSelect != null && lstMultiSelect.size()>0){
			String multiStr = lstMultiSelect.get(0).choicesMulti[0];
            outputVariables outPut = new outputVariables();
            List<outputVariables> lstoutPut = new List<outputVariables>();
            List<String> splitString = multiStr.split(';');
            if(splitString!=null && splitString.size()>=1) 
            	outPut.choicesSplit = splitString;
            else
                outPut.choicesSplit = null;
            system.debug(' ################ '+outPut.choicesSplit);
            lstoutPut.add(outPut);
            return lstoutPut;
        }
        
        return null;
            
    }
    
    
    public class inputVariables{ 
        @InvocableVariable
        public List<String> choicesMulti;
    }
    
    public class outputVariables{ 
        @InvocableVariable
        public List<String> choicesSplit;
    }
}