package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.chartboost.sdk.Chartboost;

public class LightChartboost {
	private static String appId;
	private static String appSig;

	public static void init(String _appId, String _appSig) {
		appId = _appId;
		appSig = _appSig;
	}

	public static void startSession() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Chartboost cb = Chartboost.sharedChartboost();
				cb.onCreate(LightActivity.instance, appId, appSig, null);
				cb.startSession();
			}
		});
	}
}