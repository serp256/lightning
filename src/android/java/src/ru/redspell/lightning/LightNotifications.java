package ru.redspell.lightning;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.support.v4.app.NotificationCompat;

import java.util.ArrayList;
import java.util.Calendar;

import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.utils.Log;

public class LightNotifications {
	public static final String NOTIFICATION_TITLE = "title";
	public static final String NOTIFICATION_MESSAGE = "message";
	public static final String NOTIFICATION_FIREDATE = "firedate";
	public static final String NOTIFICATION_ID = "id";

	public static final String NOTIFICATIONS_SHARED_PREF = "notifications";

	public static boolean groupNotifications = false;

	// data required for cancel intent throught filterIntent
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
		Context context = LightActivity.instance.getApplicationContext();
		logNotification(context, notifId, fireDate, message);
		scheduleNotification(context, notifId, fireDate, message);
	}
	
	public static void scheduleNotification(Context context, String notifId, double fireDate, String message) {
		Intent scheduleIntent = new Intent(context, LightNotificationsReceiver.class);

		scheduleIntent.putExtra(NOTIFICATION_ID, notifId);
		scheduleIntent.putExtra(NOTIFICATION_FIREDATE, fireDate);
		scheduleIntent.putExtra(NOTIFICATION_MESSAGE, message);
		scheduleIntent.setData(makeIntentData(context, notifId));

		PendingIntent pScheduleIntent = PendingIntent.getBroadcast(context, scheduleIntent.getDataString().hashCode(), scheduleIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager(context).set(AlarmManager.RTC_WAKEUP, (long)fireDate, pScheduleIntent);
	}

	public static void cancelNotification(String notifId) {
		Context context = LightView.instance.activity.getApplicationContext();
		unlogNotification(context, notifId);
		
		Intent cancelIntent = new Intent(context, LightNotificationsReceiver.class);
		cancelIntent.setData(makeIntentData(context, notifId));

		PendingIntent pCancelIntent = PendingIntent.getBroadcast(context, cancelIntent.getDataString().hashCode(), cancelIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		getAlarmManager(context).cancel(pCancelIntent);
	}

	public static void logNotification(Context context, String notifId, double fireDate, String message) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences(NOTIFICATIONS_SHARED_PREF, Context.MODE_PRIVATE);

			JSONObject jsonNotif = new JSONObject()
				.put("id", notifId)
				.put("fd", fireDate)
				.put("mes", message);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString(NOTIFICATIONS_SHARED_PREF, "[]"))
				.put(jsonNotif);

			notifSharedPrefs.edit().putString(NOTIFICATIONS_SHARED_PREF, jsonNotifs.toString()).commit();
		} catch (org.json.JSONException e) {
			Log.d("LIGHTNING", "logNotification json error");
		}
	}

	private interface NotificationComparer {
		public boolean equal(JSONObject jsonNotif, String notifId, double fireDate, String message) throws JSONException;
	}

	public static void unlogNotification(Context context, String notifId) {
		unlogNotification(context, notifId, 0, "", new NotificationComparer() {
			public boolean equal(JSONObject jsonNotif, String notifId, double fireDate, String message) throws JSONException {
				return jsonNotif.getString("id").contentEquals(notifId);
			}
		});
	}

	public static void unlogNotification(Context context, String notifId, double fireDate, String message) {
		unlogNotification(context, notifId, fireDate, message, new NotificationComparer() {
			public boolean equal(JSONObject jsonNotif, String notifId, double fireDate, String message) throws JSONException {
				return jsonNotif.getString("id").contentEquals(notifId) && jsonNotif.getDouble("fd") == fireDate && jsonNotif.getString("mes").contentEquals(message);
			}
		});
	}	

	public static void unlogNotification(Context context, String notifId, double fireDate, String message, NotificationComparer comparer) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences(NOTIFICATIONS_SHARED_PREF, Context.MODE_PRIVATE);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString(NOTIFICATIONS_SHARED_PREF, "[]"));
			ArrayList<JSONObject> notifs = new ArrayList<JSONObject>();

			for (int i = 0; i < jsonNotifs.length(); i++) {
				JSONObject jsonNotif = jsonNotifs.getJSONObject(i);

				if (!comparer.equal(jsonNotif, notifId, fireDate, message)) {
					notifs.add(jsonNotif);
				}
			}

			notifSharedPrefs.edit().putString(NOTIFICATIONS_SHARED_PREF, new JSONArray(notifs).toString()).commit();
		} catch (JSONException e) {
			Log.d("LIGHTNING", "unlogNotification json error");
		}
	}

	public static void rescheduleNotifications(Context context) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences(NOTIFICATIONS_SHARED_PREF, Context.MODE_PRIVATE);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString(NOTIFICATIONS_SHARED_PREF, "[]"));
			ArrayList<JSONObject> notifs = new ArrayList<JSONObject>();
			Double now = (double)java.util.Calendar.getInstance().getTimeInMillis();

			for (int i = 0; i < jsonNotifs.length(); i++) {
				JSONObject jsonNotif = jsonNotifs.getJSONObject(i);
				Double fireDate = jsonNotif.getDouble("fd");

				if (fireDate > now) {
					LightNotifications.scheduleNotification(context, jsonNotif.getString("id"), fireDate, jsonNotif.getString("mes"));
					notifs.add(jsonNotif);
				} else {
					LightNotifications.showNotification(context, jsonNotif.getString("id"), null, jsonNotif.getString("mes"));
				}
			}
			
			notifSharedPrefs.edit().putString(NOTIFICATIONS_SHARED_PREF, new JSONArray(notifs).toString()).commit();
		} catch (org.json.JSONException e) {
			Log.d("LIGHTNING", "rescheduleNotifications json error ");
		}
	}

	public static void showNotification(Context context, String id, String title, String message) {
		Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
		startIntent.putExtra("localNotification",id);

		PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        NotificationCompat.Builder notifBldr = new NotificationCompat.Builder(context)
            .setSmallIcon(R.drawable.notif_icon)
            .setContentTitle(title == null ? context.getPackageManager().getApplicationLabel(context.getApplicationInfo()) : title)
            .setContentText(message)
            .setContentIntent(pNotifIntnt)
            .setAutoCancel(true);

        NotificationManager notifMngr = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
        notifMngr.notify(id.hashCode(), notifBldr.build());		
	}
}
