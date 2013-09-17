package ru.redspell.lightning.plugins;

import ru.redspell.lightning.R;
import ru.redspell.lightning.utils.Log;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Bundle;
import com.google.android.gms.gcm.GoogleCloudMessaging;
import android.app.PendingIntent;
import android.support.v4.app.NotificationCompat;
import android.app.NotificationManager;

public class GcmBroadcastReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
			Log.d("GcmBroadcastReceiver " + intent.toString());
			Bundle extras = intent.getExtras();
			GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(context);
			String messageType = gcm.getMessageType(intent);
			 if (!extras.isEmpty() && GoogleCloudMessaging.MESSAGE_TYPE_MESSAGE.equals(messageType)) {
				 Log.d("Extras: '" + extras.toString() + "'");
				 String mid = extras.getString("id");
				 String msg = extras.getString("msg");
				 sendNotification(context,mid,null,msg);
			 } else Log.d("Does not have extras or incorrect type");
			setResultCode(Activity.RESULT_OK);
    }

		private void sendNotification(Context context,String id, String title, String message) {
			Log.d("sendNotification");

			Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
			startIntent.putExtra("remoteNotification",id);

			PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);
			NotificationCompat.Builder notifBldr = new NotificationCompat.Builder(context)
					.setSmallIcon(R.drawable.notif_icon)
					.setContentTitle(title == null ? context.getPackageManager().getApplicationLabel(context.getApplicationInfo()) : title)
					.setContentText(message)
					.setContentIntent(pNotifIntnt)
					.setDefaults(android.app.Notification.DEFAULT_ALL)
					.setAutoCancel(true);

			NotificationManager notifMngr = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
			notifMngr.notify(id.hashCode(), notifBldr.build());		
		}
}
