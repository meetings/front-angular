package gs.meetin.connector.events;

import org.apache.cordova.CallbackContext;

public class SuggestionEvent extends Event {

	private CallbackContext callbackContext;
	
    public SuggestionEvent(EventType type) {
        super(type);
    }
	
    public void setCallbackContext(CallbackContext callbackContext) {
    	this.callbackContext = callbackContext;
    }
    
    public CallbackContext getCallbackContext() {
    	return callbackContext;
    }
}
