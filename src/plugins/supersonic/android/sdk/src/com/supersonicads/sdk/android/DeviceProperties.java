package com.supersonicads.sdk.android;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.provider.Settings;
import android.telephony.TelephonyManager;

/**
 * Holder class for the Device properties.
 */
class DeviceProperties {

    private static DeviceProperties mInstance = null;

    private String mDeviceOem;
    private String mDeviceModel;
    private String mDeviceOsType;
    private int mDeviceOsVersion;
    private Map<String, String> mDeviceIds;
    private String mDeviceCarrier;

    private Location mDeviceLocation;
    private final int mSupersonicSdkVersion = 2;

    private DeviceProperties(Context context) {
        init(context);
    }

    public static DeviceProperties getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new DeviceProperties(context);
        }

        return mInstance;
    }

    /**
     * Initialize internal members of the class.
     */

    private void init(Context context) {
        mDeviceOem = Build.MANUFACTURER;
        mDeviceModel = Build.MODEL;
        mDeviceOsType = "Android";
        mDeviceOsVersion = Build.VERSION.SDK_INT;

        mDeviceIds = new TreeMap<String, String>();

        mDeviceIds
                .put("AndroidID", Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID));

        TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
        switch (tm.getPhoneType()) {
            case TelephonyManager.PHONE_TYPE_GSM:
                mDeviceIds.put("IMEI", tm.getDeviceId());
                break;

            case TelephonyManager.PHONE_TYPE_CDMA:
                mDeviceIds.put("MEID", tm.getDeviceId());
                break;
        }

        if (context.checkCallingOrSelfPermission("android.permission.ACCESS_WIFI_STATE") == PackageManager.PERMISSION_GRANTED) {
            WifiManager wm = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            WifiInfo ci = wm.getConnectionInfo();
            if (ci != null) {
                mDeviceIds.put("MAC", wm.getConnectionInfo().getMacAddress());
            }
        }

        mDeviceCarrier = tm.getNetworkOperatorName();

        mDeviceLocation = getLastBestLocation(context);

        initGingerbreadAndUp();
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    private void initGingerbreadAndUp() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
            mDeviceIds.put("UUID", Build.SERIAL);
        }
    }

    public String getDeviceOem() {
        return mDeviceOem;
    }

    /**
     * Retrieves the device's manufacturer name.
     */
    public String getDeviceModel() {
        return mDeviceModel;
    }

    /**
     * Retrieves the device's operating system name.
     */
    public String getDeviceOsType() {
        return mDeviceOsType;
    }

    /**
     * Retrieves the device's operating system version name.
     */
    public int getDeviceOsVersion() {
        return mDeviceOsVersion;
    }

    /**
     * Retrieves the device's unique id.
     */
    public Map<String, String> getDeviceIds() {
        return mDeviceIds;
    }

    public String getDeviceCarrier() {
        return mDeviceCarrier;
    }

    public Location getDeviceLocation() {

        return mDeviceLocation;
    }

    public int getSupersonicSdkVersion() {
        return mSupersonicSdkVersion;
    }

    /**
     * Retrieves the most accurate and fresh location from the cached locations.
     */
    private Location getLastBestLocation(Context context) {

        LocationManager mLocationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);

        Location bestResult = null;
        float bestAccuracy = Float.MAX_VALUE;
        long bestTime = Long.MIN_VALUE;

        List<String> matchingProviders = mLocationManager.getAllProviders();
        for (String provider : matchingProviders) {
            Location location = mLocationManager.getLastKnownLocation(provider);
            if (location != null) {
                float accuracy = location.getAccuracy();
                long time = location.getTime();

                if ((time > bestTime && accuracy < bestAccuracy)) {
                    bestResult = location;
                    bestAccuracy = accuracy;
                    bestTime = time;
                }
            }
        }

        return bestResult;
    }

}
