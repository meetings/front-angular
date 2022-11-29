package gs.meetin.connector;

/**
 * Created by tuomaslahti on 16/07/14.
 */
public class AppConfig {

	// Default values for appConfig
    private String apiBaseURL = "https://api.meetin.gs/v1";
    private long updateInterval = (1000 * 60) * 10;
    
    private static AppConfig instance = null;
    
    protected AppConfig() {
    	
    }
    
    public static AppConfig getInstance() {
    	if (instance == null) {
    		instance = new AppConfig();
    	}
    	
    	return instance;
    }

	public long getUpdateInterval() {
		return updateInterval;
	}

	public void setUpdateInterval(long updateInterval) {
		this.updateInterval = updateInterval;
	}

	public String getApiBaseURL() {
		return apiBaseURL;
	}

	public void setApiBaseURL(String apiBaseURL) {
		this.apiBaseURL = apiBaseURL;
	}
}
