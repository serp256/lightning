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
import android.support.v4.app.NotificationCompat.WearableExtender;
import android.support.v4.app.NotificationCompat.Builder;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationManagerCompat;
import android.net.Uri;
public class GcmBroadcastReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
			Log.d("GcmBroadcastReceiver " + intent.toString());
			Bundle extras = intent.getExtras();
			GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(context);
			String messageType = gcm.getMessageType(intent);
			 if (!extras.isEmpty() && GoogleCloudMessaging.MESSAGE_TYPE_MESSAGE.equals(messageType)) {
				 Log.d("Extras: '" + extras.toString() + "'");
				 String from = extras.getString("from");
				 if (from.equals("google.com/iid")) {
					 Log.d("Maybe should obtain tokens again");
				 }
				 else {
					 String mid = extras.getString("id");
					 String msg = extras.getString("msg");
					 sendNotification(context,mid,null,msg,extras);
				 }
			 } else Log.d("Does not have extras or incorrect type");
			setResultCode(Activity.RESULT_OK);
    }

		private static Uri makeIntentData(Context context, String notifId) {
			Uri.Builder bldr = new Uri.Builder()
				.scheme("lightnotif")
				.authority(context.getPackageName())
				.path(notifId);

			return bldr.build();
		}

		private void sendNotification(Context context,String id, String title, String message, Bundle extras) {
			Log.d("sendNotification " + id);

			Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
			Log.d("OK");
			startIntent.putExtra("remoteNotification",id);

			PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);


			NotificationCompat.Builder notifBldr = new NotificationCompat.Builder(context)
					.setSmallIcon(R.drawable.notif_icon)
					.setContentTitle(title == null ? context.getPackageManager().getApplicationLabel(context.getApplicationInfo()) : title)
					.setContentText(message)
					.setContentIntent(pNotifIntnt)
					.setDefaults(android.app.Notification.DEFAULT_ALL)
			//		.extend(new WearableExtender().addAction(wearAction))
					.setAutoCancel(true);

			if (extras.getString("qa_url") != null) {
				/*WEARABLE*/
				Intent wearIntent = new Intent();
				String mPackage = context.getPackageName();
				String mClass = ".WearReceiver";
				try {
					wearIntent.setClass(context,Class.forName(mPackage+mClass));
				}
				catch (ClassNotFoundException exc) {
					Log.d ("LIGHTNING", "not found class " + mPackage+mClass);
				}
				wearIntent.setAction(ru.redspell.lightning.notifications.Notifications.CUSTOM_ACTION);
				wearIntent.setData(makeIntentData(context, id));
				wearIntent.putExtra ("id",id);
				wearIntent.putExtra ("wear_action_data",extras);

				PendingIntent pendingIntentWear = PendingIntent.getBroadcast(context,wearIntent.getDataString().hashCode(), wearIntent, PendingIntent.FLAG_UPDATE_CURRENT);

				String qa_msg = extras.getString("qa_msg","");
				NotificationCompat.Action wearAction = new NotificationCompat.Action.Builder(R.drawable.notif_icon, qa_msg, pendingIntentWear).build();
					notifBldr.extend(new WearableExtender().addAction(wearAction));
				/**/

			}

			NotificationManagerCompat notifMngr = NotificationManagerCompat.from(context);
			Log.d ("notify " + id.hashCode() + " " + (notifBldr == null? "null" : "not null"));
			notifMngr.notify(id.hashCode(), notifBldr.build());
		}
}
