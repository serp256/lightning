package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;

import android.content.Intent;
import android.os.Bundle;

import com.fyber.ads.videos.RewardedVideoActivity;

import com.fyber.*;
import com.fyber.ads.*;
//import com.sponsorpay.publisher.SponsorPayPublisher;
//import com.sponsorpay.publisher.mbe.SPBrandEngageRequestListener;
//import com.sponsorpay.publisher.mbe.SPBrandEngageClient;
import com.fyber.ads.AdFormat;
import com.fyber.exceptions.IdException;
import com.fyber.reporters.InstallReporter;
import com.fyber.reporters.RewardedActionReporter;
import com.fyber.requesters.RequestCallback;
import com.fyber.requesters.RequestError;
import com.fyber.requesters.RewardedVideoRequester;
import com.fyber.requesters.VirtualCurrencyCallback;
import com.fyber.requesters.VirtualCurrencyRequester;
import com.fyber.utils.FyberLogger;

import org.androidannotations.annotations.*;
import org.androidannotations.annotations.res.*;
import com.fyber.annotations.FyberSDK;
import com.fyber.mediation.*;
import com.unity3d.ads.android.*;

  @FyberSDK
public class LightSponsorpay {
	private static String appId;
	private static String userId;
	private static String securityToken;
	private static int request_callback;
	private static int show_callback;
	private static int REWARDED_VIDEO_REQUEST_CODE = 271015;
	private static Intent mIntent;

	public static void init(String _appId, String _userId, String _securityToken,final boolean enableLog) {
		appId = _appId;
		userId = _userId;
		securityToken = _securityToken;

		Log.d ("LIGHTNING","SponsorPay init, enableLog: " + enableLog);

		Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
						public void onCreate(Bundle savedInstanceState) {}

						public void onStart () {}

						public void onResume() {}

						public void onActivityResult(int requestCode, int resultCode, Intent data) {
								Log.d("LIGHTNING", "sponsorpay onActivityResult");
								if (resultCode == android.app.Activity.RESULT_OK && requestCode == REWARDED_VIDEO_REQUEST_CODE) {
									String engagementResult = data.getStringExtra(RewardedVideoActivity.ENGAGEMENT_STATUS);
									Log.d ("LIGHTNING","engagement result:" + engagementResult);
									boolean completeFlag = (engagementResult.equals(RewardedVideoActivity.REQUEST_STATUS_PARAMETER_FINISHED_VALUE));
									Log.d ("LIGHTNING","flag:" + completeFlag);
									(new CamlParamCallbackInt(show_callback,completeFlag)).run();
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
					Fyber.with(appId, Lightning.activity)
			        .withUserId(userId)
			        .withSecurityToken(securityToken)
			        .start();  

		      FyberLogger.enableLogging(enableLog);
					UnityAds.setDebugMode(enableLog);
					UnityAds.setTestMode(enableLog);

				} catch (java.lang.RuntimeException exc) {
					Log.d ("LIGHTNING",exc.getLocalizedMessage());
				}
			}
		});
		
	}

	public static void showOffers() {
		Log.d ("LIGHTNING","SponsorPay showOffers");
		/*
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Intent offerWallIntent = SponsorPayPublisher.getIntentForOfferWallActivity(Lightning.activity.getApplicationContext(), false);
				Lightning.activity.startActivityForResult(offerWallIntent, 0xff);
			}
		});
		*/
	}

	public static void requestVideos (int cb) {
		Log.d ("LIGHTNING","SponsorPay requestVideos!!");
		request_callback = cb;
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
			RewardedVideoRequester.create(
				new RequestCallback () {
					@Override
					public void onRequestError(RequestError requestError) {
								Log.d("LIGHTNING", "Something went wrong with the request: " + requestError.getDescription());
								/*
								if (request_callback != -1) {(new CamlParamCallbackInt(request_callback,false)).run();}
								request_callback = -1;
								*/
					}

					@Override
						public void onAdAvailable(Intent intent) {
									Log.d("LIGHTNING", "Ad is available");
									mIntent = intent;
									if (request_callback != -1) {(new CamlParamCallbackInt(request_callback,true)).run();}
									request_callback = -1;
						}

					@Override
						public void onAdNotAvailable(AdFormat adFormat) {
									Log.d("LIGHTNING", "No ad available");
									if (request_callback != -1) {(new CamlParamCallbackInt(request_callback,false)).run();}
									request_callback = -1;
						}
				}
			
				).request(Lightning.activity.getApplicationContext());
			}
		});
		/*
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				LightSPBERequestListener splistener = new LightSPBERequestListener ();
				SponsorPayPublisher.getIntentForMBEActivity(Lightning.activity, splistener);
			}
		});
		*/
  }

	public static void showVideos (int cb) {
		Log.d ("LIGHTNING","SponsorPay showVideos");
		show_callback = cb;
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				if (mIntent != null) {
					Lightning.activity.startActivityForResult(mIntent, REWARDED_VIDEO_REQUEST_CODE);
					mIntent = null;
				}
				else
				{
					Log.d ("LIGHTNING","no_videos");
					(new CamlParamCallbackInt(show_callback,false)).run();
				}
			}
		});
  }

	/* LISTENER */
	/*
	private static class LightSPBERequestListener implements SPBrandEngageRequestListener {
		@Override
			public void onSPBrandEngageOffersAvailable(Intent spBrandEngageActivity) {
						Log.d("LIGHTNING", "SPBrandEngage - intent available cb");
								mIntent = spBrandEngageActivity;
								(new CamlParamCallbackInt(request_callback,true)).run();
			}

		@Override
			public void onSPBrandEngageOffersNotAvailable() {
						Log.d("LIGHTNING", "SPBrandEngage - no offers for the moment");
								mIntent = null;
								if (request_callback != -1) {(new CamlParamCallbackInt(request_callback,false)).run();}
								request_callback = -1;
			}

		@Override
			public void onSPBrandEngageError(String errorMessage) {
						Log.d("LIGHTNING", "SPBrandEngage - an error occurred:\n" + errorMessage);
								mIntent = null;
								if (request_callback != -1) {(new CamlParamCallbackInt(request_callback,false)).run();}
								request_callback = -1;
			}
	}
	*/

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
