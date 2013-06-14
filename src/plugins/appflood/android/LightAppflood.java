package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.appflood.AppFlood;
import com.appflood.AppFlood.AFEventDelegate;
import com.appflood.AppFlood.AFRequestDelegate;

public class LightAppflood {
	private static String appKey;
	private static String secKey;

	public static void init(String _appKey, String _secKey) {
		appKey = _appKey;
		secKey = _secKey;
	}

	public static void startSession() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				AppFlood.initialize(LightActivity.instance, appKey, secKey, AppFlood.AD_NONE);
			}
		});
	}
}
