package gs.meetin.connector.services;

import android.util.Log;

import de.greenrobot.event.EventBus;
import gs.meetin.connector.dto.SourceContainer;
import gs.meetin.connector.dto.SuggestionBatch;
import gs.meetin.connector.events.ErrorEvent;
import retrofit.Callback;
import retrofit.RestAdapter;
import retrofit.RetrofitError;
import retrofit.client.Response;
import retrofit.http.Body;
import retrofit.http.Header;
import retrofit.http.Headers;
import retrofit.http.POST;
import retrofit.http.Path;

public class SuggestionService {

    private String userId;
    private SuggestionRouter suggestionService;

    public interface SuggestionRouter {

        @Headers( { "x-meetings-unmanned: {unmanned}" } )
        @POST("/users/{userId}/suggestion_sources/set_container_batch")
        void updateSources(@Header("unmanned") String unmanned, @Path("userId") String userId, @Body SourceContainer body, Callback<SourceContainer> cb);

        @Headers( { "x-meetings-unmanned: {unmanned}" } )
        @POST("/users/{userId}/suggested_meetings/set_for_source_batch")
        void updateSuggestions(@Header("unmanned") String unmanned, @Path("userId") String userId, @Body SuggestionBatch body, Callback<SuggestionBatch> cb);

    }

    public SuggestionService(RestAdapter restAdapter, String userId) {
        suggestionService = restAdapter.create(SuggestionRouter.class);
        this.userId = userId;
    }

    public void updateSources(short unmanned, SourceContainer sourceContainer, final Callback cb) {
        suggestionService.updateSources(String.valueOf(unmanned), userId, sourceContainer, new Callback<SourceContainer>() {
            @Override
            public void success(SourceContainer result, Response response) {

                if(result.getError() != null) {
                    EventBus.getDefault().post(new ErrorEvent("Sorry!", result.getError().message));
                }

                Log.d("Mtn.gs", "Updated sources successfully");

                if (cb != null)
                    // Null parameters because only information about successful request is needed
                    cb.success(null, null);
            }

            @Override
            public void failure(RetrofitError error) {
                Log.e("Mtn.gs", error.getMessage());
                EventBus.getDefault().post(new ErrorEvent("Sorry!", error.getMessage()));
            }
        });
    }

    public void updateSuggestions(short unmanned, SuggestionBatch batch, final Callback cb) {
        suggestionService.updateSuggestions(String.valueOf(unmanned), userId, batch, new Callback<SuggestionBatch>() {
            @Override
            public void success(SuggestionBatch result, Response response) {

                if(result.getError() != null) {
                    EventBus.getDefault().post(new ErrorEvent("Sorry!", result.getError().message));
                    return;
                }

                Log.d("Mtn.gs", "Suggestion batch updated successfully");

                // Null parameters because only information about successful request is needed
                cb.success(null, null);
            }

            @Override
            public void failure(RetrofitError error) {
                Log.e("Mtn.gs", error.getMessage());
                EventBus.getDefault().post(new ErrorEvent("Sorry!", error.getMessage()));
            }
        });
    }
}
