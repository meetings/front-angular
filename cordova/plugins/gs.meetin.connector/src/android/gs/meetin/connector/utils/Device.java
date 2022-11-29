package gs.meetin.connector.utils;

import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;

public class Device {

    public static String getDeviceName() {
        return String.format("%s %s", Build.MANUFACTURER, Build.MODEL);
    }

    public static String getAndroidId(ContentResolver cr) {
        return Settings.Secure.getString(cr, Settings.Secure.ANDROID_ID);
    }

    public static String appVersion(Context context) {
        String appVersion = "dev";

        try {
            PackageInfo pInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
            appVersion = pInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            // Keep appVersion as "dev"
        }

        return appVersion;
    }
}
