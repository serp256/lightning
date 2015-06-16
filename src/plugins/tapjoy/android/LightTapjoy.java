package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import com.tapjoy.TapjoyConnect;
import ru.redspell.lightning.utils.Log;
import com.tapjoy.TapjoyConstants;
import com.tapjoy.TapjoyConnectFlag;
import com.tapjoy.TapjoyLog;
import java.util.Hashtable;

public class LightTapjoy {
	public static void init(final String appId, final String secKey) {
		Log.d ("LIGHTNING", "Tapjoy version:" + TapjoyConstants.TJC_LIBRARY_VERSION_NUMBER);
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
/*				Hashtable<String,Object> connectFlags = new Hashtable<String,Object>();
				connectFlags.put(TapjoyConnectFlag.ENABLE_LOGGING, "true");*/
				TapjoyLog.enableLogging(true);
				TapjoyConnect.requestTapjoyConnect(Lightning.activity, appId, secKey);
			}
		});
	}

	public static void showOffersWithCurrencyID(final String currency, final boolean showSelector) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().showOffersWithCurrencyID(currency, showSelector);
			}
		});
	}

	public static void showOffers() {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().showOffers();
			}
		});
	}

	public static void setUserID(final String uid) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().setUserID(uid);
			}
		});
	}

	public static void actionComplete(final String action) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().actionComplete(action);
			}
		});
	}
}
