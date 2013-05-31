package com.supersonicads.sdk.android;

import android.util.Log;

/**
 * Utility class for controlling the SDK Log with true / false flags.
 */
public class Logger {

    private static boolean enableLogging = false;

    /**
     * Enables or disables logging.
     */
    public static void enableLogging(boolean enableLogFlag) {
        enableLogging = enableLogFlag;
    }

    /**
     * Set an info log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     */
    public static void i(String tag, String message) {
        if (enableLogging) {
            Log.i(tag, message);
        }
    }

    /**
     * Set an info log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     * @param tr
     *            An exception to log.
     */
    public static void i(String tag, String message, Throwable tr) {
        if (enableLogging) {
            Log.i(tag, message, tr);
        }
    }

    /**
     * Set an error log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     */
    public static void e(String tag, String message) {
        if (enableLogging) {
            Log.e(tag, message);
        }
    }

    /**
     * Set an error log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     * @param tr
     *            An exception to log.
     */
    public static void e(String tag, String message, Throwable tr) {
        if (enableLogging) {
            Log.e(tag, message, tr);
        }
    }

    /**
     * Set a warning log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     */
    public static void w(String tag, String message) {
        if (enableLogging) {
            Log.w(tag, message);
        }
    }

    /**
     * Set a warning log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     * @param tr
     *            An exception to log.
     */
    public static void w(String tag, String message, Throwable tr) {
        if (enableLogging) {
            Log.w(tag, message, tr);
        }
    }

    /**
     * Set a debug log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     */
    public static void d(String tag, String message) {
        if (enableLogging) {
            Log.d(tag, message);
        }
    }

    /**
     * Set a debug log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     * @param tr
     *            An exception to log.
     */
    public static void d(String tag, String message, Throwable tr) {
        if (enableLogging) {
            Log.d(tag, message, tr);
        }
    }

    /**
     * Set a verbose log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     */
    public static void v(String tag, String message) {
        if (enableLogging) {
            Log.v(tag, message);
        }
    }

    /**
     * Set a verbose log message.
     * 
     * @param tag
     *            for the log message.
     * @param message
     *            Log to output to the console.
     * @param tr
     *            An exception to log.
     */
    public static void v(String tag, String message, Throwable tr) {
        if (enableLogging) {
            Log.v(tag, message, tr);
        }
    }

}
