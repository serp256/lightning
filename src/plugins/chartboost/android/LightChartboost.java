package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;

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
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
/*
				Chartboost cb = Chartboost.sharedChartboost();
				cb.onCreate(LightActivity.instance, appId, appSig, null);
				cb.startSession();	
*/
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
				Log.d ("run");
				Log.d ("SDK_INT = " + Build.VERSION.SDK_INT);
				Log.d ("startSession app_id " + appId + " appSig = " +  appSig);
				Chartboost.startWithAppId(Lightning.activity, appId, appSig);
				Chartboost.setLoggingLevel(Level.ALL);
			//	Chartboost.setDelegate(cb_delegate);
			//	Chartboost.setImpressionsUseActivities(boolean impressionsUseActivities) 
				Chartboost.onCreate(Lightning.activity);
				Log.d ("end RUN");
			}
		});
	}
}
