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
		TapjoyConnectCore.setSDKType(TapjoyConstants.TJC_SDK_TYPE_CONNECT);
		TapjoyConnectCore.setPlugin(TapjoyConstants.TJC_PLUGIN_NATIVE);
		
		tapjoyConnectInstance = new TapjoyConnect(context, appID, secretKey, flags);
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
	
}
