package gs.meetin.connector;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * Listener for android.intent.action.BOOT_COMPLETED.
 * Starts service on boot.
 */
public class AutoStart extends BroadcastReceiver
{
    public void onReceive(Context context, Intent i)
    {
        Intent serviceIntent = new Intent(context, ConnectorService.class);
        context.startService(serviceIntent);
        
    }
}
