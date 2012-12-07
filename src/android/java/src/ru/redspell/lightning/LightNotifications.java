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
	final public static String NOTIFICATION_TITLE_BUNDLE_KEY = "title";
	final public static String NOTIFICATION_MESSAGE_BUNDLE_KEY = "message";
	final public static String NOTIFICATION_ACTIVITY_BUNDLE_KEY = "activity";
	final public static String NOTIFICATION_ICON_BUNDLE_KEY = "icon";

	private static int notifIcon = -1;

	private static Uri makeIntentData(String notifId) {
		return (new Uri.Builder()).scheme("lightnotif").authority(LightView.instance.activity.getPackageName()).path(notifId).build();
	}

	private static AlarmManager getAlarmManager() {
		return (AlarmManager)LightView.instance.activity.getApplicationContext().getSystemService(Context.ALARM_SERVICE);
	}

	public static void scheduleNotification(String notifId, double fireDate, String message) {
		Activity activity = LightView.instance.activity;
		Intent intnt = new Intent(activity, LightNotificationsReceiver.class);

		intnt.putExtra(NOTIFICATION_MESSAGE_BUNDLE_KEY, message);
		intnt.putExtra(NOTIFICATION_ACTIVITY_BUNDLE_KEY, activity.getClass().getName());
		intnt.putExtra(NOTIFICATION_ICON_BUNDLE_KEY, notifIcon);
		intnt.setData(makeIntentData(notifId));

		PendingIntent pIntnt = PendingIntent.getBroadcast(activity.getApplicationContext(), (int)Calendar.getInstance().getTimeInMillis(), intnt, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager().set(AlarmManager.RTC_WAKEUP, (long)fireDate, pIntnt);
	}

	public static void cancelNotification(String notifId) {
		Log.d("LIGHTNING", "cancel call " + notifId);

		Activity activity = LightView.instance.activity;

		Intent intnt = new Intent(activity, LightNotificationsReceiver.class);
		intnt.setData(makeIntentData(notifId));

		PendingIntent pIntnt = PendingIntent.getBroadcast(activity.getApplicationContext(), (int)Calendar.getInstance().getTimeInMillis(), intnt, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager().cancel(pIntnt);
	}

	public static void setNotificationIcon(int notifIconResId) {
		notifIcon = notifIconResId;
	}	
}