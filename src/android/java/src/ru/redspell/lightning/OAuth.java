package ru.redspell.lightning;

public class OAuth {
	public static void dialog(final String url) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				(new OAuthDialog(Lightning.activity, url, null)).show();
			}
		});
	}

/*	public static void dialog(final String url, final UrlRunnable closeHandler, final UrlRunnable redirectHandler, final String redirectUrlPath) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				(new OAuthDialog(LightView.instance.activity, url, closeHandler, redirectHandler, redirectUrlPath)).show();
			}
		});
	}	*/
}