package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.chartboost.sdk.Chartboost;

public class LightChartboost {
	public static void startSession(final String appId, final String appSig) {
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
