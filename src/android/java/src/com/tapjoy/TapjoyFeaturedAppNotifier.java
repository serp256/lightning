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
 * Notifier class which sends callbacks whenever receiving Full Screen Ad data/response.
 *
 */
public interface TapjoyFeaturedAppNotifier
{
	/**
	 * Callback containing Full Screen Ad data.
	 * @param featuredAppObject			Object containing the Full Screen Ad data.
	 */
	public void getFeaturedAppResponse(TapjoyFeaturedAppObject featuredAppObject);
	
	
	/**
	 * Callback when there is no Full Screen Ad data returned from the server. 
	 * This may be called when there are no Full Screen Ads available.
	 * @param error						Error message.
	 */
	public void getFeaturedAppResponseFailed(String error);
}