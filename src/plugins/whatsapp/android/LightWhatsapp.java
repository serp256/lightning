package ru.redspell.lightning.plugins;

import android.content.Intent;
import android.net.Uri;

public class LightWhatsapp extends LightIntentPlugin {
	private static LightWhatsapp instance;

	private static LightWhatsapp getInstance() {
		if (instance == null) {
			instance = new LightWhatsapp();
		}

		return instance;
	}


	public static boolean text(String txt) {
		Intent intent = new Intent(android.content.Intent.ACTION_SEND);
		intent.setType("text/plain");
		intent.setPackage("com.whatsapp");
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		intent.putExtra(Intent.EXTRA_TEXT, txt);

		return getInstance().sendIntent("com.whatsapp", intent);
	}

	public static boolean picture(String pic) {
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("image/*");
		intent.setPackage("com.whatsapp");
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		intent.putExtra(Intent.EXTRA_STREAM, Uri.parse("file://" + pic));

		return getInstance().sendIntent("com.whatsapp", intent);
	}


	public static boolean isInstalled() {
		return getInstance().isAppInstalled("com.whatsapp");
	}
}
