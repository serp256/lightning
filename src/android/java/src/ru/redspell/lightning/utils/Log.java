package ru.redspell.lightning.utils;

public class Log {
		private static final String TAG = "LIGHTNING";
    public static boolean enabled = true;

    public static int v(String tag, String msg) {
        return enabled ? android.util.Log.v(tag, msg) : 0;
    }

    public static int v(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.v(tag, msg, tr) : 0;
    }

    public static int d(String tag, String msg) {
        return enabled ? android.util.Log.d(tag, msg) : 0;
    }
		public static int d(String msg) {
        return enabled ? android.util.Log.d(TAG, msg) : 0;
		}

    public static int d(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.d(tag, msg, tr) : 0;
    }

    public static int i(String tag, String msg) {
        return enabled ? android.util.Log.i(tag, msg) : 0;
    }

    public static int i(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.i(tag, msg, tr) : 0;
    }

    public static int w(String tag, String msg) {
        return enabled ? android.util.Log.w(tag, msg) : 0;
    }

    public static int w(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.w(tag, msg, tr) : 0;
    }

    public static boolean isLoggable(String tag, int level) {
        return android.util.Log.isLoggable(tag, level);
    }

    public static int w(String tag, Throwable tr) {
        return enabled ? android.util.Log.w(tag, tr) : 0;
    }

    public static int e(String tag, String msg) {
        return enabled ? android.util.Log.e(tag, msg) : 0;
    }

    public static int e(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.e(tag, msg, tr) : 0;
    }

    public static int wtf(String tag, String msg) {
        return enabled ? android.util.Log.wtf(tag, msg) : 0;
    }

    public static int wtf(String tag, Throwable tr) {
        return enabled ? android.util.Log.wtf(tag, tr) : 0;
    }

    public static int wtf(String tag, String msg, Throwable tr) {
        return enabled ? android.util.Log.wtf(tag, msg, tr) : 0;
    }

    public static String getStackTraceString(Throwable tr) {
        return android.util.Log.getStackTraceString(tr);
    }

    public static int println(int priority, String tag, String msg) {
        return enabled ? android.util.Log.println(priority, tag, msg) : 0;
    }
}
