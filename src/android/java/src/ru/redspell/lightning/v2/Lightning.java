package ru.redspell.lightning.v2;

public class Lightning {
	public static NativeActivity activity = null;

    public static String locale() {
    	ru.redspell.lightning.utils.Log.d("LIGHTNING", "locale");
        return java.util.Locale.getDefault().getLanguage();
    }

    public static native NativeActivity activity();

    public static void init() {
    	activity = activity();
    }

    static {
        System.loadLibrary("test");
    }    
}