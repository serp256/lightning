package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
import com.tapjoy.TapjoyConnect;

public class LightTapjoy {
	public static void init(final String appId, final String secKey) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.requestTapjoyConnect(LightActivity.instance.getApplicationContext(), appId, secKey);
			}
		});
	}

	public static void showOffersWithCurrencyID(final String currency, final boolean showSelector) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().showOffersWithCurrencyID(currency, showSelector);
			}
		});
	}

	public static void showOffers() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().showOffers();
			}
		});
	}

	public static void setUserID(final String uid) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().setUserID(uid);
			}
		});
	}

	public static void actionComplete(final String action) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				TapjoyConnect.getTapjoyConnectInstance().actionComplete(action);
			}
		});
	}
}