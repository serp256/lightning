package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;
import com.gameanalytics.sdk.*;

public class LightGameanalytics {
	public static void init(final String gameKey, final String secretKey, final String version, final boolean debugMode, final String[] currencies, final String[] itemTypes, final String[] dimensions) {
		Log.d ("LIGHTNING", "GameAnalytics load lib" );
		System.loadLibrary("GameAnalytics");
		Log.d ("LIGHTNING", "GameAnalytics init: " + version);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				if (debugMode) {
					Log.d ("LIGHTNING", "GameAnalytics debugMode: " + debugMode);
					GameAnalytics.setEnabledInfoLog(debugMode);
					GameAnalytics.setEnabledVerboseLog(debugMode);
				}
				GameAnalytics.configureBuild(version);

				if (currencies != null) {
					Log.d("LIGHTNING", "currencies : " + java.util.Arrays.toString(currencies)); 
					GameAnalytics.configureAvailableResourceCurrencies(currencies);
				}
				if (itemTypes != null) {
					Log.d("LIGHTNING", "itemTypes : " + java.util.Arrays.toString(itemTypes)); 
					GameAnalytics.configureAvailableResourceItemTypes(itemTypes);
				}
				if (dimensions != null) {
					Log.d("LIGHTNING", "dimensions : " + java.util.Arrays.toString(dimensions)); 
					GameAnalytics.configureAvailableCustomDimensions01(dimensions);
				}

				GameAnalytics.initializeWithGameKey(Lightning.activity, gameKey, secretKey);
			}
		});
	}
	
	public static void businessEvent(final String cartType, final String itemType, final String itemId, final String currency, final int amount, final String receipt, final String signature) {
		Log.d ("LIGHTNING", "GameAnalytics businessEvent: " + itemId);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				GameAnalytics.addBusinessEventWithCurrency(currency, amount, itemType, itemId, cartType, receipt, "google_play", signature);
			}
		});
	}

	public static void resourceEvent(final int flowIntType, final String currency, final double amount, final String itemType, final String itemId) {
		Log.d ("LIGHTNING", "GameAnalytics resourceEvent: " + flowIntType + " itemType:" + itemType + " itemId:" + itemId);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Float famount= new Float(amount);
				GAResourceFlowType flowType = flowIntType > 0 ? GAResourceFlowType.GAResourceFlowTypeSource : GAResourceFlowType.GAResourceFlowTypeSink;
				GameAnalytics.addResourceEventWithFlowType(flowType, currency, famount.floatValue(), itemType, itemId);
			}
		});
	}

	public static void progressionEvent(final int statusInt, final String worldS, final String stageS, final String levelS, final Integer score) {
		Log.d ("LIGHTNING", "GameAnalytics progressionEvent: " + worldS + ":" + stageS + ":" + levelS + " score:" + score);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				GAProgressionStatus status = statusInt == 0 ? GAProgressionStatus.GAProgressionStatusStart : statusInt > 0 ? GAProgressionStatus.GAProgressionStatusComplete : GAProgressionStatus.GAProgressionStatusFail;
				String world = (worldS != null) ? worldS: "";
				String stage = (stageS != null) ? stageS: "";
				String level = (levelS != null) ? levelS: "";
					if (score != null) {
						GameAnalytics.addProgressionEventWithProgressionStatus(status, world, stage, level, score);
					}
					else {
						GameAnalytics.addProgressionEventWithProgressionStatus(status, world, stage, level);
					}
			}
		});
	}

	public static void designEvent (final String eventId, final Double v) {
		Log.d ("LIGHTNING", "GameAnalytics designEvent: " + eventId + " v: " + v);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				if ( v!= null) {
					GameAnalytics.addDesignEventWithEventId(eventId, v.floatValue());
				}
				else {
					GameAnalytics.addDesignEventWithEventId(eventId);
				}
			}
		});
	}

	public static void errorEvent (final int errorTypeInt, final String message) {
		Log.d ("LIGHTNING", "GameAnalytics errorEvent: " + errorTypeInt + ": " + message);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				GAErrorSeverity severity = null;
				switch(errorTypeInt) {
					case 0: {
						severity = GAErrorSeverity.GAErrorSeverityDebug;
						break;
					}
					case 1: {
						severity = GAErrorSeverity.GAErrorSeverityInfo;
						break;
					}
					case 2: {
						severity = GAErrorSeverity.GAErrorSeverityWarning;
						break;
					}
					case 3: {
						severity = GAErrorSeverity.GAErrorSeverityError;
						break;
					}
					case 4: {
						severity = GAErrorSeverity.GAErrorSeverityCritical;
						break;
					}

				}
				if (severity != null) {
					GameAnalytics.addErrorEventWithSeverity(severity, message);
				}
			}
		});
	}

}
