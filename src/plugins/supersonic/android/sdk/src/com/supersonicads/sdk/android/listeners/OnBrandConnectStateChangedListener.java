package com.supersonicads.sdk.android.listeners;

import com.supersonicads.sdk.android.BrandConnectParameters;

/**
 * Interface definition for a callback to be invoked when brandConnect process
 * states are changed.
 */
public interface OnBrandConnectStateChangedListener {

    /**
     * Invoked when the client has succeeded establishing connection to the
     * brand.
     */
    public void onInitSuccess(BrandConnectParameters campaign);

    /**
     * Invoked when the client has failed establishing connection to the brand.
     */
    public void onInitFail(int errorId, String description);

    /**
     * Called after the user has finished viewing a video ad.
     */
    public void onAdFinished(String campaignName, int receivedCredits);

    /**
     * Called when there are no more offers.
     */
    public void noMoreOffers();

}
