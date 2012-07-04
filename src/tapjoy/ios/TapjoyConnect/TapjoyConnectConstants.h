// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#define TJC_CONNECT_SUCCESS				@"TJC_Connect_Success"
#define TJC_CONNECT_FAILED					@"TJC_Connect_Failed"
#define TJC_OFFERS_SDK
#define TJC_SDK_TYPE_VALUE					@"offers"

// This notification is fired after getTapPoints has been called, and indicates that user currency amount has been received from the server.
#define TJC_TAP_POINTS_RESPONSE_NOTIFICATION					@"TJC_TAP_POINTS_RESPONSE_NOTIFICATION"
// This notification is fired after spendTapPoints has been called, and indicates that the user has successfully spent currency.
#define TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION			@"TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION"
// This notification is fired after awardTapPoints has been called, and indicates that the user has successfully been awarded currency.
#define TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION			@"TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION"

// Error notification for getTapPoints.
#define TJC_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR			@"TJC_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR"
// Error notification for spendTapPoints
#define TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR	@"TJC_SPEND_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR"
// Error notification for awardTapPoints
#define TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR	@"TJC_AWARD_TAP_POINTS_RESPONSE_NOTIFICATION_ERROR"

// Featured App notification is fired after full screen ad data is received from the server.
#define TJC_FEATURED_APP_RESPONSE_NOTIFICATION				@"TJC_FEATURED_APP_RESPONSE_NOTIFICATION"

// Notification that a user has just successfully completed an offer and earned currency. This only fires on init/resume.
#define TJC_TAPPOINTS_EARNED_NOTIFICATION						@"TJC_TAPPOINTS_EARNED_NOTIFICATION"

// Fired when any Tapjoy view is closed.
#define TJC_VIEW_CLOSED_NOTIFICATION							@"TJC_VIEW_CLOSED_NOTIFICATION"

#import "TJCViewCommons.h"
#import "TJCNetReachability.h"
#import "TJCOffersViewHandler.h"
#import "TJCUserAccountManager.h"
#import "TJCAdView.h"
#import "TJCAdDelegateProtocol.h"
#import "TJCFeaturedAppModel.h"
#import "TJCFeaturedAppViewHandler.h"
#import "TJCConstants.h"
#import "TJCLog.h"
#import "TJCFeaturedAppManager.h"
#import "TJCOffersWebView.h"
#import "TJCFeaturedAppView.h"
#import "TJCHardwareUtil.h"
#import "TJCCallsWrapper.h"
#import "TJCVideoViewHandler.h"
#import "TJCVideoView.h"
#import "TJCVideoManager.h"
#import "TJCAdDelegateProtocol.h"
#import "TJCVideoAdProtocol.h"