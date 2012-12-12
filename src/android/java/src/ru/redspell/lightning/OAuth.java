package ru.redspell.lightning;

public class OAuth {
	public static void dialog(final String url) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				(new OAuthDialog(LightView.instance.activity, url)).show();
			}
		});
	}
}