package ru.redspell.lightning;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import java.util.Calendar;

import ru.redspell.lightning.LightView;
import ru.redspell.lightning.utils.Log;

import android.app.NotificationManager;
import android.app.Notification;

public class LightNotifications {
	final public static String NOTIFICATION_TITLE_KEY = "title";
	final public static String NOTIFICATION_MESSAGE_KEY = "message";
	final public static String NOTIFICATION_FIREDATE_KEY = "firedate";
	final public static String NOTIFICATION_ID_KEY = "id";

	public static boolean groupNotifications = false;

	private static Intent intent;

	private static Uri makeIntentData(Context context, String notifId) {
		Uri.Builder bldr = new Uri.Builder()
			.scheme("lightnotif")
			.authority(context.getPackageName())
			.path(notifId);

		return bldr.build();
	}

	private static AlarmManager getAlarmManager(Context context) {
		return (AlarmManager)context.getSystemService(Context.ALARM_SERVICE);
	}

	public static void scheduleNotification(String notifId, double fireDate, String message) {
		Context context = LightView.instance.activity.getApplicationContext();
		LightActivity.addNotification(context, notifId, fireDate, message);
		scheduleNotification(context, notifId, fireDate, message);
	}
	
	public static void scheduleNotification(Context context, String notifId, double fireDate, String message) {
		Intent intnt = new Intent(context, LightNotificationsReceiver.class);

		intnt.putExtra(NOTIFICATION_ID_KEY, notifId);
		intnt.putExtra(NOTIFICATION_FIREDATE_KEY, fireDate);
		intnt.putExtra(NOTIFICATION_MESSAGE_KEY, message);
		intnt.setData(makeIntentData(context, notifId));

		intent = intnt;

		PendingIntent pIntnt = PendingIntent.getBroadcast(context, intnt.getDataString().hashCode(), intnt, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager(context).set(AlarmManager.RTC_WAKEUP, (long)fireDate, pIntnt);
	}

	public static void cancelNotification(String notifId) {
		Log.d("LIGHTNING", "cancel call " + notifId);

		Context context = LightView.instance.activity.getApplicationContext();
		LightActivity.removeNotification(context, notifId);
		
		Intent intnt = new Intent(context, LightNotificationsReceiver.class);
		intnt.setData(makeIntentData(context, notifId));

		PendingIntent pIntnt = PendingIntent.getBroadcast(context, intnt.getDataString().hashCode(), intnt, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager(context).cancel(pIntnt);
	}
}