package ru.redspell.lightning;

import ru.redspell.lightning.OAuthDialog.UrlRunnable;

public class OAuth {
	public static void dialog(final String url) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				(new OAuthDialog(LightView.instance.activity, url)).show();
			}
		});
	}

	public static void dialog(final String url, final UrlRunnable closeHandler, final UrlRunnable redirectHandler, final String redirectUrlPath) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				(new OAuthDialog(LightView.instance.activity, url, closeHandler, redirectHandler, redirectUrlPath)).show();
			}
		});
	}	
}