package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
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

		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				SponsorPay.start(appId, userId, securityToken, Lightning.activity.getApplicationContext());
			}
		});
		
	}

	public static void showOfferts() {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Lightning.activity.startActivityForResult(SponsorPayPublisher.getIntentForOfferWallActivity(Lightning.activity, false), 0xff);
			}
		});
	}
}
