package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.supersonicads.sdk.android.SupersonicAdsPublisherAgent;

public class LightSupersonic {
	public static void showOfferts(String appKey, String appUid) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				SupersonicAdsPublisherAgent adsAgnt = SupersonicAdsPublisherAgent.getInstance();
				adsAgnt.showOfferWall(LightActivity.instance.getApplicationContext(), appKey, appUid, null);
			}
		});
	}
}
