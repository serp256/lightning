package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import com.tapjoy.TapjoyConnect;

public class LightTapjoy {
	public static void init(final String appId, final String secKey) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
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