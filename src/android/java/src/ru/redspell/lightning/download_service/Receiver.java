package ru.redspell.lightning.download_service;
import ru.redspell.lightning.Lightning;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import android.app.DownloadManager;
import ru.redspell.lightning.utils.Log;

public class Receiver extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			Log.d ("LIGHTNING","onReceive "+ action);
				if (DownloadManager.ACTION_NOTIFICATION_CLICKED.equals(action)) {
					Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
					context.startActivity(startIntent);
				}
		}
}
