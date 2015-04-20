package ru.redspell.lightning.download_service;
import ru.redspell.lightning.Lightning;

import android.app.ActivityManager;
import android.app.NotificationManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import android.app.DownloadManager;

import java.util.List;

import ru.redspell.lightning.utils.Log;

import ru.redspell.lightning.R;
import android.support.v4.app.NotificationCompat;
public class Receiver extends BroadcastReceiver {
    /* When application not running and receiver fired, using of Lightning.activity.isRunning cause static section of Lightning class to run,
     * where activity does not exists, exception thrown and loading of library is failed. When user touch notification and application starts,
     * static section of Lightning class not run and library with native methods still not loaded. It cause to unsatisfied methods exceptions.
     * Therefore Receiver uses its own flag to determine is app running or not. 
     */

		@Override
		public void onReceive(Context context, Intent intent) {
				String action = intent.getAction();
			Log.d ("LIGHTNING","onReceive "+ action);
				if (DownloadManager.ACTION_NOTIFICATION_CLICKED.equals(action)) {
					Log.d ("LIGHTNING","PIZDA");
					Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
					context.startActivity(startIntent);
				}
				else if (DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(action)) {
Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());

    PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);
					NotificationManager notificationManager = (NotificationManager) Lightning.activity.getSystemService(Context.NOTIFICATION_SERVICE);
					NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(context);
					mBuilder.setContentTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()))
						.setContentText("Download completed")
						.setContentIntent(pNotifIntnt)
						.setSmallIcon(R.drawable.notif_icon);
					notificationManager.notify(11, mBuilder.build());
}}
}
