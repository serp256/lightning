package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.supersonicads.sdk.android.SupersonicAdsPublisherAgent;

public class LightSupersonic {
	private static String appKey;
	private static String appUid;

	public static void init(String _appKey, String _appUid) {
		appKey = _appKey;
		appUid = _appUid;
	}

	public static void showOfferts() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				SupersonicAdsPublisherAgent adsAgnt = SupersonicAdsPublisherAgent.getInstance();
				adsAgnt.showOfferWall(LightActivity.instance.getApplicationContext(), appKey, appUid, null);
			}
		});
	}
}