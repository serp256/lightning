package ru.redspell.lightning.v2;

import android.app.Activity;

public class Lightning {
    public static String locale() {
    	ru.redspell.lightning.utils.Log.d("LIGHTNING", "locale");
        return java.util.Locale.getDefault().getLanguage();
    }

    public static native NativeActivity activity();

    static {
        System.loadLibrary("test");
    }    
}