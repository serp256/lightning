package ru.redspell.lightning;

public class OAuth {
	public static void dialog(final String url) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				new OAuthDialog(LightView.instance.activity, url, new OAuthDialog.DialogListener () {
			        public void onComplete(android.os.Bundle values) {}
			        public void onError() {}
			        public void onCancel() {}					
				}).show();
			}
		});
	}
}