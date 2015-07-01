package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;

import android.content.Intent;
import android.os.Bundle;

import com.sponsorpay.SponsorPay;
import com.sponsorpay.publisher.SponsorPayPublisher;
import com.sponsorpay.publisher.mbe.SPBrandEngageRequestListener;
import com.sponsorpay.publisher.mbe.SPBrandEngageClient;


public class LightSponsorpay {
	private static String appId;
	private static String userId;
	private static String securityToken;
	private static int callback;

	public static void init(String _appId, String _userId, String _securityToken,final boolean enableLog) {
		appId = _appId;
		userId = _userId;
		securityToken = _securityToken;

		Log.d ("LIGHTNING","SponsorPay init");

		Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
						public void onCreate(Bundle savedInstanceState) {}

						public void onResume() {}

						public void onActivityResult(int requestCode, int resultCode, Intent data) {
								Log.d("LIGHTNING", "sponsorpay onActivityResult");
								if (resultCode == android.app.Activity.RESULT_OK && requestCode == 290615) {
									String engagementResult = data.getStringExtra(SPBrandEngageClient.SP_ENGAGEMENT_STATUS);
									Log.d ("LIGHTNING","engagement result:" + engagementResult);
									boolean completeFlag = (engagementResult.equals(com.sponsorpay.publisher.mbe.SPBrandEngageClient.SP_REQUEST_STATUS_PARAMETER_FINISHED_VALUE));
									Log.d ("LIGHTNING","flag:" + completeFlag);
									(new CamlParamCallbackInt(callback,completeFlag)).run();
								}
						}

						public void onSaveInstanceState(Bundle outState) {}
						public void onPause() {}
						public void onStop() {}
						public void onDestroy() {}
				});


		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				try {
					SponsorPay.start(appId, userId, securityToken, Lightning.activity);
					com.sponsorpay.utils.SponsorPayLogger.enableLogging(enableLog);
					Log.d ("LIGHTNING", "is logging" + com.sponsorpay.utils.SponsorPayLogger.isLogging ());
				} catch (java.lang.RuntimeException exc) {
					Log.d ("LIGHTNING",exc.getLocalizedMessage());
				}
			}
		});
		
	}

	public static void showOffers() {
		Log.d ("LIGHTNING","SponsorPay showOffers");
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Intent offerWallIntent = SponsorPayPublisher.getIntentForOfferWallActivity(Lightning.activity.getApplicationContext(), false);
				Lightning.activity.startActivityForResult(offerWallIntent, 0xff);
			}
		});
	}

	public static void requestVideos (int cb) {
		Log.d ("LIGHTNING","SponsorPay requestVideos");
		callback = cb;
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				LightSPBERequestListener splistener = new LightSPBERequestListener ();
				SponsorPayPublisher.getIntentForMBEActivity(Lightning.activity, splistener);
			}
		});
  }

	/* LISTENER */
	private static class LightSPBERequestListener implements SPBrandEngageRequestListener {
		private Intent mIntent;
		@Override
			public void onSPBrandEngageOffersAvailable(Intent spBrandEngageActivity) {
						Log.d("LIGHTNING", "SPBrandEngage - intent available");
								mIntent = spBrandEngageActivity;
								Lightning.activity.startActivityForResult(mIntent, 290615);
			}

		@Override
			public void onSPBrandEngageOffersNotAvailable() {
						Log.d("LIGHTNING", "SPBrandEngage - no offers for the moment");
								mIntent = null;
			}

		@Override
			public void onSPBrandEngageError(String errorMessage) {
						Log.d("LIGHTNING", "SPBrandEngage - an error occurred:\n" + errorMessage);
								mIntent = null;
			}
	}

	private static class CamlParamCallbackInt implements Runnable {
			protected int callback;
			protected boolean flag;

			public CamlParamCallbackInt (int callback, boolean flag) {
					this.callback = callback;
					this.flag = flag;
			}

			@Override
			public native void run();
	}
}
