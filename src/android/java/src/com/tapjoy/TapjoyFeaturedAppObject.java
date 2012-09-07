// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

/**
 * 
 * The TapjoyFeaturedAppObject represents a full screen ad object and is initialized when 
 * the server responds to the URL request for getting the feature app data is completed.
 * 
 */
public class TapjoyFeaturedAppObject
{
	/**	The cost of the full screen ad. */
	public String cost = "";
	
	/**	The store id of the full screen ad. */
	public String storeID = "";
	
	/**	The name of the full screen ad. */
	public String name = "";
	
	/**	The description for the full screen ad. */
	public String description = "";
	
	/**	The amount of virtual currency the user gets if they complete the full screen ad offer. */
	public int amount;
	
	/**	The URL to the location of the icon for the full screen ad. */
	public String iconURL = "";
	
	/**	The redirect URL for the full screen ad. */
	public String redirectURL = "";
	
	/**	The maximum number of times this feature app may appear. */
	public int maxTimesToDisplayThisApp;
	
	/**	The URL to the full screen Ad. This is used when the Tapjoy Full Screen Ad web view is used to display the full screen ad. */
	public String fullScreenAdURL = "";
	
	public TapjoyFeaturedAppObject()
	{
		
	}
}