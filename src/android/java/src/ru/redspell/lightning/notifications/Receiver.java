package ru.redspell.lightning.notifications;

import android.app.ActivityManager;
import android.app.NotificationManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import java.util.List;

import ru.redspell.lightning.utils.Log;

public class Receiver extends BroadcastReceiver {
    /* When application not running and receiver fired, using of Lightning.activity.isRunning cause static section of Lightning class to run,
     * where activity does not exists, exception thrown and loading of library is failed. When user touch notification and application starts,
     * static section of Lightning class not run and library with native methods still not loaded. It cause to unsatisfied methods exceptions.
     * Therefore Receiver uses its own flag to determine is app running or not. 
     */
    public static boolean appRunning = false;

    public void onReceive(Context context, android.content.Intent intent) {
        String action = intent.getAction();

        if (action != null && action.contentEquals("android.intent.action.BOOT_COMPLETED")) {
            Notifications.rescheduleNotifications(context);
            return;
        }

        Bundle intntExtras = intent.getExtras();
				String nid = intntExtras.getString(Notifications.NOTIFICATION_ID);
        String title = intntExtras.getString(Notifications.NOTIFICATION_TITLE);
        String message = intntExtras.getString(Notifications.NOTIFICATION_MESSAGE);

        Notifications.unlogNotification(context, nid, intntExtras.getDouble(Notifications.NOTIFICATION_FIREDATE), message);

        if (appRunning) return;

        if (message != null) {
            Notifications.showNotification(context, nid, title, message);
        } else {
            Log.e("LIGHTNING", "Notification message not specified, notification was not fired");
        }
    }
}
