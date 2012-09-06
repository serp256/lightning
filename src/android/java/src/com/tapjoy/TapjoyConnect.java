// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

import java.util.Hashtable;

import android.content.Context;


/**
 * Created by Tapjoy.
 * Copyright 2010 Tapjoy.com All rights reserved.
 * 
 * For information about SDK integration, best practices and FAQs, please go to <a href="http://knowledge.tapjoy.com">http://knowledge.tapjoy.com </a>
 */


public final class TapjoyConnect
{ 
	private static TapjoyConnect tapjoyConnectInstance = null;
	public static final String TAPJOY_CONNECT 										= "TapjoyConnect";
	
	// Offers related.
	private static TJCOffers tapjoyOffers = null;
	private static TapjoyFeaturedApp tapjoyFeaturedApp = null;
	private static TapjoyDisplayAd tapjoyDisplayAd = null;
	private static TapjoyVideo tapjoyVideo = null;
	private static TapjoyEvent tapjoyEvent = null;
	
	
	/**
	 * Performs the Tapjoy Connect call to the Tapjoy server to notify it that
	 * this device is running your application.
	 * 
	 * This method should be called in the onCreate() method of your first activity
	 * and before any other TapjoyConnect methods.
	 * @param context						The application context.
	 * @param appID							Your Tapjoy APP ID.
	 * @param secretKey						Your Tapjoy SECRET KEY.
	 */
	public static void requestTapjoyConnect(Context context, String appID, String secretKey)
	{
		requestTapjoyConnect(context, appID, secretKey, null);
	}
	
	
	/**
	 * Performs the Tapjoy Connect call to the Tapjoy server to notify it that
	 * this device is running your application.
	 * 
	 * This method should be called in the onCreate() method of your first activity
	 * and before any other TapjoyConnect methods.
	 * <br>
	 * For special flags, this is a hashtable of special flags to send to enable non-standard settings.  See {@link TapjoyConnectFlag} for possible values.
	 * @param context						The application context.
	 * @param appID							Your Tapjoy APP ID.
	 * @param secretKey						Your Tapjoy SECRET KEY.
	 * @param flags							Special flags.
	 */
	public static void requestTapjoyConnect(Context context, String appID, String secretKey, Hashtable<String, String> flags)
	{
		TapjoyConnectCore.setSDKType(TapjoyConstants.TJC_SDK_TYPE_OFFERS);
		TapjoyConnectCore.setPlugin(TapjoyConstants.TJC_PLUGIN_NATIVE);
		
		tapjoyConnectInstance = new TapjoyConnect(context, appID, secretKey, flags);
		tapjoyOffers = new TJCOffers(context);
		tapjoyFeaturedApp = new TapjoyFeaturedApp(context);
		tapjoyDisplayAd = new TapjoyDisplayAd(context);
		tapjoyVideo = new TapjoyVideo(context);
		tapjoyEvent = new TapjoyEvent(context);
		
		tapjoyVideo.initVideoAd(new TapjoyVideoNotifier()
		{
			@Override
			public void videoReady(){}
			
			@Override
			public void videoError(int statusCode){}
			
			@Override
			public void videoComplete(){}
		}, true);
	}
	
	
	/**
	 * Returns the singleton instance of TapjoyConnect.
	 * @return 								Singleton instance of TapjoyConnect.
	 */
	public static TapjoyConnect getTapjoyConnectInstance()
	{
		if (tapjoyConnectInstance == null)
		{
			android.util.Log.e(TAPJOY_CONNECT, "----------------------------------------");
			android.util.Log.e(TAPJOY_CONNECT, "ERROR -- call requestTapjoyConnect before any other Tapjoy methods");
			android.util.Log.e(TAPJOY_CONNECT, "----------------------------------------");
		}
		
		return tapjoyConnectInstance;
	}
	
	
	/**
	 * Performs the Tapjoy Connect call to the Tapjoy server to notify it that
	 * this device is running your application.
	 * @param context						The application context.
	 * @param appID							Your Tapjoy APP ID.
	 * @param secretKey						Your Tapjoy SECRET KEY.
	 * @param flags							Special flags.
	 */
	private TapjoyConnect(Context context, String appID, String secretKey, Hashtable<String, String> flags)
	{
		TapjoyConnectCore.requestTapjoyConnect(context, appID, secretKey, flags);
	}
	
	
	/**
	 * Assigns a user ID for this user/device.  This is used to identify the user
	 * in your application.  The default user ID is the device id.
	 * @param userID						User ID you wish to assign to this device.
	 */
	public void setUserID(String userID)
	{
		android.util.Log.d("LIGHNING", "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!setUserID call, " + userID);
		TapjoyConnectCore.setUserID(userID);
	}
	
	
	/**
	 * Gets the user ID assigned to this device.  By default, this is the device ID.
	 * @return								User ID assigned to this device.
	 */
	public String getUserID()
	{
		return TapjoyConnectCore.getUserID();
	}
	
	
	/**
	 * Gets the Tapjoy App ID used to identify app.
	 * @return								Tapjoy App ID used to identify app.
	 */
	public String getAppID()
	{
		return TapjoyConnectCore.getAppID();
	}
	
	
	/**
	 * ONLY USE FOR PAID APP INSTALLS.<br>
	 * This method should be called in the onCreate() method of your first activity after calling
	 * {@link #requestTapjoyConnect(Context context, String appID, String secretKey)}.<br>
	 * Must enable a paid app Pay-Per-Action on the Tapjoy dashboard.
	 * Starts a 15 minute timer.  After which, will send an actionComplete call with the paid app PPA to
	 * inform the Tapjoy server that the paid install PPA has been completed.
	 * @param paidAppPayPerActionID			The Pay-Per-Action ID for this paid app download action. 
	 */
	public void enablePaidAppWithActionID(String paidAppPayPerActionID)
	{
		TapjoyConnectCore.getInstance().enablePaidAppWithActionID(paidAppPayPerActionID);
	}
	

	/**
	 * ONLY USE FOR NON-MANAGED (by TAPJOY) CURRENCY.<br>
	 * Sets the multiplier for the virtual currency displayed in Offers, Banner Ads, etc.  The default is 1.0
	 * @param multiplier
	 */
	public void setCurrencyMultiplier(float multiplier)
	{
		TapjoyConnectCore.getInstance().setCurrencyMultiplier(multiplier);
	}
	
	
	/**
	 * Gets the multiplier for the virtual currency display.
	 * @return
	 */
	public float getCurrencyMultiplier()
	{
		return TapjoyConnectCore.getInstance().getCurrencyMultiplier();
	}
	
	
	//================================================================================
	// PAY-PER-ACTION Methods
	//================================================================================
	
	
	/**
	 * Informs the Tapjoy server that the specified Pay-Per-Action was completed.  Should
	 * be called whenever a user completes an in-game action.
	 * @param actionID				The action ID of the completed action.
	 */
	public void actionComplete(String actionID)
	{
		TapjoyConnectCore.getInstance().actionComplete(actionID);
	}
	
	
	//================================================================================
	// OFFERS Methods
	//================================================================================
	
	
	/**
	 * Show available offers to the user.
	 */
	public void showOffers()
	{
		tapjoyOffers.showOffers();
	}
	
	
	/**
	 * Show available offers using a currencyID and currency selector flag.  
	 * This should only be used if the application supports multiple currencies and is NON-MANAGED by Tapjoy.
	 * @param currencyID				ID of the currency to display.
	 * @param enableCurrencySelector	Whether to display the currency selector to toggle currency.
	 */
	public void showOffersWithCurrencyID(String currencyID, boolean enableCurrencySelector)
	{
		tapjoyOffers.showOffersWithCurrencyID(currencyID, enableCurrencySelector);
	}
	
	
	/**
	 * Gets the virtual currency data from the server for this device.
	 * The data will be returned in a callback to updatePoints() to the class implementing the notifier.
	 * @param notifier The class implementing the TapjoyNotifier callback.
	 */
	public void getTapPoints(TapjoyNotifier notifier)
	{
		tapjoyOffers.getTapPoints(notifier);
	}
	

	/**
	 * Spends virtual currency.  This can only be used for currency managed by Tapjoy.
	 * The data will be returned in a callback to updatePoints() to the class implementing the notifier.
	 * @param notifier The class implementing the TapjoySpendPointsNotifier callback.
	 */
	public void spendTapPoints(int amount, TapjoySpendPointsNotifier notifier)
	{
		tapjoyOffers.spendTapPoints(amount, notifier);
	}
	
	
	/**
	 * Awards virtual currency.  This can only be used for currency managed by Tapjoy.
	 * The data will be returned in a callback to getAwardPointsResponse() to the class implementing the notifier.
	 * @param notifier The class implementing the TapjoyAwardPointsNotifier callback.
	 */
	public void awardTapPoints(int amount, TapjoyAwardPointsNotifier notifier)
	{
		tapjoyOffers.awardTapPoints(amount, notifier);
	}
	
	
	/**
	 * Sets the notifier which gets informed whenever virtual currency is earned.
	 * @param notifier						Class implementing TapjoyEarnedPointsNotifier.
	 */
	public void setEarnedPointsNotifier(TapjoyEarnedPointsNotifier notifier)
	{
		tapjoyOffers.setEarnedPointsNotifier(notifier);
	}
	
	
	//================================================================================
	// FEATURED APP Methods
	//================================================================================
	
	
	/**
	 * Retrieves the Full Screen Ad data from the server.
	 * Data is returned to the callback method TapjoyFeaturedAppNotifier.getFeaturedAppResponse().
	 * @param notifier				Class implementing TapjoyFeaturedAppNotifier for the Full Screen Ad data callback.
	 */
	public void getFeaturedApp(TapjoyFeaturedAppNotifier notifier)
	{
		tapjoyFeaturedApp.getFeaturedApp(notifier);
	}
	
	
	/**
	 * Retrieves the Full Screen Ad data from the server.
	 * Data is returned to the callback method TapjoyFeaturedAppNotifier.getFeaturedAppResponse().
	 * This should only be used if the application supports multiple currencies and is NON-MANAGED by Tapjoy.
	 * @param currencyID			ID of the currency to award.
	 * @param notifier				Class implementing TapjoyFeaturedAppNotifier for the Full Screen Ad data callback.
	 */
	public void getFeaturedAppWithCurrencyID(String currencyID, TapjoyFeaturedAppNotifier notifier)
	{
		tapjoyFeaturedApp.getFeaturedApp(currencyID, notifier);
	}
	
	
	/**
	 * Sets the maximum number of times the same full screen ad should be displayed.
	 * @param count					The maximum number of times to display a full screen ad.
	 */
	public void setFeaturedAppDisplayCount(int count)
	{
		tapjoyFeaturedApp.setDisplayCount(count);
	}
	
	
	/**
	 * Displays the Full Screen Ad fullscreen ad.
	 * Should be called after getFeaturedApp() and after receiving the TapjoyFeaturedAppNotifier.getFeaturedAppResponse callback. 
	 */
	public void showFeaturedAppFullScreenAd()
	{
		tapjoyFeaturedApp.showFeaturedAppFullScreenAd();
	}
	
	
	//================================================================================
	// Banner Ad Methods
	//================================================================================
	
	
	/**
	 * Sets the size (dimensions) of the banner ad.  By default this is 320x50.<br>
	 * Supported sizes are:<br>
	 * {@link TapjoyDisplayAdSize#TJC_AD_BANNERSIZE_320X50}<br>
	 * {@link TapjoyDisplayAdSize#TJC_AD_BANNERSIZE_640X100}<br>
	 * {@link TapjoyDisplayAdSize#TJC_AD_BANNERSIZE_768X90}<br>
	 * @param dimensions			Dimensions of the banner.
	 */
	public void setBannerAdSize(String dimensions)
	{
		tapjoyDisplayAd.setBannerAdSize(dimensions);
	}
	
	
	/**
	 * Enables automatic refreshing of the banner ads.  Default is FALSE.
	 * @param shouldAutoRefresh		Whether banner ad should auto-refresh or not.
	 */
	public void enableBannerAdAutoRefresh(boolean shouldAutoRefresh)
	{
		tapjoyDisplayAd.enableAutoRefresh(shouldAutoRefresh);
	}
	
	
	/**
	 * Retrieves the Banner Ad data from the server.
	 * Data is returned to the callback method TapjoyFeaturedAppNotifier.getFeaturedAppResponse().
	 * @param notifier				Class implementing TapjoyFeaturedAppNotifier for the Full Screen Ad data callback.
	 */
	public void getDisplayAd(TapjoyDisplayAdNotifier notifier)
	{
		tapjoyDisplayAd.getDisplayAd(notifier);
	}
	
	
	/**
	 * Retrieves the Banner Ad data from the server.
	 * Data is returned to the callback method TapjoyFeaturedAppNotifier.getFeaturedAppResponse().
	 * This should only be used if the application supports multiple currencies and is NON-MANAGED by Tapjoy.
	 * @param currencyID			ID of the currency to award.
	 * @param notifier				Class implementing TapjoyFeaturedAppNotifier for the Full Screen Ad data callback.
	 */
	public void getDisplayAdWithCurrencyID(String currencyID, TapjoyDisplayAdNotifier notifier)
	{
		tapjoyDisplayAd.getDisplayAd(currencyID, notifier);
	}
	
	
	//================================================================================
	// TAPJOY VIDEO Methods
	//================================================================================
	
	
	/**
	 * Initialize video ads so video offers can be made available via the offer wall.  Call this method if you wish
	 * to enable video offers.
	 */
	public void initVideoAd(TapjoyVideoNotifier notifier)
	{
		tapjoyVideo.initVideoAd(notifier);
	}
	
	
	/**
	 * Sets the limit of number of videos to keep in cache.  The default value is 5.
	 * @param count							Number of videos to cache.
	 */
	public void setVideoCacheCount(int count)
	{
		tapjoyVideo.setVideoCacheCount(count);
	}
	
	
	/**
	 * Sets whether to enable caching for videos.  By default this is enabled.
	 * @param enable						TRUE to enable video caching, FALSE to disable video caching.
	 */
	public void enableVideoCache(boolean enable)
	{
		tapjoyVideo.enableVideoCache(enable);
	}
	
	
	//================================================================================
	// Tapjoy Event Methods
	//================================================================================
	/**
	 * Event to send when app shuts down.
	 */
	public void sendShutDownEvent()
	{
		tapjoyEvent.sendShutDownEvent();
	}
	
	
	/**
	 * Event when an In-App-Purchased occurs.
	 * @param name							Item name.
	 * @param price							Item price (real life currency).
	 * @param quantity						Quantity of the item purchased.
	 * @param currencyCode					Real life currency code purchase was made in.
	 */
	public void sendIAPEvent(String name, float price, int quantity, String currencyCode)
	{
		tapjoyEvent.sendIAPEvent(name, price, quantity, currencyCode);
	}
}
