package gs.meetin.connector;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

public class SessionManager {

    // Shared Preferences
    SharedPreferences pref;

    // Context
    Context context;

    // Shared pref mode
    int PRIVATE_MODE = 0;

    // Sharedpref file name
    private static final String PREF_NAME = "SwipeToMeetPref";

    // All Shared Preferences Keys
    public static final String KEY_USER_ID = "userId";
    public static final String KEY_TOKEN = "token";

    public SessionManager(Context context){
        this.context = context;
        pref = this.context.getSharedPreferences(PREF_NAME, PRIVATE_MODE);
    }

    public void signIn(String userId, String token) {
        Log.d("Mtn.gs", "Logging in");

        saveSessionData(userId, token);
    }

    public void signOut() {
        Log.d("Mtn.gs", "Logging out");

        clearSessionData();
    }

    private void saveSessionData(String userId, String token){
        SharedPreferences.Editor editor = pref.edit();

        editor.putString(KEY_USER_ID, userId);
        editor.putString(KEY_TOKEN, token);

        editor.commit();
    }

    private void clearSessionData() {
        SharedPreferences.Editor editor = pref.edit();

        editor.remove(KEY_USER_ID);
        editor.remove(KEY_TOKEN);

        editor.commit();
    }

    public String getUserId(){
        return pref.getString(KEY_USER_ID, null);
    }
    public String getToken(){
        return pref.getString(KEY_TOKEN, null);
    }
}
