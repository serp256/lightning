package ru.redspell.lightning.expansions;

import com.google.android.vending.expansion.downloader.DownloaderClientMarshaller;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager.NameNotFoundException;

public class LightExpansionsAlarmReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            DownloaderClientMarshaller.startDownloadServiceIfRequired(context, intent, LightExpansionsDownloadService.class);
        } catch (NameNotFoundException e) {
            e.printStackTrace();
        }
    }
}