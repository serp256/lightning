package ru.redspell.lightning.utils;

import java.security.NoSuchAlgorithmException;
import java.security.MessageDigest;
import java.util.UUID;

import android.content.SharedPreferences;
import android.provider.Settings.Secure;
import android.provider.Settings;
import android.os.Build;

import ru.redspell.lightning.v2.Lightning;

public class UDID {
	protected static final String PREFS_FILE = "device_id.xml";
	protected static final String PREFS_DEVICE_ID = "device_id";

    private static String udid = null;

    public static final String md5(final String s) {
            try {
                    // Create MD5 Hash
                    MessageDigest digest = java.security.MessageDigest
                                    .getInstance("MD5");
                    digest.update(s.getBytes());
                    byte messageDigest[] = digest.digest();

                    // Create Hex String
                    StringBuffer hexString = new StringBuffer();
                    for (int i = 0; i < messageDigest.length; i++) {
                            String h = Integer.toHexString(0xFF & messageDigest[i]);
                            while (h.length() < 2)
                                    h = "0" + h;
                            hexString.append(h);
                    }
                    return hexString.toString();

            } catch (NoSuchAlgorithmException e) {
                    e.printStackTrace();
            }
            return "00000000000000000000000000000000";
    }

    public static String get() {
        if (udid == null) {
            Log.d("LIGHTNING", "INIT OLD UDID");
            String serial = md5 (
                Build.BOARD + Build.BRAND
                + Build.CPU_ABI + Build.DEVICE
                + Build.DISPLAY + Build.HOST
                + Build.ID + Build.MANUFACTURER
                + Build.MODEL + Build.PRODUCT
                + Build.TAGS + Build.TYPE
                + Build.USER);
    
            Log.d ("LIGHTNING", "Board: " + Build.BOARD);
            Log.d ("LIGHTNING", "Brand: " + Build.BRAND);
            Log.d ("LIGHTNING", "CPU_ABI: " + Build.CPU_ABI);
            Log.d ("LIGHTNING", "DISPLAY: " + Build.DISPLAY);
            Log.d ("LIGHTNING", "ID: " + Build.ID);
            Log.d ("LIGHTNING", "DEVICE: " + Build.DEVICE);
            Log.d ("LIGHTNING", "HOST: " + Build.HOST);
            Log.d ("LIGHTNING", "MANUFACTURER: " + Build.MANUFACTURER);
            Log.d ("LIGHTNING", "MODEL: " + Build.MODEL);
            Log.d ("LIGHTNING", "TAGS: " + Build.TAGS);
            Log.d ("LIGHTNING", "PRODUCT: " + Build.PRODUCT);
            Log.d ("LIGHTNING", "TYPE: " + Build.TYPE);
            Log.d ("LIGHTNING", "USER: " + Build.USER);

            Log.d("LIGHTNING", "SERIAL: " + serial);


            final String android_id = Settings.System.getString(Lightning.activity.getContentResolver(),Secure.ANDROID_ID);
            Log.d("LIGHTNING","ANDROID_ID = " + android_id);
            if (android_id != null && !"9774d56d682e549c".equals(android_id) && !"0000000000000000".equals(android_id)  ) {
                udid =android_id;
            } else {
                Log.d("LIGHTNING","ANDROID_ID is bad " + android_id);
                final SharedPreferences prefs = Lightning.activity.getSharedPreferences( PREFS_FILE, 0);
                Log.d("LIGHTNING", "get deviec id" );
                final String id = prefs.getString(PREFS_DEVICE_ID, null );
                if (id == null) {
                    udid = (UUID.randomUUID ()).toString ();
                    prefs.edit().putString(PREFS_DEVICE_ID, udid).commit();
                } else {
                    Log.d("LIGHTNING", "id is not null");
                    udid = id;
                }
            };
            udid = udid + "_" + serial;
        }

        return udid;
    }	
}