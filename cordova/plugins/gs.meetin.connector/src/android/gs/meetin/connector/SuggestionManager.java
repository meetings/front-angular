package gs.meetin.connector;

import static gs.meetin.connector.events.Event.EventType.UPDATE_SUGGESTIONS_SUCCESSFUL;
import android.content.Context;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.joda.time.DateTime;

import de.greenrobot.event.EventBus;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import gs.meetin.connector.adapters.SessionAdapter;
import gs.meetin.connector.dto.CalendarSuggestion;
import gs.meetin.connector.dto.SourceContainer;
import gs.meetin.connector.dto.SuggestionBatch;
import gs.meetin.connector.dto.SuggestionSource;
import gs.meetin.connector.events.SuggestionEvent;
import gs.meetin.connector.services.SuggestionService;
import gs.meetin.connector.utils.DateHelper;
import gs.meetin.connector.utils.Device;
import retrofit.Callback;
import retrofit.RestAdapter;
import retrofit.RetrofitError;
import retrofit.client.Response;

public class SuggestionManager {

    private Context context;

    private SuggestionService suggestionService;

    private HashMap<String, ArrayList<CalendarSuggestion>> previousSuggestions;

    private String containerName;
    private String androidId;

    private int updateSuggestionsSuccessCounter;

    public SuggestionManager(Context context) {
        this.context = context;

        String appVersion = Device.appVersion(context);

        SessionManager sessionManager = new SessionManager(context);
        
        RestAdapter sessionAdapter = SessionAdapter.build(sessionManager.getUserId(), sessionManager.getToken(), appVersion);
        suggestionService = new SuggestionService(sessionAdapter, sessionManager.getUserId());

        previousSuggestions = new HashMap<String, ArrayList<CalendarSuggestion>>();

        containerName = Device.getDeviceName();
        androidId = Device.getAndroidId(context.getContentResolver());
    }

    public boolean update(boolean forceUpdate, final CallbackContext callbackContext) {
        final short unmanned = (short) (forceUpdate ? 0 : 1);

        ArrayList<SuggestionSource> suggestionSources = new CalendarManager().getCalendars(context);

        final ArrayList<SuggestionBatch> updateList = getSuggestions(suggestionSources, forceUpdate);

        if (forceUpdate || previousSuggestions.size() < suggestionSources.size() || !updateList.isEmpty()) {
            // Found new suggestions
            updateSuggestionsSuccessCounter = 0;
            updateSuggestionSources(unmanned, suggestionSources, onSuggestionSourcesUpdated(unmanned, callbackContext, updateList));

            return true;
        } else {
            return false;
        }
    }

    public ArrayList<SuggestionBatch> getSuggestions(ArrayList<SuggestionSource> suggestionSources, boolean forceUpdate) {

        ArrayList<SuggestionBatch> updateList = new ArrayList<SuggestionBatch>();

        DateTime todayDateTime = DateHelper.today();
        long todayEpoch = todayDateTime.getMillis() / 1000;
        long threeMonthsFromNowEpoch = todayDateTime.plusMonths(3).getMillis() / 1000;

        for (SuggestionSource calendar : suggestionSources) {

            ArrayList<CalendarSuggestion> suggestions = new CalendarManager().getEventsFromCalendar(context, calendar.getName());

            // If new suggestions were found or if user has pressed 'Sync now', send new results to backend
            if (forceUpdate || hasNewMeetings(calendar.getName(), suggestions)) {

                updateList.add(new SuggestionBatch(containerName, "phone", androidId, calendar.getName(), calendar.getName(), calendar.getIsPrimary(), todayEpoch, threeMonthsFromNowEpoch, suggestions));
            }
        }

        return updateList;
    }

    public void updateSuggestionSources(short unmanned, ArrayList<SuggestionSource> suggestionSources, Callback cb) {
        SourceContainer sourceContainer = new SourceContainer(containerName, "phone", androidId, suggestionSources);

        suggestionService.updateSources(unmanned, sourceContainer, cb);
    }

    // Send an empty suggestion source list to remove suggestion sources from backend
    public void removeSuggestionSources() {
        short unmanned = 0;
        updateSuggestionSources(unmanned, new ArrayList<SuggestionSource>(), null);
    }

    public void updateSuggestions(short unmanned, final CallbackContext callbackContext, ArrayList<SuggestionBatch> updateList) {
        for (SuggestionBatch batch : updateList) {
            suggestionService.updateSuggestions(unmanned, batch, onSuggestionsUpdated(unmanned, callbackContext, batch, updateList.size()));
        }
    }

    // Compare in memory cache of meetings to the ones found in calendar
    private boolean hasNewMeetings(String calendarName, ArrayList<CalendarSuggestion> suggestions) {

        ArrayList<CalendarSuggestion> previous = previousSuggestions.get(calendarName);

        if (previous == null) {
            return true;
        }

        List<CalendarSuggestion> previousList = new ArrayList<CalendarSuggestion>(previous);
        List<CalendarSuggestion> newList = new ArrayList<CalendarSuggestion>(suggestions);

        previousList.removeAll(suggestions);
        newList.removeAll(previous);

        return !newList.isEmpty() || !previousList.isEmpty();
    }

    private Callback onSuggestionSourcesUpdated(final short unmanned, final CallbackContext callbackContext, final ArrayList<SuggestionBatch> updateList) {
        return new Callback() {

            @Override
            public void success(Object o, Response response) {
                updateSuggestions(unmanned, callbackContext, updateList);

            }

            @Override
            public void failure(RetrofitError error) {
                Log.e("Mtn.gs", error.getMessage());
            }
        };
    }

    private Callback onSuggestionsUpdated(final short unmanned, final CallbackContext callbackContext, final SuggestionBatch batch, final int updateListSize) {
        return new Callback() {

            @Override
            public void success(Object o, Response response) {

                // Save suggestions to cache on successful update
                previousSuggestions.put(batch.getSourceName(), batch.getSuggestions());

                updateSuggestionsSuccessCounter++;

                // Tell javascript to update last sync time
                if (updateSuggestionsSuccessCounter == updateListSize) {
                    SuggestionEvent suggestionEvent = new SuggestionEvent(UPDATE_SUGGESTIONS_SUCCESSFUL);
                    suggestionEvent.setCallbackContext(callbackContext);
                    EventBus.getDefault().post(suggestionEvent);
                }
            }

            @Override
            public void failure(RetrofitError error) {
                Log.e("Mtn.gs", error.getMessage());
            }
        };
    }
}
