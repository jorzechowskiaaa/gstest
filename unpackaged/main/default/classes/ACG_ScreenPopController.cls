global class ACG_ScreenPopController{  
    @RemoteAction
    public static string getCaseId(string memNum, string contactANI) {
        return new ACG_ScreenPopService().searchCase(memNum, contactANI);
    }
    @RemoteAction
    public static string getBaseURL(){
        return URL.getSalesforceBaseURL().toExternalForm();
    }
	@RemoteAction
	public static string getRelatedCases(string caseIdsStr, string delimiter) {
		return ACG_ScreenPopService.getRelatedCases(caseIdsStr, delimiter);
	}
}