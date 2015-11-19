package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;

import com.appsflyer.AppsFlyerLib;
import com.appsflyer.*;
import java.util.HashMap;
import java.util.Map;
import java.lang.Float;

public class LightAppsflyer {
	static String tapjoyEvent = "tapjoy_action";

	public static void trackPurchase (final String content_id, final String currency, final double revenue) {
		Log.d ("LIGHTNING","Appsflyer track purchase sku:" + content_id + " " + revenue + " " + currency);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Map<String, Object> eventValue = new HashMap<String, Object>();
				Float frevenue = new Float(revenue);
				eventValue.put(AFInAppEventParameterName.REVENUE,frevenue.floatValue()); 
				eventValue.put(AFInAppEventParameterName.CONTENT_ID, content_id); 
				eventValue.put(AFInAppEventParameterName.CURRENCY, currency);

				AppsFlyerLib.trackEvent(Lightning.activity,AFInAppEventType.PURCHASE,eventValue);
			}
		});
	}

	public static void trackLevelComplete (final int level) {
		Log.d ("LIGHTNING","Appsflyer track level complete " + level);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Map<String, Object> eventValue = new HashMap<String, Object>();
				eventValue.put(AFInAppEventParameterName.LEVEL,level); 

				AppsFlyerLib.trackEvent(Lightning.activity,AFInAppEventType.LEVEL_ACHIEVED,eventValue);
			}
		});
	}

	public static void trackTapjoyEvent () {
		Log.d ("LIGHTNING","Appsflyer track tapjoy event");
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Map<String, Object> eventValue = new HashMap<String, Object>();
				AppsFlyerLib.trackEvent(Lightning.activity,tapjoyEvent,eventValue);
			}
		});
	}
}
