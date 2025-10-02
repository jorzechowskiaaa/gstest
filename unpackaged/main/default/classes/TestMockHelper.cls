public virtual with sharing class TestMockHelper {

    protected Map <String, Integer> callCounts = new Map<String, Integer>();
    protected Map <String, Object>  returnValues = new Map<String, Object>();

    protected Exception exceptionToThrow = null;
 
 
    public void setReturnValue(String fname, Object obj) {
            returnValues.put(fname, obj);           
    }
    public void setException(Exception ex) {
        exceptionToThrow = ex;
    }
    public Integer getCallCount(String fname) {
        Integer count = 0;
        if ( callCounts.containsKey(fname)) {
            count = callCounts.get(fname);
        }
        return count;
    }

    protected Integer incrementCount(String fname) {
        Integer count = 0;
        if ( callCounts.containsKey(fname)) {
            count = callCounts.get(fname);
        }
        count++;
        callCounts.put(fname, count);           
        return count;
    }
    protected Object  incrementReturnOrThrow(string fname) {
        Object returnValue = null;
        incrementCount(fname);
        if ( exceptionToThrow != null) {
            throw exceptionToThrow;
        }
        if ( returnValues.containsKey(fname)) {
            returnValue = returnValues.get(fname);
        }
        return returnValue;
    }
}