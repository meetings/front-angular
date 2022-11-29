package gs.meetin.connector;

import android.content.Intent;
import de.greenrobot.event.EventBus;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import gs.meetin.connector.events.Event;
import gs.meetin.connector.events.SuggestionEvent;
import static gs.meetin.connector.events.Event.EventType.UPDATE_SUGGESTIONS;

public class CalendarConnectorPlugin extends CordovaPlugin {

    public static final String ACTION_INIT = "init";
    public static final String ACTION_GET_USER_ID = "getUserId";
    public static final String ACTION_GET_TOKEN = "getToken";
    public static final String ACTION_SIGN_IN = "signIn";
    public static final String ACTION_SIGN_OUT = "signOut";
    public static final String ACTION_START_SERVICE = "startService";
    public static final String ACTION_STOP_SERVICE = "stopService";
    public static final String ACTION_FORCE_UPDATE = "forceUpdate";
    public static final String ACTION_REMOVE_SOURCES = "removeSources";

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    @Override
    public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) {

    	if (ACTION_INIT.equals(action)) {
            return init(data, callbackContext);

        } else if (ACTION_GET_USER_ID.equals(action)) {
            return getUserId(callbackContext);

        } else if (ACTION_GET_TOKEN.equals(action)) {
            return getToken(callbackContext);

        }else if (ACTION_SIGN_IN.equals(action)) {
            return signIn(data, callbackContext);

        } else if (ACTION_SIGN_OUT.equals(action)) {
            return signOut(callbackContext);

        } else if (ACTION_START_SERVICE.equals(action)) {
            return startCalendarService(callbackContext);

        } else if (ACTION_STOP_SERVICE.equals(action)) {
            return stopCalendarService(callbackContext);

        } else if (ACTION_FORCE_UPDATE.equals(action)) {
            return forceUpdate(callbackContext);

        } else if (ACTION_REMOVE_SOURCES.equals(action)) {
            return removeSources(callbackContext);

        }

        return false;
    }

    private boolean init(final JSONArray data, final CallbackContext callbackContext) {
        try {
            String userId = data.getString(0);
            String token  = data.getString(1);

            SessionManager sessionManager = new SessionManager(cordova.getActivity().getApplicationContext());
            sessionManager.signIn(userId, token);

        	String apiBaseURL = data.getString(2);
			Long updateInterval  = data.getLong(3);

			if (apiBaseURL != null) {
                AppConfig.getInstance().setApiBaseURL(apiBaseURL);
            }
            if (updateInterval != null) {
                AppConfig.getInstance().setUpdateInterval(updateInterval);
            }

			callbackContext.success();
			return true;
		} catch (JSONException e) {
            callbackContext.error(e.getMessage());
            return false;
		}
    }

    private boolean getUserId(final CallbackContext callbackContext) {
        SessionManager sessionManager = new SessionManager(cordova.getActivity().getApplicationContext());
        String userId = sessionManager.getUserId();

        callbackContext.success(userId);
        return true;}

    private boolean getToken(final CallbackContext callbackContext) {
        SessionManager sessionManager = new SessionManager(cordova.getActivity().getApplicationContext());
        String token = sessionManager.getToken();

        callbackContext.success(token);
        return true;}

    private boolean signIn(final JSONArray data, final CallbackContext callbackContext) {

        try {
            String userId = data.getString(0);
            String token  = data.getString(1);

            SessionManager sessionManager = new SessionManager(cordova.getActivity().getApplicationContext());
            sessionManager.signIn(userId, token);

            callbackContext.success();
            return true;

        } catch (JSONException e) {
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    private boolean signOut(final CallbackContext callbackContext) {
        Intent serviceIntent = new Intent(cordova.getActivity().getApplicationContext(), ConnectorService.class);
        cordova.getActivity().stopService(serviceIntent);

        SessionManager sessionManager = new SessionManager(cordova.getActivity().getApplicationContext());
        sessionManager.signOut();

        callbackContext.success();
        return true;
    }

    private boolean startCalendarService(final CallbackContext callbackContext) {
        Intent serviceIntent = new Intent(cordova.getActivity().getApplicationContext(), ConnectorService.class);
        cordova.getActivity().startService(serviceIntent);

        callbackContext.success();
        return true;
    }

    private boolean stopCalendarService(final CallbackContext callbackContext) {
        Intent serviceIntent = new Intent(cordova.getActivity().getApplicationContext(), ConnectorService.class);
        cordova.getActivity().stopService(serviceIntent);

        callbackContext.success();
        return true;
    }

    private boolean forceUpdate(final CallbackContext callbackContext) {
    	if (!EventBus.getDefault().isRegistered(this)) {
    		EventBus.getDefault().register(this);
    	}

        SuggestionEvent suggestionEvent = new SuggestionEvent(UPDATE_SUGGESTIONS);
        suggestionEvent.setCallbackContext(callbackContext);
        suggestionEvent.putBoolean("forceUpdate", true);
        EventBus.getDefault().post(suggestionEvent);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
        return true;
    }

    // Remove suggestion sources.
    // No callback for this one, let's just hope that the suggestion sources really are removed.
    private boolean removeSources(final CallbackContext callbackContext) {;
        new SuggestionManager(cordova.getActivity().getApplicationContext()).removeSuggestionSources();

        callbackContext.success();
        return true;
    }

    public void onEvent(SuggestionEvent event) {
        if (event.getType() == Event.EventType.UPDATE_SUGGESTIONS_SUCCESSFUL) {
            CallbackContext callbackContext = event.getCallbackContext();

            if (callbackContext != null) {
            	PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
                pluginResult.setKeepCallback(false);
                callbackContext.sendPluginResult(pluginResult);
            }
        }
    }
}
