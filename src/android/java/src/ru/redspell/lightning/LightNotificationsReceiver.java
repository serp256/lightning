package ru.redspell.lightning;

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

public class LightNotificationsReceiver extends BroadcastReceiver {
    public void onReceive(Context context, android.content.Intent intent) {
        String action = intent.getAction();

        if (action != null && action.contentEquals("android.intent.action.BOOT_COMPLETED")) {
            LightNotifications.rescheduleNotifications(context);
            return;
        }

        Bundle intntExtras = intent.getExtras();
        LightNotifications.unlogNotification(context, intntExtras.getString(LightNotifications.NOTIFICATION_ID),
            intntExtras.getDouble(LightNotifications.NOTIFICATION_FIREDATE), intntExtras.getString(LightNotifications.NOTIFICATION_MESSAGE));

        if (LightActivity.isRunning) return;

        String title = intntExtras.getString(LightNotifications.NOTIFICATION_TITLE);
        String message = intntExtras.getString(LightNotifications.NOTIFICATION_MESSAGE);
        if (message != null) {
            LightNotifications.showNotification(context, intent.getData(), title, message);
        } else {
            Log.e("LIGHTNING", "Notification message not specified, notification was not fired");
        }
    }
}