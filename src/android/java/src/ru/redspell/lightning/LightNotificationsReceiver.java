package ru.redspell.lightning;

import android.app.ActivityManager;
import android.app.NotificationManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.support.v4.app.NotificationCompat;
import android.os.Bundle;

import java.util.List;

import ru.redspell.lightning.utils.Log;

public class LightNotificationsReceiver extends BroadcastReceiver {
	private static boolean activityIsRunning(Context context, String activityClsName) {		
		ActivityManager activityManager = (ActivityManager)context.getSystemService(Context.ACTIVITY_SERVICE);
		List<ActivityManager.RunningTaskInfo> tasks = activityManager.getRunningTasks(Integer.MAX_VALUE);

	    for (ActivityManager.RunningTaskInfo task : tasks) {
	        if (activityClsName.equalsIgnoreCase(task.baseActivity.getClassName())) {
	        	return true;
	        } 
	    }

	    return false;
	}

	public void onReceive(Context context, android.content.Intent intent) {
		Log.d("LIGHTNING", "LightNotificationReceiver onReceive " + context.getClass().getName());

		try {
			Log.d("LIGHTNING", "intent.getExtras().getString(activity) " + intent.getExtras().getString("activity"));

			Bundle intntExtras = intent.getExtras();

			Log.d("LIGHTNING", "activityIsRunning " + activityIsRunning(context, intntExtras.getString(LightNotifications.NOTIFICATION_ACTIVITY_BUNDLE_KEY)));

			Intent intnt = new Intent(context, context.getClassLoader().loadClass(intntExtras.getString(LightNotifications.NOTIFICATION_ACTIVITY_BUNDLE_KEY)));
			PendingIntent pIntnt = PendingIntent.getActivity(context, 0, intnt, PendingIntent.FLAG_UPDATE_CURRENT);

			String title = intntExtras.getString(LightNotifications.NOTIFICATION_TITLE_BUNDLE_KEY);
			String message = intntExtras.getString(LightNotifications.NOTIFICATION_MESSAGE_BUNDLE_KEY);
			int notifIconResId = intntExtras.getInt(LightNotifications.NOTIFICATION_ICON_BUNDLE_KEY);

			if (notifIconResId >= 0 && message != null) {
				NotificationCompat.Builder notifBldr = new NotificationCompat.Builder(context)
			        .setSmallIcon(notifIconResId)
			        .setContentTitle(title == null ? context.getPackageManager().getApplicationLabel(context.getApplicationInfo()) : title)
			        .setContentText(intntExtras.getString("message"))
			        .setContentIntent(pIntnt);

				NotificationManager notifMngr = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
				notifMngr.notify(0, notifBldr.build());				
			} else {
				Log.e("LIGHTNING", "Notification icon resource id or message not specified, notification was not fired");
			}
		} catch (java.lang.ClassNotFoundException e) {
			Log.d("LIGHTNING", "activity class not found");
		}
	}
}