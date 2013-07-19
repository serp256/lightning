package ru.redspell.lightning.plugins;

import android.util.Log;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;

import ru.redspell.lightning.LightActivity;

public class LightInstagram {
	public static boolean post(String fname, String text) {
		Context cntxt = LightActivity.instance.getApplicationContext();
		PackageManager pm = cntxt.getPackageManager();

		for (PackageInfo pi : pm.getInstalledPackages(0)) {
			if (pi.packageName.contentEquals("com.instagram.android")) {
				Intent intent = new Intent(Intent.ACTION_SEND);
				intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
				intent.setType("image/*");
				intent.putExtra(Intent.EXTRA_STREAM, Uri.parse("file://" + text));

				intent.setPackage("com.instagram.android");
				cntxt.startActivity(intent);

				return true;
			}
		}

		return false;
	}
}