
package ru.redspell.lightning.plugins;
import ru.redspell.lightning.Lightning;

public class LightXsolla{
	public static void purchase (final int s, final int f, final String token, final String redirectUrl, final boolean isSandbox) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				(new LightXsollaDialog(Lightning.activity, token, redirectUrl, s, f, isSandbox)).show();
			}
		});
	}
}
