package com.supersonicads.sdk.android;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Calendar;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Application's main interface for interacting with SuperSonicAds servers as
 * advertiser.
 */
public class SupersonicAdsAdvertiserAgent {

    private static final String TAG = "SupersonicAdsAdvertiserAgent";

    private static final String SERVICE_PROTOCOL = "http";
    private static final String SERVICE_HOST_NAME = "www.supersonicads.com";
    private static final int SERVICE_PORT = 80;

    private static final String DOMAIN_SERVICE_REPORT_APP_STARTED = "/api/v1/mobileApplicationOnLoad.php?";

    private static final int REPORT_FLAG_SUCCEED = -1;
    private static final int REPORT_FLAG_NOW = 0;

    private static final String PREFERENCES_FILE = "com.supersonicads.sdk.android.supersonicadsadvertiseragent";
    private static final String PREFERENCES_KEY_REPORT_TIMESTEMP = "preferences_key_report_timestemp";
    private static final String PREFERENCES_KEY_REPORT_COUNTER = "preferences_key_report_counter";

    public static SupersonicAdsAdvertiserAgent sInstance;

    // ================================================================================
    // AGENT CONSTRUCTION.
    // ================================================================================

    private SupersonicAdsAdvertiserAgent() {
    }

    public static SupersonicAdsAdvertiserAgent getInstance() {
        if (sInstance == null) {
            sInstance = new SupersonicAdsAdvertiserAgent();
        }
        return sInstance;
    }

    // ================================================================================
    // ADVERTISER.
    // ================================================================================

    /**
     * Initializes the SDK on the advertiser's application and stores the the
     * next time to call this method </br> in the application's shared
     * preferences.
     * 
     * @param applicationKey
     *            code for connecting with the servers.
     */
    public void reportAppStarted(Context context, String advertiserId, String password, String campaignId) {

        final String lAdvertiserId = advertiserId;
        final String lPassword = password;
        final String lCamaignId = campaignId;

        final Context lContext = context.getApplicationContext();

        /**
         * Executor thread for performing call to the reportAppStarted service.
         */
        new Thread(new Runnable() {

            @Override
            public void run() {
                Logger.i(TAG, "Starting to report.");

                DeviceProperties deviceProperties = DeviceProperties.getInstance(lContext);

                int counter = getCounter(lContext);
                StringBuilder sb = new StringBuilder().append(counter).append(lCamaignId);
                for (String deviceId : deviceProperties.getDeviceIds().values()) {
                    sb.append(deviceId);
                }
                sb.append(lPassword);
                String advertiserSignature = toMD5(sb.toString());

                // get the data from the service.
                try {
                    // builds the requests URL.
                    URL urlRequest = buildRequestWithParamters(lContext, DOMAIN_SERVICE_REPORT_APP_STARTED,
                            lAdvertiserId, lCamaignId, counter, advertiserSignature);

                    int reportFlag = REPORT_FLAG_NOW;

                    if (hasToReport(lContext)) {
                        reportFlag = report(urlRequest);
                        storeNextTimeToReport(lContext, reportFlag);

                        Logger.i(TAG, "Done reporting.");
                    } else {
                        Logger.i(TAG, "Failed reporting - time has not come");
                    }

                    setCounter(lContext, counter + 1);

                } catch (SuperSonicAdsAdvertiserException e) {
                    Logger.e(TAG, "Failed reporting", e);
                }
            }
        }).start();
    }

    /**
     * Reports the server about the installation of the application.
     * 
     * @param urlRequest
     *            full URL to the server.
     * @return an indicator for the next time to the service, see report flags.
     * 
     * @throws SuperSonicAdsAdvertiserException
     */
    private int report(URL urlRequest) throws SuperSonicAdsAdvertiserException {
        Logger.i("Report App Started request", urlRequest.toString());

        try {
            HttpURLConnection urlConnection = (HttpURLConnection) urlRequest.openConnection();
            urlConnection.setDoInput(true);
            urlConnection.setDoOutput(true);
            urlConnection.setUseCaches(false);
            urlConnection.setRequestMethod("GET");
            urlConnection.setRequestProperty("Content-Type", "multipart/form-data");

            InputStream is = urlConnection.getInputStream();
            BufferedReader br = new BufferedReader(new InputStreamReader(is));

            StringBuilder builder = new StringBuilder();
            for (String line = null; (line = br.readLine()) != null;) {
                builder.append(line);
            }

            // parse the value from the server, and store it in the
            // application's shared preferences.
            String response = builder.toString();

            if (response != null && response.length() > 0) {
                Logger.i("Report App Started response", response);
                return Integer.parseInt(response);
            }

            // an error occurred, sets flag to call it next time.
            return REPORT_FLAG_NOW;
        } catch (IOException e) {
            throw new SuperSonicAdsAdvertiserException(e);
        }

    }

    /**
     * Build the BrandConnect HTTP request with it's parameters.
     * 
     * @param domainServicePath
     *            path to the service in the domain.
     * @throws SuperSonicAdsAdvertiserException
     */
    private URL buildRequestWithParamters(Context context, String domainServicePath, String advertiserId,
            String campaignId, int counter, String advertiserSignature) throws SuperSonicAdsAdvertiserException {

        DeviceProperties deviceProperties = DeviceProperties.getInstance(context);

        // builds the query:
        StringBuilder requestParameters = new StringBuilder();

        requestParameters.append("advertiserId=").append(advertiserId);
        requestParameters.append("&campaignId=").append(campaignId);
        requestParameters.append("&counter=").append(Integer.toString(counter));
        requestParameters.append("&advertiserSignature=").append(advertiserSignature);

        requestParameters.append("&deviceOEM=").append(deviceProperties.getDeviceOem());
        requestParameters.append("&deviceModel=").append(deviceProperties.getDeviceModel());
        for (String deviceIdType : deviceProperties.getDeviceIds().keySet()) {
            requestParameters.append("&deviceIds[").append(deviceIdType).append("]=")
                    .append(deviceProperties.getDeviceIds().get(deviceIdType));
        }
        requestParameters.append("&deviceOs=").append(deviceProperties.getDeviceOsType());
        requestParameters.append("&deviceOSVersion=").append(Integer.toString(deviceProperties.getDeviceOsVersion()));
        requestParameters.append("&SDKVersion=").append(deviceProperties.getSupersonicSdkVersion());

        // optional:

        if (deviceProperties.getDeviceCarrier() != null && deviceProperties.getDeviceCarrier().length() > 0) {
            requestParameters.append("&mobileCarrier=").append(deviceProperties.getDeviceCarrier());
        }

        if (deviceProperties.getDeviceLocation() != null) {
            requestParameters.append("&location=").append(deviceProperties.getDeviceLocation().getLongitude())
                    .append(",").append(deviceProperties.getDeviceLocation().getLatitude());
        }

        String file = (domainServicePath + requestParameters.toString()).replace(" ", "%20");
        try {
            return new URL(SERVICE_PROTOCOL, SERVICE_HOST_NAME, SERVICE_PORT, file);
        } catch (MalformedURLException e) {
            throw new SuperSonicAdsAdvertiserException(e);
        }
    }

    /**
     * Stores timestamp to the next time to report about the installation of the
     * app.
     * 
     * @param days
     *            to execute the next web service call.
     */
    private void storeNextTimeToReport(Context context, int days) {
        long nextTime = (long) days;

        if (days > REPORT_FLAG_NOW) {
            Calendar timeToReport = Calendar.getInstance();
            timeToReport.add(Calendar.DATE, days);

            nextTime = timeToReport.getTimeInMillis();
            Logger.i(TAG, "Next time to report: " + timeToReport.getTime().toString() + " - " + Long.toString(nextTime));
        }

        SharedPreferences sharedPreferences = context.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putLong(PREFERENCES_KEY_REPORT_TIMESTEMP, nextTime);
        editor.commit();
    }

    /**
     * Validates if it's the time to report about the installation of the app.
     * 
     * @return true that is the time, false otherwise.
     */
    private boolean hasToReport(Context context) {
        // get the last time it was reported.
        SharedPreferences sharedPreferences = context.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE);
        long lastTime = sharedPreferences.getLong(PREFERENCES_KEY_REPORT_TIMESTEMP, REPORT_FLAG_NOW);

        // checks if the application succeeded to report and should not do it
        // again.
        if (lastTime == REPORT_FLAG_SUCCEED) {
            return false;
        }

        // checks if it should report now.
        if (lastTime == REPORT_FLAG_NOW) {
            return true;
        }

        long now = System.currentTimeMillis();
        // checks the last time it was trying to report and it should do it
        // again.
        if (now >= lastTime) {
            return true;
        }

        return false;
    }

    // ================================================================================
    // UTIL
    // ================================================================================

    /**
     * Sets flag to enable or disable printing Log events.
     * 
     * @param enableLogging
     *            sets {@code true} to enable logging, {@code false} otherwise.
     */
    public void enableLogging(boolean enableLogging) {
        Logger.enableLogging(true);
    }

    /**
     * Retrieves counter to indicate the number of calls.
     * 
     * @param context
     *            of the application.
     * @return counter
     */
    private int getCounter(Context context) {
        SharedPreferences sharedPreferences = context.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getInt(PREFERENCES_KEY_REPORT_COUNTER, 1);
    }

    /**
     * Set a counter to indicate the number of calls.
     * 
     * @param context
     *            of the application.
     */
    private void setCounter(Context context, int counter) {
        SharedPreferences sharedPreferences = context.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putInt(PREFERENCES_KEY_REPORT_COUNTER, counter);
        editor.commit();
    }

    private String toMD5(String signature) {
        try {

            // Create MD5 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(signature.getBytes());
            byte messageDigest[] = digest.digest();

            // Create Hex String
            StringBuffer hexString = new StringBuffer();
            for (int i = 0; i < messageDigest.length; i++) {
                String h = Integer.toHexString(0xFF & messageDigest[i]);
                while (h.length() < 2) {
                    h = "0" + h;
                }

                hexString.append(h);
            }
            return hexString.toString();

        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public static final class SuperSonicAdsAdvertiserException extends RuntimeException {
        private static final long serialVersionUID = 8169178234844720921L;

        public SuperSonicAdsAdvertiserException(Throwable t) {
            super(t);
        }
    }

}
