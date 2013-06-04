package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.sponsorpay.sdk.android.SponsorPay;
import com.sponsorpay.sdk.android.publisher.SponsorPayPublisher;

public class LightSponsorpay {
	private static String appId;
	private static String userId;
	private static String securityToken;

	public static void init(String _appId, String _userId, String _securityToken) {
		appId = _appId;
		userId = _userId;
		securityToken = _securityToken;

		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				SponsorPay.start(appId, userId, securityToken, LightActivity.instance.getApplicationContext());
			}
		});
		
	}

	public static void showOfferts() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				LightActivity.instance.startActivityForResult(SponsorPayPublisher.getIntentForOfferWallActivity(LightActivity.instance, false), 0xff);
			}
		});
	}
}
