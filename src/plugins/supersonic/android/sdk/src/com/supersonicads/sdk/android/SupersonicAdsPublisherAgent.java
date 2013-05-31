package com.supersonicads.sdk.android;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Map;

import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;

import com.supersonicads.sdk.android.listeners.OnBrandConnectStateChangedListener;

/**
 * Application's main interface for interacting with SuperSonicAds servers as
 * publisher.
 */
@SuppressLint("HandlerLeak")
public final class SupersonicAdsPublisherAgent {

    private static final String SERVICE_PROTOCOL = "http";
    private static final String SERVICE_HOST_NAME = "www.supersonicads.com";
    private static final int SERVICE_PORT = 80;

    // definitions of the application's services.
    private static final String DOMAIN_SERVICE_BRAND_CONNECT_MOBILE = "/delivery/brandConnectMobile.php?";
    private static final String DOMAIN_SERVICE_OFFER_WALL = "/delivery/mobilePanel.php?";

    // BrandConnect handler flags:
    private static final int BRAND_CONNECT_INIT_SUCCESS = 1;
    private static final int BRAND_CONNECT_INIT_FAIL = 2;

    private static final String BRAND_CONNECT = "brand_connect";
    private static final String BRAND_CONNECT_ERROR_DESCRIPTION = "brand_connect_error_description";

    private static SupersonicAdsPublisherAgent sInstance;

    // definitions of the client's listeners.
    private OnBrandConnectStateChangedListener mOnBrandConnectStateChangedListener;

    // definition of the internal SDK's notifications receiver.
    private ActionReceiver mActionReceiver;

    // members that are retrieved from BrandConnectMobile call.
    private volatile String mBrandConnectMobileUrl = "";

    // ================================================================================
    // AGENT CONSTRUCTION.
    // ================================================================================

    private SupersonicAdsPublisherAgent() {
    }

    public static SupersonicAdsPublisherAgent getInstance() {
        if (sInstance == null) {
            sInstance = new SupersonicAdsPublisherAgent();
        }
        return sInstance;
    }

    // ================================================================================
    // PUBLISHER
    // ================================================================================

    /**
     * Initializes brand connect asynchronously.<br />
     * Note that the brand connect process happens asynchronously, and for
     * notifying about it's process, <br />
     * implements the argumented {@link OnBrandConnectStateChangedListener}
     * interface. <br />
     * For releasing the module, invoke {@link release()}.
     * 
     * @param context
     *            given from the client application for access system's
     *            properties.
     * @param applicationKey
     *            code for connecting with the servers.
     * @param applicationUserId
     *            code for connecting with the servers.
     * @param listener
     *            for invoking callbacks when there are changes in the
     *            BrandConnect process.
     * @param shouldGetLocation
     *            flag for indicating whatever location of the device should be
     *            taken part for presenting content to the client.
     * @param extraParameters
     *            that should be taken part for presenting content to the client
     *            and handling requests with the servers
     * 
     * @return reference to initialized SupersonicAdsAgent.
     */
    public void initializeBrandConnnect(Context context, String applicationKey, String applicationUserId,
            OnBrandConnectStateChangedListener listener, boolean shouldGetLocation, Map<String, String> extraParameters) {
        mOnBrandConnectStateChangedListener = listener;

        if (context != null) {
            if (mActionReceiver != null) {
                context.unregisterReceiver(mActionReceiver);
            }

            // register the action receiver.
            mActionReceiver = new ActionReceiver();
            IntentFilter intentFilter = new IntentFilter();
            intentFilter.addAction(Constants.ACTION_BRAND_CONNECT_AD_COMPLETE);
            intentFilter.addAction(Constants.ACTION_BRAND_CONNECT_NO_MORE_OFFERS);

            context.registerReceiver(mActionReceiver, intentFilter);
        }

        // load BrandConnect.
        initializeBrandConnnect(context, applicationKey, applicationUserId, shouldGetLocation, extraParameters);
    }

    /**
     * Shows the brand connect HTML dialog in new Activity. </br> For being
     * notifying about the dialog states, the callbacks: </br>
     * {@code OnBrandConnectStateChangedListener.onBeforeOpen()} </br>
     * {@code OnBrandConnectStateChangedListener.onAftertClose()} </br>
     * {@code OnBrandConnectStateChangedListener.onAdFinished(String campaignName, int receivedCredits)}
     * </br> will be invoked.
     * 
     * @param context
     *            given from the client application for access system's
     *            properties.
     * @param applicationKey
     *            code for connecting with the servers.
     * @param applicationUserId
     *            code for connecting with the servers.
     */
    public void showBrandConnect(Context context) {
        if (mBrandConnectMobileUrl != null && mBrandConnectMobileUrl.length() > 0) {
            Intent intent = new Intent(context.getApplicationContext(), WebViewActivity.class);
            intent.putExtra(Constants.KEY_ACTIVITY_DATA_URL, mBrandConnectMobileUrl);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }

    /**
     * Shows the offer wall dialog in new Activity.
     * 
     * Same as
     * {@link SupersonicAdsPublisherAgent#showOfferWall(Context, OnOfferWallVisibilityChangedListener, String, String, Map)}
     * except this sends null to the last parameter.
     * 
     * @param context
     *            given from the client application for access system's
     *            properties.
     * @param applicationKey
     *            code for connecting with the servers.
     * @param applicationUserId
     *            code for connecting with the servers.
     * @throws SuperSonicAdsPublisherException
     */
    public void showOfferWall(Context context, String applicationKey, String applicationUserId)
            throws SuperSonicAdsPublisherException {
        showOfferWall(context, applicationKey, applicationUserId, null);
    }

    /**
     * Shows the offer wall dialog in new Activity.
     * 
     * @param context
     *            given from the client application for access system's
     *            properties.
     * @param listener
     *            for being notifying about the offer wall visibility states
     *            (when it's about to be opened or closed).
     * @param applicationKey
     *            code for connecting with the servers.
     * @param applicationUserId
     *            code for connecting with the servers.
     * @param extraParameters
     *            that should be taken part for presenting content to the client
     *            and handling requests with the servers
     * @throws SuperSonicAdsPublisherException
     */
    public void showOfferWall(Context context, String applicationKey, String applicationUserId,
            Map<String, String> extraParameters) throws SuperSonicAdsPublisherException {
        // build the url for the offerWall
        URL requestUrl = buildRequestWithParamters(context, DOMAIN_SERVICE_OFFER_WALL, applicationKey,
                applicationUserId, false, extraParameters);

        Logger.i("Show offer wall", requestUrl.toString());

        Intent intent = new Intent(context.getApplicationContext(), WebViewActivity.class);
        intent.putExtra(Constants.KEY_ACTIVITY_DATA_URL, requestUrl.toString());
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    /**
     * Releases resources of the SDK, must be called after done using the agent.
     * 
     * @param context
     *            context.
     */
    public void release(Context context) {
        if (mActionReceiver != null) {
            context.unregisterReceiver(mActionReceiver);
            mActionReceiver = null;
        }

        mOnBrandConnectStateChangedListener = null;
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

    // ================================================================================
    // PRIVATE
    // ================================================================================

    /**
     * Helper method for getting the campaigns in worker thread.
     */
    private void initializeBrandConnnect(final Context context, final String applicationKey,
            final String applicationUserId, final boolean shouldGetLocation, final Map<String, String> extraParameters) {

        /**
         * Executor thread for performing call to the BrandConnect service call.
         */
        new Thread(new Runnable() {
            @SuppressWarnings("unchecked")
            @Override
            public void run() {
                try {
                    URL urlRequest = buildRequestWithParamters(context, DOMAIN_SERVICE_BRAND_CONNECT_MOBILE,
                            applicationKey, applicationUserId, shouldGetLocation, extraParameters);

                    // get the data from the service.

                    Logger.i("Brand Connect request", urlRequest.toString());

                    HttpURLConnection urlConnection = (HttpURLConnection) urlRequest.openConnection();
                    urlConnection.setDoInput(true);
                    urlConnection.setDoOutput(true);
                    urlConnection.setUseCaches(false);
                    urlConnection.setRequestMethod("GET");

                    InputStream is = urlConnection.getInputStream();

                    BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));

                    StringBuilder builder = new StringBuilder();
                    for (String line = null; (line = br.readLine()) != null;) {
                        builder.append(line);
                    }

                    // decode the response
                    String response = builder.toString();
                    response = new String(response.getBytes(), "UTF-8");

                    Logger.i("Brand Connect response", response);

                    // extract the data from the service call.

                    JSONParser parser = new JSONParser();
                    Map<String, Object> resultMap = (Map<String, Object>) parser.parse(response);

                    if (resultMap != null && resultMap.size() > 0) {
                        // get general properties:

                        int numberAvailableCampaigns = 0;
                        int totalNumberCredits = 0;
                        int firstCampaignCredits = 0;

                        // get parameters for BrandConnectParameters:
                        ArrayList<Map<String, Object>> campaigns = (ArrayList<Map<String, Object>>) resultMap
                                .get("campaigns");
                        if (campaigns != null && campaigns.size() > 0) {

                            mBrandConnectMobileUrl = resultMap.get("mobileUrl").toString();

                            numberAvailableCampaigns = campaigns.size();

                            // get the first campaign credits.
                            firstCampaignCredits = Long.valueOf(campaigns.get(0).get("credits").toString()).intValue();

                            int campaginCredits = 0;

                            for (Map<String, Object> campagin : campaigns) {
                                // gets the campagin's credits and adds it to
                                // the total.
                                campaginCredits = Long.valueOf(campagin.get("credits").toString()).intValue();
                                totalNumberCredits = totalNumberCredits + campaginCredits;
                            }

                            BrandConnectParameters brandConnectParameters = new BrandConnectParameters(
                                    numberAvailableCampaigns, totalNumberCredits, firstCampaignCredits);

                            // SUCCESS - returns BrandConnectParameters.
                            Message message = new Message();
                            message.what = BRAND_CONNECT_INIT_SUCCESS;
                            Bundle data = new Bundle();
                            data.putSerializable(BRAND_CONNECT, (Serializable) brandConnectParameters);
                            message.setData(data);
                            mBrandConnectHandler.sendMessage(message);

                        } else {
                            // the response not containing campaigns, checks if
                            // it because an error response.
                            Map<String, Object> errorResponse = (Map<String, Object>) resultMap.get("response");
                            if (errorResponse != null && errorResponse.containsKey("errorCode")) {
                                // it's an error, send it to the listener.
                                long errorCode = Long.valueOf(errorResponse.get("errorCode").toString());
                                String errorMessage = errorResponse.get("errorMessage").toString();

                                Message message = new Message();
                                message.what = BRAND_CONNECT_INIT_FAIL;
                                message.arg1 = (int) errorCode;
                                Bundle data = new Bundle();
                                data.putString(BRAND_CONNECT_ERROR_DESCRIPTION, errorMessage);
                                message.setData(data);
                                mBrandConnectHandler.sendMessage(message);
                            } else {
                                // no campaigns available.
                                Message message = new Message();
                                message.what = BRAND_CONNECT_INIT_FAIL;
                                Bundle data = new Bundle();
                                data.putString(BRAND_CONNECT_ERROR_DESCRIPTION, "No campagins available.");
                                message.setData(data);
                                mBrandConnectHandler.sendMessage(message);
                            }
                        }
                    }

                } catch (MalformedURLException e) {
                    Message message = new Message();
                    message.what = BRAND_CONNECT_INIT_FAIL;
                    Bundle data = new Bundle();
                    data.putString(BRAND_CONNECT_ERROR_DESCRIPTION, "Bad url request.");
                    message.setData(data);
                    mBrandConnectHandler.sendMessage(message);
                } catch (IOException e) {
                    Message message = new Message();
                    message.what = BRAND_CONNECT_INIT_FAIL;
                    Bundle data = new Bundle();
                    data.putString(BRAND_CONNECT_ERROR_DESCRIPTION, "Internet connection error.");
                    message.setData(data);
                    mBrandConnectHandler.sendMessage(message);
                } catch (ParseException e) {
                    Message message = new Message();
                    message.what = BRAND_CONNECT_INIT_FAIL;
                    Bundle data = new Bundle();
                    data.putString(BRAND_CONNECT_ERROR_DESCRIPTION, "Corrupted Data from server.");
                    message.setData(data);
                    mBrandConnectHandler.sendMessage(message);
                }
            }
        }).start();
    }

    private Handler mBrandConnectHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case BRAND_CONNECT_INIT_SUCCESS:
                    Bundle data = msg.getData();
                    BrandConnectParameters brandConnectParameters = (BrandConnectParameters) data
                            .getSerializable(BRAND_CONNECT);

                    if (mOnBrandConnectStateChangedListener != null) {
                        mOnBrandConnectStateChangedListener.onInitSuccess(brandConnectParameters);
                    }
                    break;

                case BRAND_CONNECT_INIT_FAIL:
                    if (mOnBrandConnectStateChangedListener != null) {
                        mOnBrandConnectStateChangedListener.onInitFail(msg.arg1,
                                msg.getData().getString(BRAND_CONNECT_ERROR_DESCRIPTION));
                    }
                    break;
            }
        }
    };

    /**
     * Build the BrandConnect HTTP request with it's parameters.
     * 
     * @param domainServicePath
     *            - path to the service in the domain.
     * @throws SuperSonicAdsPublisherException
     */
    private URL buildRequestWithParamters(Context context, String domainServicePath, String applicationKey,
            String applicationUserId, boolean shouldGetLocation, Map<String, String> extraParameters)
            throws SuperSonicAdsPublisherException {
        DeviceProperties deviceProperties = DeviceProperties.getInstance(context);

        // builds the query:
        StringBuilder requestParameters = new StringBuilder();

        if (applicationUserId != null && applicationUserId.length() > 0) {
            requestParameters.append("applicationUserId=").append(applicationUserId);
        }

        if (applicationKey != null && applicationKey.length() > 0) {
            requestParameters.append("&applicationKey=").append(applicationKey);
        }

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

        if (shouldGetLocation == true && deviceProperties.getDeviceLocation() != null) {
            requestParameters.append("&location=").append(deviceProperties.getDeviceLocation().getLongitude())
                    .append(",").append(deviceProperties.getDeviceLocation().getLatitude());
        }

        // add aditionalParameters
        if (extraParameters != null && extraParameters.size() > 0) {
            for (Map.Entry<String, String> entry : extraParameters.entrySet()) {
                requestParameters.append("&").append(entry.getKey()).append("=").append(entry.getValue());
            }
        }

        String file = (domainServicePath + requestParameters.toString()).replace(" ", "%20");
        try {
            return new URL(SERVICE_PROTOCOL, SERVICE_HOST_NAME, SERVICE_PORT, file);
        } catch (MalformedURLException e) {
            throw new SuperSonicAdsPublisherException(e);
        }
    }

    /**
     * Receiver for handling notifications from {@link WebViewActivity}.
     */
    private class ActionReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {

            String action = intent.getAction();

            if (action.equals(Constants.ACTION_BRAND_CONNECT_AD_COMPLETE)) {
                int receivedCredits = intent.getIntExtra(Constants.KEY_ACTIVITY_DATA_ACTION, 0);

                if (mOnBrandConnectStateChangedListener != null) {
                    mOnBrandConnectStateChangedListener.onAdFinished("", receivedCredits);
                }
            } else if (action.contains(Constants.ACTION_BRAND_CONNECT_NO_MORE_OFFERS)) {
                if (mOnBrandConnectStateChangedListener != null) {
                    mOnBrandConnectStateChangedListener.noMoreOffers();
                }
            }
        }

    }

    public static final class SuperSonicAdsPublisherException extends RuntimeException {
        private static final long serialVersionUID = 7864930980864935234L;

        public SuperSonicAdsPublisherException(Throwable t) {
            super(t);
        }
    }

}
