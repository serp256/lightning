package com.tapjoy;

/**
 * Flags used in {@link TapjoyConnect#requestTapjoyConnect}
 */
public class TapjoyConnectFlag
{
	/**
	 * Sends the SHA2 hash of UDID/deviceID (IMEI/MEID/serial) in sha2_udid parameter instead of the udid parameter.<br>
	 * Use "true" as the flag value.<br>
	 * <b>CAN ONLY BE USED IN THE ADVERTISER/CONNECT SDK.</b>
	 */
	public static final String SHA_2_UDID				= "sha_2_udid";
	
	/**
	 * Sets the app to use a different market/app store other than Google Play.  If not set, Google Play will be used.<br>
	 * Use the alternate market name as the flag value.<br>
	 */
	public static final String ALTERNATE_MARKET			= "alternate_market";
	
	
	// Use these values when using the ALTERNATE_MARKET flag.
	public static final String MARKET_GFAN				= "gfan";
}
