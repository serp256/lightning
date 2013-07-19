package ru.redspell.lightning.plugins;

import android.content.Intent;
import android.net.Uri;

public class LightInstagram extends LightIntentPlugin {
	private static LightInstagram instance;

	private static LightInstagram getInstance() {
		if (instance == null) {
			instance = new LightInstagram();
		}

		return instance;
	}

	public static boolean post(String fname, String text) {
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("image/*");
		intent.setPackage("com.instagram.android");
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		intent.putExtra(Intent.EXTRA_STREAM, Uri.parse("file://" + text));

		return getInstance().sendIntent("com.instagram.android", intent);
	}
}