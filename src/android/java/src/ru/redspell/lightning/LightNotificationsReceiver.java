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
    public void onReceive(Context context, android.content.Intent intent) {
        String action = intent.getAction();

        if (action != null && action.contentEquals("android.intent.action.BOOT_COMPLETED")) {
            Log.d("LIGHTNING", "boot compeleted");
            LightActivity.rescheduleNotifications(context);

            return;
        }

        Log.d("LIGHTNING", "LightNotificationReceiver onReceive " + LightActivity.isRunning);

        Bundle intntExtras = intent.getExtras();
        LightActivity.removeNotification(context, intntExtras.getString(LightNotifications.NOTIFICATION_ID_KEY),
            intntExtras.getDouble(LightNotifications.NOTIFICATION_FIREDATE_KEY), intntExtras.getString(LightNotifications.NOTIFICATION_MESSAGE_KEY));

        if (LightActivity.isRunning) return;

        PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, context.getPackageManager().getLaunchIntentForPackage(context.getPackageName()), PendingIntent.FLAG_UPDATE_CURRENT);

        String title = intntExtras.getString(LightNotifications.NOTIFICATION_TITLE_KEY);
        String message = intntExtras.getString(LightNotifications.NOTIFICATION_MESSAGE_KEY);
        if (message != null) {
            NotificationCompat.Builder notifBldr = new NotificationCompat.Builder(context)
                .setSmallIcon(R.drawable.notif_icon)
                .setContentTitle(title == null ? context.getPackageManager().getApplicationLabel(context.getApplicationInfo()) : title)
                .setContentText(intntExtras.getString("message"))
                .setContentIntent(pNotifIntnt);

            NotificationManager notifMngr = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
            notifMngr.notify(intent.getDataString().hashCode(), notifBldr.build());                
        } else {
            Log.e("LIGHTNING", "Notification message not specified, notification was not fired");
        }
    }
}