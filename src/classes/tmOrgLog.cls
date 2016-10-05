public with sharing class tmOrgLog extends BaseOrgLog {
    public List<String> emailAddresses { get; set; }

    @TestVisible
    private String chatterGroupId = null;
    private String module = 'TM';

    // The following are implemented to satisify the abstract base class methods
    private List<String> getEmailAddresses() { return emailAddresses; }
    private String getChatterGroupId() { 
        if (chatterGroupId == null) {
             List<CollaborationGroup> chatterGroupList = [SELECT Id, Name from CollaborationGroup WHERE name = : tmConstants.CHATTER_GROUP_NAME LIMIT 1];
             if (chatterGroupList.size() >  0 ) {
                chatterGroupId = chatterGroupList.get(0).Id;
             }


        }
        return chatterGroupId; 
    }
    private String getModule() { return module; }

	public tmOrgLog() { } 
	   
	public static tmOrgLog log (Exception ex) {
		tmOrgLog tol = new tmOrgLog();
		tol.doLog(ex);
		return tol;
	}

    public static tmOrgLog log (Level logLvl, Exception ex) {
        tmOrgLog tol = new tmOrgLog();
        tol.doLog(logLvl, ex);
        return tol;
    }

    public static tmOrgLog log (Level logLvl, Exception ex, String objId) {
        tmOrgLog tol = new tmOrgLog();
        tol.doLog(LogLvl, ex, objId);
        return tol;
    }
    public static tmOrgLog log(level logLvl, String cls, String dtl, String objId) {
        tmOrgLog tol = new tmOrgLog();
        tol.doLog(logLvl, cls, dtl, objId);
        return tol;
    }
}