// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

import android.view.View;

/**
 * 
 * Notifier class which sends callbacks whenever receiving Banner Ad data/response.
 *
 */
public interface TapjoyDisplayAdNotifier
{
	/**
	 * Callback containing Banner Ad data.
	 * @param featuredApObject			Object containing the Banner Ad data.
	 */
	public void getDisplayAdResponse(View adView);
	
	
	/**
	 * Callback when there is no Banner Ad data returned from the server. 
	 * This may be called when there are no Banner Ads available.
	 * @param error						Error message.
	 */
	public void getDisplayAdResponseFailed(String error);
}