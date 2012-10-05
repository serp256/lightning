// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;

import org.w3c.dom.Document;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.ConnectivityManager;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import ru.redspell.lightning.utils.Log;

public class TapjoyConnectCore
{
	private static Context context = null;
	
	private static TapjoyConnectCore tapjoyConnectCore = null;
	private static TapjoyURLConnection tapjoyURLConnection = null;
	
	// URL parameter variables.
	private static String androidID = "";												// ANDROID_ID
	private static String deviceID = "";												// Device ID (IMEI/MEID).
	private static String sha2DeviceID = "";											// SHA-256 of DeviceID.
	private static String macAddress = "";												// Mac address.
	private static String sha1MacAddress = "";											// SHA-1 hash of the mac_address.
	private static String serialID = "";												// Serial ID.
	private static String deviceModel = "";												// Device type/model.
	private static String deviceManufacturer = "";										// Device manufacturer.
	private static String deviceType = "";												// Platform (iPhone, Android, etc).
	private static String deviceOSVersion = "";											// Android OS version.
	private static String deviceCountryCode = "";										// Default country code for this device.
	private static String deviceLanguage = "";											// Default language for this device.
	private static String appID = "";													// App ID.
	private static String appVersion = "";												// App version.
	private static String libraryVersion = "";											// Tapjoy Library version.
	private static String deviceScreenDensity = "";										// Screen density.
	private static String deviceScreenLayoutSize = "";									// Screen size.
	private static String userID = "";													// Publisher defined userID for this device.
	
	private static String platformName = "";											// Platform
	private static String carrierName = "";												// Carrier network.
	private static String carrierCountryCode = "";										// Carrier Country Code (ISO)
	private static String mobileCountryCode = "";										// Mobile Country Code (MCC)
	private static String mobileNetworkCode = "";										// Mobile Network Code (MNC)
	private static String connectionType = "";											// Connection type (MOBILE or WIFI)
	private static String marketName = "";												// Android app/market store to use.
	
	private static String secretKey= "";												// Secret key.
	private static String clientPackage = "";											// App package name.	
	private static String referralURL = "";												// Referral parameter (format is "referrer=com.package.name")
	
	private static String plugin = TapjoyConstants.TJC_PLUGIN_NATIVE;					// Plugin type, by default this will be "native"
	private static String sdkType = "";													// SDK type.
	
	private static boolean videoEnabled = false;										// Whether videos are enabled or not.
	private static boolean enableVideoCache = true;										// Whether video caching is enabled or not.
	private static String videoIDs = "";												// List of video IDs to pass to the offer wall.
	
	//private static int flags = 0;
	private static float currencyMultiplier = 1.0f;										// Currency Multiplier.
	
	public static final String TAPJOY_CONNECT 										= "TapjoyConnect";
	
	// PAID APP
	private static String paidAppActionID = null;										// Pay-Per-Action ID for the paid app.
	private long elapsed_time = 0;
	private Timer timer = null;
	
	private static Hashtable<String, String> connectFlags = null;
	
	private static String matchingPackageNames = "";
	
	/**
	 * Returns the singleton instance of this class.
	 * @return								Singleton instance of this class.
	 */
	public static TapjoyConnectCore getInstance()
	{
		return tapjoyConnectCore;
	}
	
	
	/**
	 * Connects to the Tapjoy server and sends the Tapjoy Connect call.
	 * @param applicationContext			The application context.
	 * @param app_ID						The Tapjoy APP ID for this app.
	 * @param secret_Key					The Tapjoy SECRET KEY for this app.
	 */
	public static void requestTapjoyConnect(Context applicationContext, String app_ID, String secret_Key)
	{
		requestTapjoyConnect(applicationContext, app_ID, secret_Key, null);
	}
	
	
	/**
	 * Connects to the Tapjoy server and sends the Tapjoy Connect call.
	 * @param applicationContext			The application context.
	 * @param app_ID						The Tapjoy APP ID for this app.
	 * @param secret_Key					The Tapjoy SECRET KEY for this app.
	 * @param connectFlags					Special flags to use.
	 */
	public static void requestTapjoyConnect(Context applicationContext, String app_ID, String secret_Key, Hashtable<String, String> flags)
	{
		appID = app_ID;
		secretKey = secret_Key;
		connectFlags = flags;
		tapjoyConnectCore = new TapjoyConnectCore(applicationContext);
	}
	
	
	/**
	 * Constructor.
	 * @param applicationContext			The application context.
	 */
	public TapjoyConnectCore(Context applicationContext)
	{
		context = applicationContext;
		tapjoyURLConnection = new TapjoyURLConnection();
		
		init();
		
		TapjoyLog.i(TAPJOY_CONNECT, "URL parameters: " + getURLParams());
		
		new Thread(new ConnectThread()).start();
	}
	
	
	/**
	 * Calls connect.  Helper method.
	 */
	public void callConnect()
	{
		new Thread(new ConnectThread()).start();
	}
	
	
	/**
	 * Constructs the generic URL parameters for the connect call.  Includes the verifier/timestamp parameter.
	 * Does NOT include:
	 *  	publisher_user_id				(publisher user ID)
	 *  	referrer						(for referral tracking)
	 * @return								Generic URL parameters used in the connect call.
	 */
	public static String getURLParams()
	{
		String urlParams = getGenericURLParams() + "&";
		String verifier = "";
		
		// Convert to seconds.
		long time = System.currentTimeMillis()/1000;
		verifier = getVerifier(time);
		
		urlParams += TapjoyConstants.TJC_TIMESTAMP + "=" + time + "&";
		urlParams += TapjoyConstants.TJC_VERIFIER + "=" + verifier;
		
		return urlParams;
	}
	
	
	/**
	 * Constructs the generic URL parameters.
	 * Does NOT include:
	 *  	publisher_user_id				(publisher user ID)
	 *  	referrer						(for referral tracking)
	 *  	verifier/timestamp
	 * @return								Generic URL parameters used in the connect call.
	 */
	public static String getGenericURLParams()
	{
		String urlParams = "";
		
		urlParams += TapjoyConstants.TJC_APP_ID_NAME + "=" + Uri.encode(appID) + "&";
		urlParams += getParamsWithoutAppID();
		
		return urlParams;
	}
	
	
	/**
	 * Constructs the generic URL parameters without an App ID.
	 * This is the base method for generating the URL parameters.
	 * Does NOT include:
	 * 		app_id							(App ID)
	 *  	publisher_user_id				(publisher user ID)
	 *  	referrer						(for referral tracking)
	 *  	verifier/timestamp
	 * @return								Generic URL parameters without app ID.
	 */
	private static String getParamsWithoutAppID()
	{
		String urlParams = "";
		
		// Construct the url parameters.
		urlParams += TapjoyConstants.TJC_ANDROID_ID + "=" + androidID + "&";
		
		// If this flag is set, then send sha2_udid instead of udid.
		if (getFlagValue(TapjoyConnectFlag.SHA_2_UDID) != null && getFlagValue(TapjoyConnectFlag.SHA_2_UDID).equals("true"))
		{
			urlParams += TapjoyConstants.TJC_SHA2_DEVICE_ID_NAME + "=" + Uri.encode(sha2DeviceID) + "&";
		}
		else
		{
			urlParams += TapjoyConstants.TJC_DEVICE_ID_NAME + "=" + Uri.encode(deviceID) + "&";
		}
		
		// Mac address.
		if (macAddress != null && macAddress.length() > 0)
		{
			// Only send SHA-1 mac_address.
			//urlParams += TapjoyConstants.TJC_DEVICE_MAC_ADDRESS + "=" + Uri.encode(macAddress) + "&";
			urlParams += TapjoyConstants.TJC_DEVICE_SHA1_MAC_ADDRESS + "=" + Uri.encode(sha1MacAddress) + "&";
		}
		
		// Serial ID.
		if (serialID != null && serialID.length() > 0)
		{
			urlParams += TapjoyConstants.TJC_DEVICE_SERIAL_ID + "=" + Uri.encode(serialID) + "&";
		}
		
		urlParams += TapjoyConstants.TJC_DEVICE_NAME + "=" + Uri.encode(deviceModel) + "&";
		urlParams += TapjoyConstants.TJC_DEVICE_MANUFACTURER + "=" + Uri.encode(deviceManufacturer) + "&";
		urlParams += TapjoyConstants.TJC_DEVICE_TYPE_NAME + "=" + Uri.encode(deviceType) + "&";
		urlParams += TapjoyConstants.TJC_DEVICE_OS_VERSION_NAME + "=" + Uri.encode(deviceOSVersion) + "&";
		urlParams += TapjoyConstants.TJC_DEVICE_COUNTRY_CODE + "=" + Uri.encode(deviceCountryCode) + "&";
		urlParams += TapjoyConstants.TJC_DEVICE_LANGUAGE + "=" + Uri.encode(deviceLanguage) + "&";
		urlParams += TapjoyConstants.TJC_APP_VERSION_NAME + "=" + Uri.encode(appVersion) + "&";
		urlParams += TapjoyConstants.TJC_CONNECT_LIBRARY_VERSION_NAME + "=" + Uri.encode(libraryVersion) + "&";
		urlParams += TapjoyConstants.TJC_PLATFORM + "=" + Uri.encode(platformName) + "&";
		
		// Virtual Currency Multiplier
		urlParams += TapjoyConstants.TJC_CURRENCY_MULTIPLIER + "=" + Uri.encode(Float.toString(currencyMultiplier));
		
		// Add carrier name.
		if (carrierName.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_CARRIER_NAME + "=" + Uri.encode(carrierName);
		}
		
		// Carrier country code.
		if (carrierCountryCode.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_CARRIER_COUNTRY_CODE + "=" + Uri.encode(carrierCountryCode);
		}
		
		// MCC
		if (mobileCountryCode.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_MOBILE_COUNTRY_CODE + "=" + Uri.encode(mobileCountryCode);
		}
		
		// MNC
		if (mobileNetworkCode.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_MOBILE_NETWORK_CODE + "=" + Uri.encode(mobileNetworkCode);
		}
		
		// Add device density and screen layout size.
		if (deviceScreenDensity.length() > 0 && deviceScreenLayoutSize.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_DEVICE_SCREEN_DENSITY + "=" + Uri.encode(deviceScreenDensity) + "&";		
			urlParams += TapjoyConstants.TJC_DEVICE_SCREEN_LAYOUT_SIZE + "=" + Uri.encode(deviceScreenLayoutSize);
		}
		
		// Connection type
		connectionType = getConnectionType();
		if (connectionType.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_CONNECTION_TYPE + "=" + Uri.encode(connectionType);
		}
		
		// Plugin
		if (plugin.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_PLUGIN + "=" + Uri.encode(plugin);
		}
		
		// SDK type.
		if (sdkType.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_SDK_TYPE + "=" + Uri.encode(sdkType);
		}
		
		// App store/market name.
		if (marketName.length() > 0)
		{
			urlParams += "&";
			urlParams += TapjoyConstants.TJC_MARKET_NAME + "=" + Uri.encode(marketName);
		}
		
		return urlParams;
	}
	
	
	/**
	 * Initialize data from the device information and application info.
	 * This data is used in our URL connection to the Tapjoy server. 
	 */
	private void init()
	{
		PackageManager manager = context.getPackageManager();
		
		try 
		{
			// ANDROID_ID
			androidID = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
			
			// Get app version.
			PackageInfo packageInfo = manager.getPackageInfo(context.getPackageName(), 0);
			appVersion = packageInfo.versionName;
			
			// Device platform.  Same as device type.
			deviceType = TapjoyConstants.TJC_DEVICE_PLATFORM_TYPE;
			platformName = TapjoyConstants.TJC_DEVICE_PLATFORM_TYPE;
			
			// Get the device model.
			deviceModel = android.os.Build.MODEL;
			deviceManufacturer = android.os.Build.MANUFACTURER;
			
			// Get the Android OS Version.
			deviceOSVersion = android.os.Build.VERSION.RELEASE;
			
			// Get the device country and language code.
			deviceCountryCode = Locale.getDefault().getCountry();
			deviceLanguage = Locale.getDefault().getLanguage();
			
			// Tapjoy SDK Library version.
			libraryVersion = TapjoyConstants.TJC_LIBRARY_VERSION_NUMBER;
			
			SharedPreferences settings = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
			
			try
			{
				TelephonyManager telephonyManager = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
				
				if (telephonyManager != null)
				{
					deviceID = telephonyManager.getDeviceId();
					
					carrierName = telephonyManager.getNetworkOperatorName();
					carrierCountryCode = telephonyManager.getNetworkCountryIso();
					
					// getNetworkOperator() returns MCC + MNC, so make sure it's 5 or 6 digits total.
					// MCC is 3 digits
					// MNC is 2 or 3 digits
					if (telephonyManager.getNetworkOperator() != null && (telephonyManager.getNetworkOperator().length() == 5 || telephonyManager.getNetworkOperator().length() == 6))
					{
						mobileCountryCode = telephonyManager.getNetworkOperator().substring(0, 3);
						mobileNetworkCode = telephonyManager.getNetworkOperator().substring(3);
					}
				}
				
				TapjoyLog.i(TAPJOY_CONNECT, "deviceID: " + deviceID);
				
				boolean invalidDeviceID = false;
				
				//----------------------------------------
				// Is the device ID null or empty?
				//----------------------------------------
				if (deviceID == null)
				{
					TapjoyLog.e(TAPJOY_CONNECT, "Device id is null.");
					invalidDeviceID = true;
				}
				else
				//----------------------------------------
				// Is this an emulator device ID?
				//----------------------------------------
				if (deviceID.length() == 0 || deviceID.equals("000000000000000") || deviceID.equals("0"))
				{
					TapjoyLog.e(TAPJOY_CONNECT, "Device id is empty or an emulator.");
					invalidDeviceID = true;
				}
				//----------------------------------------
				// Valid device ID.
				//----------------------------------------
				else
				{
					// Lower case the device ID.
					deviceID = deviceID.toLowerCase();
				}
				
				TapjoyLog.i(TAPJOY_CONNECT, "ANDROID SDK VERSION: " + android.os.Build.VERSION.SDK);
				
				
				// Is this at least Android 2.3+?
				// Then let's get the serial.
				if (Integer.parseInt(android.os.Build.VERSION.SDK) >= 9)
				{
					TapjoyLog.i(TAPJOY_CONNECT, "TRYING TO GET SERIAL OF 2.3+ DEVICE...");
					
					// THIS CLASS IS ONLY LOADED FOR ANDROID 2.3+
					TapjoyHardwareUtil hardware = new TapjoyHardwareUtil();
					
					serialID = hardware.getSerial();
					
					// Is there no IMEI or MEID?
					if (invalidDeviceID)
					{
						deviceID = serialID;
					}
					
					TapjoyLog.i(TAPJOY_CONNECT, "====================");
					TapjoyLog.i(TAPJOY_CONNECT, "SERIAL: deviceID: [" + deviceID + "]");
					TapjoyLog.i(TAPJOY_CONNECT, "====================");
					
					//----------------------------------------
					// Is the device ID null or empty?
					//----------------------------------------
					if (deviceID == null)
					{
						TapjoyLog.e(TAPJOY_CONNECT, "SERIAL: Device id is null.");
						invalidDeviceID = true;
					}
					else
					//----------------------------------------
					// Is this an emulator device ID?
					//----------------------------------------
					if (deviceID.length() == 0 || deviceID.equals("000000000000000") || deviceID.equals("0") || deviceID.equals("unknown"))
					{
						TapjoyLog.e(TAPJOY_CONNECT, "SERIAL: Device id is empty or an emulator.");
						invalidDeviceID = true;
					}
					//----------------------------------------
					// Valid device ID.
					//----------------------------------------
					else
					{
						// Lower case the device ID.
						deviceID = deviceID.toLowerCase();
						invalidDeviceID = false;
					}
				}
				
				
				// Is the device ID invalid?  This is probably an emulator or pre-production device.
				if (invalidDeviceID)
				{
					StringBuffer buff = new StringBuffer();
					buff.append("EMULATOR");
					String deviceId = settings.getString(TapjoyConstants.PREF_EMULATOR_DEVICE_ID, null);
					
					// Do we already have an emulator device id stored for this device?
					if( deviceId != null && !deviceId.equals(""))
					{
						deviceID = deviceId;
					}
					// Otherwise generate a deviceID for emulator testing.
					else
					{
						String constantChars = "1234567890abcdefghijklmnopqrstuvw";
						
						for (int i = 0; i < 32; i++)
						{
							int randomChar = (int) ( Math.random()* 100) ;
							int ch = randomChar % 30;
							buff.append(constantChars.charAt(ch));
						}
						
						deviceID = buff.toString().toLowerCase();
						
						// Save the emulator device ID in the prefs so we can reuse it.
						SharedPreferences.Editor editor = settings.edit();
						editor.putString(TapjoyConstants.PREF_EMULATOR_DEVICE_ID, deviceID);
						editor.commit();
					}
				}
			}
			catch(Exception e)
			{
				TapjoyLog.e(TAPJOY_CONNECT, "Error getting deviceID. e: " + e.toString());
				deviceID = null;
			}
			
			// Set the userID to the deviceID as the initial value.
			if (userID.length() == 0)
				userID = deviceID;
			
			// Save the SHA-2 hash of the device id.
			sha2DeviceID = TapjoyUtil.SHA256(deviceID);
			
			// Get screen density, dimensions and layout.
			try
			{
				// This is a backwards compatibility fix for Android 1.5 which has no display metric API.
				// If this is 1.6 or higher, then load the class, otherwise the class never loads and
				// no crash occurs.
				if (Integer.parseInt(android.os.Build.VERSION.SDK) > 3) 
				{
					TapjoyDisplayMetricsUtil displayMetricsUtil = new TapjoyDisplayMetricsUtil(context);
					
					deviceScreenDensity = "" + displayMetricsUtil.getScreenDensity();
					deviceScreenLayoutSize = "" + displayMetricsUtil.getScreenLayoutSize();
				}
			}
			catch (Exception e)
			{
				TapjoyLog.e(TAPJOY_CONNECT, "Error getting screen density/dimensions/layout: " + e.toString());
			}
			
			// Get mac address.
			try
			{
				WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

				if (wifiManager != null)
				{
					WifiInfo wifiInfo = wifiManager.getConnectionInfo();

					if (wifiInfo != null)
					{
						macAddress = wifiInfo.getMacAddress();

						if (macAddress != null && macAddress.length() > 0)
						{
							macAddress = macAddress.toUpperCase();
							sha1MacAddress = TapjoyUtil.SHA1(macAddress);
						}
					}
				}
			}
			catch (Exception e)
			{
				TapjoyLog.e(TAPJOY_CONNECT, "Error getting device mac address: " + e.toString());
			}
			
			// Alternate market.
			if (getFlagValue(TapjoyConnectFlag.ALTERNATE_MARKET) != null)
			{
				marketName = getFlagValue(TapjoyConnectFlag.ALTERNATE_MARKET);
				
				// Check for existing/supported market names.
				ArrayList <String> supportedMarketNames = new ArrayList<String>();
				supportedMarketNames.add(TapjoyConnectFlag.MARKET_GFAN);
				
				// Warning for undefined market names.
				if (!supportedMarketNames.contains(marketName))
				{
					Log.w(TAPJOY_CONNECT, "Warning -- undefined ALTERNATE_MARKET: " + marketName);
				}
			}
			
			// Get the referral URL
			String tempReferralURL = settings.getString(TapjoyConstants.PREF_REFERRAL_URL, null);
			if (tempReferralURL != null && !tempReferralURL.equals(""))
				referralURL = tempReferralURL;
			
			// Get the client package name.
			clientPackage = context.getPackageName();
			
			TapjoyLog.i(TAPJOY_CONNECT, "Metadata successfully loaded");
			
			TapjoyLog.i(TAPJOY_CONNECT, "APP_ID = [" + appID + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "ANDROID_ID: [" + androidID + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "CLIENT_PACKAGE = [" + clientPackage + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "deviceID: [" + deviceID + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "sha2DeviceID: [" + sha2DeviceID + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_DEVICE_SERIAL_ID + ": [" + serialID + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_DEVICE_MAC_ADDRESS + ": [" + macAddress + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_DEVICE_SHA1_MAC_ADDRESS + ": [" + sha1MacAddress + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "deviceName: [" + deviceModel + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "deviceManufacturer: [" + deviceManufacturer + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "deviceType: [" + deviceType + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "libraryVersion: [" + libraryVersion + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "deviceOSVersion: [" + deviceOSVersion + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "COUNTRY_CODE: [" + deviceCountryCode + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "LANGUAGE_CODE: [" + deviceLanguage + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "density: [" + deviceScreenDensity + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "screen_layout: [" + deviceScreenLayoutSize + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "carrier_name: [" + carrierName + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "carrier_country_code: [" + carrierCountryCode + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_MOBILE_COUNTRY_CODE + ": [" + mobileCountryCode + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_MOBILE_NETWORK_CODE + ": [" + mobileNetworkCode + "]");
			TapjoyLog.i(TAPJOY_CONNECT, "" + TapjoyConstants.TJC_MARKET_NAME + ": [" + marketName + "]");
			
			TapjoyLog.i(TAPJOY_CONNECT, "referralURL: [" + referralURL + "]");
			
			if (connectFlags != null)
			{
				TapjoyLog.i(TAPJOY_CONNECT, "Connect Flags:");
				TapjoyLog.i(TAPJOY_CONNECT, "--------------------");
				
				Set<Entry<String, String>> entries = connectFlags.entrySet();
				Iterator<Entry<String, String>> iterator = entries.iterator();

				while (iterator.hasNext())
				{
					Entry<String, String> item = iterator.next();
					TapjoyLog.i(TAPJOY_CONNECT, "key: " + item.getKey() + ", value: " + Uri.encode(item.getValue()));
				}
			}
		}
		catch (Exception e) 
		{
			TapjoyLog.e(TAPJOY_CONNECT, "Error initializing Tapjoy parameters.  e=" + e.toString());
		}
	}
	
	
	/**
	 * Timer which executes the actionComplete with paid app actionID once completed.
	 */
	private class PaidAppTimerTask extends TimerTask
	{
		public void run()
		{
			elapsed_time += TapjoyConstants.TIMER_INCREMENT;

			TapjoyLog.i(TAPJOY_CONNECT, "elapsed_time: " + elapsed_time + " (" + elapsed_time / 1000 / 60 + "m " + (elapsed_time / 1000 % 60) + "s)");

			SharedPreferences prefs = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
			SharedPreferences.Editor editor = prefs.edit();
			editor.putLong(TapjoyConstants.PREF_ELAPSED_TIME, elapsed_time);
			editor.commit();

			// Have 15 minutes passed?
			if (elapsed_time >= TapjoyConstants.PAID_APP_TIME)
			{
				TapjoyLog.i(TAPJOY_CONNECT, "timer done...");

				// If there is a valid paid app action ID, then trigger the PPA.
				if (paidAppActionID != null && paidAppActionID.length() > 0)
				{
					TapjoyLog.i(TAPJOY_CONNECT, "Calling PPA actionComplete...");

					actionComplete(paidAppActionID);
				}

				cancel();
			}
		}
	}
	
	
	/**
	 * Handles the response from calling Connect.
	 * @param response					HTTP response from the server.
	 * @return							TRUE if the response is handled and notifier has been called, FALSE otherwise.
	 */
	private static boolean handleConnectResponse(String response)
	{
		// Create a document so we can parse the XML easily.
		Document document = TapjoyUtil.buildDocument(response);
		
		if (document != null)
		{
			String nodeValue = TapjoyUtil.getNodeTrimValue(document.getElementsByTagName("PackageNames"));

			// Parse package names.
			if (nodeValue != null && nodeValue.length() > 0)
			{
				String data = nodeValue;
				Vector<String> allPackageNames = new Vector<String>();
				
				int current = 0;
				int index = -1;
				
				while (true)
				{
					index = data.indexOf(',', current);
					
					// No commas left, grab the rest of the string.
					if (index == -1)
					{
						// Trim whitespace.
						TapjoyLog.i(TAPJOY_CONNECT, "parse: " + data.substring(current).trim());
						allPackageNames.add(data.substring(current).trim());
						break;
					}
					// Comma found, so get the substring.
					else
					{
						// Trim whitespace.
						TapjoyLog.i(TAPJOY_CONNECT, "parse: " + data.substring(current, index).trim());
						allPackageNames.add(data.substring(current, index).trim());
						current = index+1;
					}
				}
				
				matchingPackageNames = "";
				
				List <ApplicationInfo> applications = context.getPackageManager().getInstalledApplications(0);
				for (ApplicationInfo appInfo : applications)
				{
					// System app.
					if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) == 1)
					{
						//android.util.Log.i(TAPJOY, "system: " + appInfo.packageName);
					}
					// User installed app.
					else
					{
						if (allPackageNames.contains(appInfo.packageName))
						{
							TapjoyLog.i(TAPJOY_CONNECT, "MATCH: installed packageName: " + appInfo.packageName);
							
							// Comma separate if there are previous entries.
							if (matchingPackageNames.length() > 0)
								matchingPackageNames += ",";
							
							matchingPackageNames += appInfo.packageName;
						}
					}
				}
			}
			
			nodeValue = TapjoyUtil.getNodeTrimValue(document.getElementsByTagName("Success"));
			
			// The Tapjoy Connect call was successful.
			if (nodeValue != null && nodeValue.equals("true"))
			{
				//TapjoyLog.i(TAPJOY_CONNECT, "Successfully connected to tapjoy site.");
				return true;
			}
//			else
//			{
//				TapjoyLog.e(TAPJOY_CONNECT, "Tapjoy Connect call failed.");
//			}
		}
		
		return true;
	}
	
	
	/**
	 * Handles the response from a completed Pay-Per-Action.
	 * @param response					HTTP response from the server.
	 * @return							TRUE if the response is handled and notifier has been called, FALSE otherwise.
	 */
	private boolean handlePayPerActionResponse(String response)
	{
		// Create a document so we can parse the XML easily.
		Document document = TapjoyUtil.buildDocument(response);
		
		if (document != null)
		{
			String nodeValue = TapjoyUtil.getNodeTrimValue(document.getElementsByTagName("Success"));
			
			// The Tapjoy Connect call was successful.
			if (nodeValue != null && nodeValue.equals("true"))
			{
				TapjoyLog.i(TAPJOY_CONNECT, "Successfully sent completed Pay-Per-Action to Tapjoy server.");
				return true;
			}
			else
			{
				TapjoyLog.e(TAPJOY_CONNECT, "Completed Pay-Per-Action call failed.");
			}
		}
		
		return false;
	}

	
	/**
	 * Releases the TapjoyConnectInstance object. This must be called whenever the application exits.
	 */
	public void release()
	{
		tapjoyConnectCore = null;
		tapjoyURLConnection = null;
		
		TapjoyLog.i(TAPJOY_CONNECT, "Releasing core static instance.");
	}
	

	//================================================================================
	// HELPER Methods
	//================================================================================
	
	
	/**
	 * Gets the Tapjoy App ID.
	 * @return								The Tapjoy App ID.
	 */
	public static String getAppID()
	{
		return appID;
	}
	
	
	/**
	 * Gets the unique identifier for this device.
	 * @return								The device ID.
	 */
	public static String getDeviceID()
	{
		return deviceID;
	}
	
	
	/**
	 * Gets the user ID for this device.
	 * @return								The user ID for this device.
	 */
	public static String getUserID()
	{
		return userID;
	}
	
	
	/**
	 * Returns the video IDs to pass to the offer wall.
	 * @return								The video IDs that are cached.
	 */
	public static String getVideoIDs()
	{
		return videoIDs;
	}
	
	
	/**
	 * Gets carrier name for this device.
	 * @return								The carrier name for this device.
	 */
	public static String getCarrierName()
	{
		return carrierName;
	}
	
	
	/**
	 * Gets the connection type used by this device ("mobile" or "wifi").
	 * @return								Connection type the device is using.
	 */
	public static String getConnectionType()
	{
		String type = "";
		
		// Adding this try/catch for weird nullPointerException issue which rarely occurs on certain hardware ?
		try
		{
			// Get connection type.
			ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
			
			// Might be null on airplane mode.
			if (connectivityManager != null && connectivityManager.getActiveNetworkInfo() != null)
			{
				switch (connectivityManager.getActiveNetworkInfo().getType())
				{
					case ConnectivityManager.TYPE_WIFI:
					case 0x6:	//case ConnectivityManager.TYPE_WIMAX is 0x6
						type = "wifi";
						break;
					default:
						type = "mobile";
						break;
				}
				
				TapjoyLog.i(TAPJOY_CONNECT, "connectivity: " + connectivityManager.getActiveNetworkInfo().getType());
				TapjoyLog.i(TAPJOY_CONNECT, "connection_type: " + type);
			}
		}
		catch (Exception e)
		{
			TapjoyLog.e(TAPJOY_CONNECT, "getConnectionType error: " + e.toString());
		}
		
		return type;
	}
	
	
	/**
	 * Gets the app package name.
	 * @return								The app package name.
	 */
	public static String getClientPackage()
	{
		return clientPackage;
	}
	
	
	/**
	 * Gets The application context.
	 * @return								The application context.
	 */
	public static Context getContext()
	{
		return context;
	}
	
	
	/**
	 * Returns the verifier hash.
	 * The format is:
	 * appID:deviceID:timestamp:secretKey
	 * @param time							Time in seconds since 1/1/1970
	 * @return								The verifier hash.
	 */
	public static String getVerifier(long time)
	{
		String verifier = "";
		
		try
		{
			// Verifier format:
			// "app_id:device_id:time_stamp:secret_key"
			verifier = TapjoyUtil.SHA256(appID + ":" + deviceID + ":" + time + ":" + secretKey);
		}
		catch (Exception e)
		{
			TapjoyLog.e(TAPJOY_CONNECT, "getVerifier ERROR: " + e.toString());
		}
		
		return verifier;
	}
	
	
	/**
	 * Returns the verifier hash for awardTapPoints
	 * The format is:
	 * appID:deviceID:timestamp:secretKey:amount:guid
	 * @param time							Time in seconds since 1/1/1970
	 * @return								The verifier hash.
	 */
	public static String getAwardPointsVerifier(long time, int amount, String guid)
	{
		String verifier = "";
		
		try
		{
			// Verifier format:
			// "app_id:udid:time_stamp:secret_key:tap_points:guid"
			verifier = TapjoyUtil.SHA256(appID + ":" + deviceID + ":" + time + ":" + secretKey + ":" + amount + ":" + guid);
		}
		catch (Exception e)
		{
			TapjoyLog.e(TAPJOY_CONNECT, "getAwardPointsVerifier ERROR: " + e.toString());
		}
		
		return verifier;
	}
	
	
	/**
	 * Returns the verifier hash for event tracking
	 * The format is:
	 * appID:deviceID:ecretKey:eventData
	 * @param eventData						Event tracking data.
	 * @return								The verifier hash.
	 */
	public static String getEventVerifier(String eventData)
	{
		String verifier = "";
		
		try
		{
			// Verifier format:
			// "appID:deviceID:ecretKey:eventData"
			verifier = TapjoyUtil.SHA256(appID + ":" + deviceID + ":"  + secretKey + ":" + eventData);
		}
		catch (Exception e)
		{
			TapjoyLog.e(TAPJOY_CONNECT, "getEventVerifier ERROR: " + e.toString());
		}
		
		return verifier;
	}
	
	
	/**
	 * Returns the verifier hash.
	 * The format is:
	 * appID:deviceID:timestamp:secretKey:<comma separated package names>
	 * @param time							Time in seconds since 1/1/1970
	 * @return								The verifier hash.
	 */
	public static String getPackageNamesVerifier(long time, String packageNames)
	{
		String verifier = "";
		
		try
		{
			// Verifier format:
			// "app_id:device_id:time_stamp:secret_key"
			verifier = TapjoyUtil.SHA256(appID + ":" + deviceID + ":" + time + ":" + secretKey + ":" + packageNames);
		}
		catch (Exception e)
		{
			TapjoyLog.e(TAPJOY_CONNECT, "getVerifier ERROR: " + e.toString());
		}
		
		return verifier;
	}
	
	
	/**
	 * Sets the plugin type.
	 * @param name							Name of the plugin.
	 */
	public static void setPlugin(String name)
	{
		plugin = name;
	}
	
	
	/**
	 * Sets the sdk type.
	 * @param name							Type of sdk.
	 */
	public static void setSDKType(String name)
	{
		sdkType = name;
	}
	
	
	/**
	 * Sets the user ID for this device.  This is used by the publisher to identify the user for their app.
	 * This needs to be called before any call to Offers, Full Screen Ad, etc.
	 * If this method is not called, the device ID will be used by default.
	 * @param id							User ID which is used to identify this user for this device.
	 */
	public static void setUserID(String id)
	{
		userID = id;
		
		TapjoyLog.i(TAPJOY_CONNECT, "URL parameters: " + getURLParams());
		
		// Send request to server.
		new Thread(new Runnable() 
		{
			public void run() 
			{
				TapjoyLog.i(TAPJOY_CONNECT, "setUserID...");
				
				String connectURLParams = getURLParams();
				
				connectURLParams += "&" + TapjoyConstants.TJC_USER_ID + "=" + getUserID();
				
				// The referralURL contains both referrer parameter and its value e.g. referralURL="referrer=com.tapjoy.tapX"
		        if (!referralURL.equals(""))
		        {
		            // Pass referral parameters to connect call to Tapjoy server
		        	connectURLParams += "&" + referralURL;
		        }
				
				// Get the result of the http request.
				String result = tapjoyURLConnection.connectToURL(TapjoyConstants.TJC_SERVICE_URL + TapjoyConstants.TJC_USER_ID_URL_PATH, connectURLParams);
				
				// Handle the response for a connect call.
				if (result != null)
				{
					if (handleConnectResponse(result));
						TapjoyLog.i(TAPJOY_CONNECT, "setUserID successful...");
				}
			}
		}).start();
	}
	
	
	/**
	 * Sets the video IDs to pass to the offer wall.
	 * @param ids							Video/Offer IDs.
	 */
	public static void setVideoIDs(String ids)
	{
		videoIDs = ids;
	}
	
	
	/**
	 * Sets a flag that video ads are enabled.
	 * @param enabled						Whether videos are enabled or not.
	 */
	public static void setVideoEnabled(boolean enabled)
	{
		videoEnabled = enabled;
	}
	
	
	/**
	 * Sets whether to enable caching for videos.  By default this is enabled.
	 * @param enable						TRUE to enable video caching, FALSE to disable video caching.
	 */
	public static void enableVideoCache(boolean enable)
	{
		enableVideoCache = enable;
	}
	
	
	/**
	 * Whether video caching is enabled or not.
	 * @return								Whether video caching is enabled or not.
	 */
	public static  boolean isVideoCacheEnabled()
	{
		return enableVideoCache;
	}
	
	
	/**
	 * Returns true or false depending on whether videos are enabled.
	 * @return								Boolean indicating whether videos are enabled or not.
	 */
	public static boolean isVideoEnabled()
	{
		return videoEnabled;
	}
	
	
	/**
	 * Sets the device ID for debugging purposes.  This only works when the deviceID is invalid for this device (simulator/emulator).
	 * @param id							String to use as the deviceID.
	 */
	public static void setDebugDeviceID(String id)
	{
		deviceID = id;
		
		SharedPreferences settings = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
		
		// Save the emulator device ID in the prefs so we can reuse it.
		SharedPreferences.Editor editor = settings.edit();
		editor.putString(TapjoyConstants.PREF_EMULATOR_DEVICE_ID, deviceID);
		editor.commit();
	}
	
	
	/**
	 * Saves the current tap points total to be stored locally.
	 * @param total							Amount of tap points the user has.
	 */
	public static void saveTapPointsTotal(int total)
	{
		SharedPreferences settings = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
		
		// Save the tap points total.
		SharedPreferences.Editor editor = settings.edit();
		editor.putInt(TapjoyConstants.PREF_LAST_TAP_POINTS, total);
		editor.commit();
	}
	
	
	/**
	 * Gets the tap points total from that was locally stored by saveTapPointsTotal.  If -9999 is returned,
	 * then no data was previously stored.
	 * @return								Amount of tap points the user has.
	 */
	public static int getLocalTapPointsTotal()
	{
		SharedPreferences settings = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
		
		int total = settings.getInt(TapjoyConstants.PREF_LAST_TAP_POINTS, -9999);
		return total;
	}
	
	
	//================================================================================
	// Core TapjoyConnect Methods
	//================================================================================
	
	
	/**
	 * Informs the Tapjoy server that the specified Pay-Per-Action was completed. 
	 * @param actionID				The action ID of the completed action.
	 */
	public void actionComplete(String actionID)
	{
		TapjoyLog.i(TAPJOY_CONNECT, "actionComplete: " + actionID);
		
		// The PPA call is identical to Connect except the PPA ID is passed as the app_id parameter.
		String actionURLParams = TapjoyConstants.TJC_APP_ID_NAME + "=" + actionID + "&";

		actionURLParams += getParamsWithoutAppID();
		
		// Only send publisher_user_id if this flag is NOT set.
		if (getFlagValue(TapjoyConnectFlag.SHA_2_UDID) == null || !getFlagValue(TapjoyConnectFlag.SHA_2_UDID).equals("true"))
		{
			actionURLParams += "&" + TapjoyConstants.TJC_USER_ID + "=" + TapjoyConnectCore.getUserID();
		}
		
		// Add verifier.
		actionURLParams += "&";
		
		// Convert to seconds.
		long time = System.currentTimeMillis()/1000;		
		actionURLParams += TapjoyConstants.TJC_TIMESTAMP + "=" + time + "&";
		actionURLParams += TapjoyConstants.TJC_VERIFIER + "=" + getVerifier(time);
		
		TapjoyLog.i(TAPJOY_CONNECT, "PPA URL parameters: " + actionURLParams);
		
		new Thread(new PPAThread(actionURLParams)).start();
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
		TapjoyLog.i(TAPJOY_CONNECT, "enablePaidAppWithActionID: " + paidAppPayPerActionID);
		
		paidAppActionID = paidAppPayPerActionID;
		
		SharedPreferences prefs = context.getSharedPreferences(TapjoyConstants.TJC_PREFERENCE, 0);
		
		// Load the stored elapsed time from the prefs.
		elapsed_time = prefs.getLong(TapjoyConstants.PREF_ELAPSED_TIME, 0);
		
		TapjoyLog.i(TAPJOY_CONNECT, "paidApp elapsed: " + elapsed_time);
		
		// If elapsed time is enough, then call the paid app PPA.
		if (elapsed_time >= TapjoyConstants.PAID_APP_TIME)
		{
			// If there is a valid paid app action ID, then trigger the PPA.
			if (paidAppActionID != null && paidAppActionID.length() > 0)
			{
				TapjoyLog.i(TAPJOY_CONNECT, "Calling PPA actionComplete...");
				
				actionComplete(paidAppActionID);
			}
		}
		else
		// Only have 1 timer running at a time.
		if (timer == null)
		{
			timer = new Timer();
			timer.schedule(new PaidAppTimerTask(), TapjoyConstants.TIMER_INCREMENT, TapjoyConstants.TIMER_INCREMENT);
		}
	}
	

	/**
	 * Thread to run connect and do sdkless verification.
	 */
	public class ConnectThread implements Runnable
	{
		public void run() 
		{
			TapjoyLog.i(TAPJOY_CONNECT, "starting connect call...");
			
			String connectURLParams = getURLParams();
			
			// Get the result of the http request.
			TapjoyHttpURLResponse httpResponse = tapjoyURLConnection.getResponseFromURL(TapjoyConstants.TJC_SERVICE_URL + TapjoyConstants.TJC_CONNECT_URL_PATH, connectURLParams);
			
			// Handle the response for a connect call.
			if (httpResponse != null && httpResponse.statusCode == org.apache.http.HttpStatus.SC_OK)
			{
				if (handleConnectResponse(httpResponse.response))
					TapjoyLog.i(TAPJOY_CONNECT, "Successfully connected to tapjoy site.");
				
				// Valid data.
				if (matchingPackageNames.length() > 0)
				{
					String params = getGenericURLParams() + "&" + TapjoyConstants.TJC_PACKAGE_NAMES + "=" + matchingPackageNames + "&";
					String verifier = "";
					
					// Convert to seconds.
					long time = System.currentTimeMillis()/1000;
					verifier = getPackageNamesVerifier(time, matchingPackageNames);
					
					params += TapjoyConstants.TJC_TIMESTAMP + "=" + time + "&";
					params += TapjoyConstants.TJC_VERIFIER + "=" + verifier;
					
					httpResponse = tapjoyURLConnection.getResponseFromURL(TapjoyConstants.TJC_SERVICE_URL + TapjoyConstants.TJC_SDK_LESS_CONNECT, params);
					
					// Handle the response for a connect call.
					if (httpResponse != null && httpResponse.statusCode == org.apache.http.HttpStatus.SC_OK)
						TapjoyLog.i(TAPJOY_CONNECT, "Successfully pinged sdkless api.");
				}
			}
		}
	}
	
		
	/**
	 * Thread to run PPA request.
	 *
	 */
	public class PPAThread implements Runnable
	{
		private String params;
		
		public PPAThread(String urlParams)
		{
			params = urlParams;
		}

		public void run()
		{
			// Get the result of the http request.
			String result = tapjoyURLConnection.connectToURL(TapjoyConstants.TJC_SERVICE_URL + TapjoyConstants.TJC_CONNECT_URL_PATH, params);
			
			// Handle the response for a connect call.
			if (result != null)
				handlePayPerActionResponse(result);
		}
	}
	
	
	/**
	 * ONLY USE FOR NON-MANAGED (by TAPJOY) CURRENCY.<br>
	 * Sets the multiplier for the virtual currency displayed in Offers, Banner Ads, etc.  The default is 1.0
	 * @param multiplier
	 */
	public void setCurrencyMultiplier(float multiplier)
	{
		TapjoyLog.i(TAPJOY_CONNECT, "setVirtualCurrencyMultiplier: " + multiplier);
		currencyMultiplier = multiplier;
	}
	
	
	/**
	 * Gets the multiplier for the virtual currency display.
	 * @return
	 */
	public float getCurrencyMultiplier()
	{
		return currencyMultiplier;
	}
	
	
	/**
	 * Gets the flag value from the connectFlags table.
	 * @param key							Key to search for.
	 * @return								Value of the key.
	 */
	private static String getFlagValue(String key)
	{
		if (connectFlags != null)
		{
			return connectFlags.get(key);
		}
		
		return null;
	}
}
