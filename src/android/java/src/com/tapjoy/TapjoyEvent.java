// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;


import android.content.Context;
import android.net.Uri;

public class TapjoyEvent
{
	private static TapjoyURLConnection tapjoyURLConnection = null;
	@SuppressWarnings("unused")
	private Context context;
	
	final static String TAPJOY_EVENT = "Event";
	
	public static final int EVENT_TYPE_IAP					= 1;
	public static final int EVENT_TYPE_SHUTDOWN				= 2;
	
	/**
	 * Constructor.
	 */
	public TapjoyEvent(Context ctx)
	{	
		context = ctx;
		tapjoyURLConnection = new TapjoyURLConnection();
	}
	
	
	/**
	 * Event to send when app shuts down.
	 */
	public void sendShutDownEvent()
	{
		sendEvent(EVENT_TYPE_SHUTDOWN, null);
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
		String params = createEventParameter(TapjoyConstants.TJC_EVENT_IAP_NAME) + "=" + Uri.encode(name);
		params += "&" + createEventParameter(TapjoyConstants.TJC_EVENT_IAP_PRICE) + "=" + Uri.encode("" + price);
		params += "&" + createEventParameter(TapjoyConstants.TJC_EVENT_IAP_QUANTITY) + "=" + Uri.encode("" + quantity);
		params += "&" + createEventParameter(TapjoyConstants.TJC_EVENT_IAP_CURRENCY_ID) + "=" + Uri.encode(currencyCode);
		sendEvent(EVENT_TYPE_IAP, params);
	}
	
	
	/**
	 * Converts an event specific parameter name into the desired format.
	 * @param parameter						Parameter name.
	 * @return								Formatted parameter name.
	 */
	public String createEventParameter(String parameter)
	{
		return "ue[" + parameter + "]";
	}
	
	
	/**
	 * Sends an event.
	 * @param type
	 * @param eventData
	 */
	public void sendEvent(int type, String eventData)
	{
		TapjoyLog.i(TAPJOY_EVENT, "sendEvent type: " + type);
		
		// Get verifier (uses event type).
		//String verifier = TapjoyConnectCore.getEventVerifier("" + type);
		
		String eventURLParams = TapjoyConnectCore.getURLParams();
		eventURLParams += "&" + TapjoyConstants.TJC_USER_ID + "=" + TapjoyConnectCore.getUserID();
		//eventURLParams += "&" + TapjoyConstants.TJC_VERIFIER + "=" + verifier;
		
		// Event type.
		eventURLParams += "&" + TapjoyConstants.TJC_EVENT_TYPE_ID + "=" + type;
		
		// Event data.
		if (eventData != null && eventData.length() > 0)
		{
			eventURLParams += "&" + eventData;
		}
		
		new Thread(new EventThread(eventURLParams)).start();
	}
	
	
	/**
	 * Thread to send event data.
	 */
	public class EventThread implements Runnable
	{
		private String params;
		
		public EventThread(String urlParams)
		{
			params = urlParams;
		}

		public void run()
		{
			TapjoyHttpURLResponse httpResponse = tapjoyURLConnection.getResponseFromURL(TapjoyConstants.TJC_SERVICE_URL + TapjoyConstants.TJC_EVENT_URL_PATH, params, TapjoyURLConnection.TYPE_POST);
			
			if (httpResponse != null) 
			{
				switch (httpResponse.statusCode)
				{
					// Success
					case 200:
						TapjoyLog.i(TAPJOY_EVENT, "Successfully sent Tapjoy event");
						break;
					
					// Error
					case 400:
						// Reason for error is in the response.
						TapjoyLog.e(TAPJOY_EVENT, "Error sending event: " + httpResponse.response);
						break;
						
					default:
						TapjoyLog.e(TAPJOY_EVENT, "Server/network error: " + httpResponse.statusCode);
						break;
				}
			}
			else
			{
				TapjoyLog.e(TAPJOY_EVENT, "Server/network error");
			}
		}
	}
}
