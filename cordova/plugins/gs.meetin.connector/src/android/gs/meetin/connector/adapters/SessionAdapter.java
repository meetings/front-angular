package gs.meetin.connector.adapters;

import com.google.gson.FieldNamingPolicy;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import gs.meetin.connector.AppConfig;
import retrofit.RequestInterceptor;
import retrofit.RestAdapter;
import retrofit.converter.GsonConverter;

public class SessionAdapter {

    public static RestAdapter build (final String userId, final String token, final String appVersion) {
        Gson gson = new GsonBuilder()
                .setFieldNamingPolicy(FieldNamingPolicy.LOWER_CASE_WITH_UNDERSCORES)
                .create();

        return new RestAdapter.Builder()
                .setRequestInterceptor(new RequestInterceptor() {
                    @Override
                    public void intercept(RequestFacade request) {
                        request.addHeader("user_id", userId);
                        request.addHeader("dic", token);
                        request.addHeader("User-Agent", System.getProperty( "http.agent" ));
                        request.addHeader("x-expect-http-errors-for-rest", "1");
                        request.addHeader("x-meetings-app-version", appVersion + " Android Connector");
                    }
                })
                .setConverter(new GsonConverter(gson))
                .setEndpoint(AppConfig.getInstance().getApiBaseURL())
                .build();
    }
}
