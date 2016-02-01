package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;

import android.content.Intent;
import android.os.Bundle;
import android.os.Build;
import android.os.Build.VERSION;
import com.chartboost.sdk.Libraries.CBLogging.Level;
import com.chartboost.sdk.Model.CBError;
import com.chartboost.sdk.Model.CBError.CBClickError;
import com.chartboost.sdk.Model.CBError.CBImpressionError;
import com.chartboost.sdk.Tracking.CBAnalytics;
import com.chartboost.sdk.CBLocation;
import com.chartboost.sdk.CBImpressionActivity;
import com.chartboost.sdk.Chartboost;
import com.chartboost.sdk.ChartboostDelegate;

public class LightChartboost {
	public static void startSession(final String appId, final String appSig) {
		Log.d ("startSession app_id " + appId + " appSig = " +  appSig);

		Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
				public void onCreate(Bundle savedInstanceState) {}
				public void onStart() {
					Log.d("LIGHTNING", "onStart");
					Chartboost.onStart(Lightning.activity);
				}

				public void onResume() {
					Log.d("LIGHTNING", "onResume");
				 Chartboost.onResume(Lightning.activity);
				}

				public void onPause() {
					Log.d("LIGHTNING", "onPause");
				 Chartboost.onPause(Lightning.activity);
				}
				 
				public void onStop() {
					Log.d("LIGHTNING", "onStop");
				 Chartboost.onStop(Lightning.activity);
				}

				public void onDestroy() {
					Log.d("LIGHTNING", "onDestroy");
				 Chartboost.onDestroy(Lightning.activity);
				}
				public void onActivityResult(int requestCode, int resultCode, Intent data) {
				}

				public void onSaveInstanceState(Bundle outState) {}

				});



		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
/*
				Chartboost cb = Chartboost.sharedChartboost();
				cb.onCreate(LightActivity.instance, appId, appSig, null);
				cb.startSession();	
*/
/*
				ChartboostDelegate cb_delegate = new ChartboostDelegate() {
					//Override the Chartboost delegate callbacks you wish to track and control
					@Override
					public void didInitialize() {
						Log.d ("didInitialize");
						super.didInitialize ();
					}
				
					@Override
					public void	didFailToLoadInterstitial(java.lang.String location, CBError.CBImpressionError error) {
						Log.d ("didInitialize"  + location + " error : " + (error.toString ()));
						super.didFailToLoadInterstitial (location, error);
					}
				}; 
*/
				Log.d ("run");
				Log.d ("SDK_INT = " + Build.VERSION.SDK_INT);
				Log.d ("startSession app_id " + appId + " appSig = " +  appSig);
				Chartboost.startWithAppId(Lightning.activity, appId, appSig);
				Chartboost.setLoggingLevel(Level.ALL);
//				Chartboost.setDelegate(cb_delegate);
			//	Chartboost.setImpressionsUseActivities(boolean impressionsUseActivities) 
				Chartboost.onCreate(Lightning.activity);
				Chartboost.onStart(Lightning.activity);
				Chartboost.onResume(Lightning.activity);
				Log.d ("end RUN");
			}
		});
	}
}
