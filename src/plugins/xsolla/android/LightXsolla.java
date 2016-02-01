
package ru.redspell.lightning.plugins;
import ru.redspell.lightning.Lightning;
import android.content.DialogInterface;

public class LightXsolla{
	public static void purchase (final int s, final int f, final String token, final String redirectUrl, final boolean isSandbox) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				LightXsollaDialog dialog = new LightXsollaDialog(Lightning.activity, token, redirectUrl, s, f, isSandbox);
				dialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
					@Override
					public void onCancel(DialogInterface dialog) {
						dialog.cancel();
					}
				});
				dialog.show ();
			}
		});
	}
}
