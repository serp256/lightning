package ru.redspell.lightning;

public class LightNativeActivityHelper {
	public static android.app.Activity activity = null;

	public static String locale() {
		return java.util.Locale.getDefault().getLanguage();
	}
}