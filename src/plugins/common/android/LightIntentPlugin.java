package ru.redspell.lightning.plugins;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import ru.redspell.lightning.LightActivity;

public abstract class LightIntentPlugin {
	protected boolean sendIntent(String pckg, Intent intent) {
		Context cntxt = LightActivity.instance.getApplicationContext();
		PackageManager pm = cntxt.getPackageManager();

		for (PackageInfo pi : pm.getInstalledPackages(0)) {
			if (pi.packageName.contentEquals(pckg)) {
				cntxt.startActivity(intent);
				return true;
			}
		}

		return false;
	}
}