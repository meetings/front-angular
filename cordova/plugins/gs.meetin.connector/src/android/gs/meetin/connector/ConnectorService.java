package gs.meetin.connector;

import android.app.IntentService;
import android.content.Intent;
import android.util.Log;
import de.greenrobot.event.EventBus;
import gs.meetin.connector.events.Event;
import gs.meetin.connector.events.SuggestionEvent;
import static gs.meetin.connector.events.Event.EventType.UPDATE_SUGGESTIONS;

public class ConnectorService extends IntentService {

    private boolean running = false;

    private SuggestionManager suggestionManager;

    public ConnectorService() {
        super("ConnectorService");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d("Mtn.gs", "Starting service...");

        return super.onStartCommand(intent,flags,startId);
    }

    @Override
    public void onCreate() {
        super.onCreate();
        running = true;

        suggestionManager = new SuggestionManager(this);

        EventBus.getDefault().register(this);
    }

    @Override
    public void onDestroy() {
        Log.d("Mtn.gs", "Stopping service...");
        running = false;
        suggestionManager = null;
        EventBus.getDefault().unregister(this);
        super.onDestroy();
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        while (running) {
            synchronized (this) {
                try {
                    wait(AppConfig.getInstance().getUpdateInterval());
                    
                    Log.d("Mtn.gs", "Syncing suggestions... ");

                    SuggestionEvent suggestionEvent = new SuggestionEvent(UPDATE_SUGGESTIONS);
                    suggestionEvent.putBoolean("forceUpdate", false);
                    EventBus.getDefault().post(suggestionEvent);

                } catch (Exception e) {
                }
            }
        }
    }

    public void onEvent(SuggestionEvent event) {
		if (event.getType() == Event.EventType.UPDATE_SUGGESTIONS) {
        	suggestionManager.update(event.getBoolean("forceUpdate"), event.getCallbackContext());
        }
    }
}
