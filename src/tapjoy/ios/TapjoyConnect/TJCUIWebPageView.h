// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


#define TJCUIWEBPAGE_ACTIVITY_INDICATOR_SIZE	60
#define TJCUIWEBPAGE_ACTIVITY_RECT_SIZE			100
#define TJCUIWEBPAGE_LOADING_TEXT_RECT_HEIGHT	20

static const float LOADING_PAGE_START_ALPHA = 0.75f;	/*!< The target alpha value when the loading rect fades in. */
static const float LOADING_PAGE_END_ALPHA = 0.0f;		/*!< The target alpha value after the loading rect fades out. */
static const float LOADING_PAGE_FADE_TIME = 0.25f;		/*!< The amount of time in seconds that the loading rect fades in and out. */

/*!	\protocol TJCUIWebPageViewProtocol
 *	\brief The Tapjoy Connect Web Page protocol.
 */
@protocol TJCUIWebPageViewProtocol<NSObject>

@required

/*!	\fn tjcUIWebPageViewwebRequestCompleted
 *	\brief When library throws this event, the user can start showing his custom Ad.
 *  
 *	\param n/a
 *  \return n/a
 */
-(void) tjcUIWebPageViewwebRequestCompleted;

/*!	\fn tjcUIWebPageViewwebRequestCanceled
 *	\brief When library throws this event, the library wants its control back to continue its rotation.
 *  
 *	\param n/a
 *  \return n/a
 */
-(void) tjcUIWebPageViewwebRequestCanceled;

@end 


@class TJCLoadingView;

/*!	\interface TJCUIWebPageView
 *	\brief The Tapjoy Connect Web Page class.
 */
@interface TJCUIWebPageView : UIView <UIWebViewDelegate>
{
	UIWebView *cWebView_;			/*!< The UIWebView is used for embedding web content in the application. */
	NSString *lastClickedURL_;		/*!< Holds the last URL selected. */
	TJCLoadingView *loadingView_;	/*!< The loading view object, visible when the web view is loading content. */
	BOOL isViewVisible_;				/*!< Used to make sure that the web UIView is only refreshed when it is visible. */
	BOOL isAlertViewVisible_;		/*!< Indicates whether the retry message box is visible. */
	id delegate_;
}

@property (nonatomic, retain) TJCLoadingView *loadingView;
@property (nonatomic) BOOL isViewVisible;
@property (nonatomic) BOOL isAlertViewVisible;

/*!	\fn refreshWithFrame:(CGRect)frame
 *	\brief Refreshes the #TJCUIWebPageView with the given CGRect as the frame.
 *  
 *	\param aFrame The CGRect that represents the web page frame.
 *	\return n/a
 */
- (void)refreshWithFrame:(CGRect)frame;

- (void)setViewToTransparent:(BOOL)transparent;

/*!	\fn clearWebViewContents
 *	\brief Releases the web view object, effectively wiping the webview clean.
 *  
 *	\param n/a
 *	\return n/a
 */
- (void)clearWebViewContents;

/*!	\fn (BOOL)parseVideoClickURL:(NSString*)videoClickURL shouldPlayVideo:(BOOL)shouldPlay
 *	\brief Takes a video click URL, and initiates a video ad playback using 
 *  
 *	\param videoClickURL The video click URL contains a video offer id and click URL, called when the video is completed.
 *	\return n/a
 */
- (void)parseVideoClickURL:(NSString*)videoClickURL shouldPlayVideo:(BOOL)shouldPlay;

/*!	\fn loadURLRequest:withTimeOutInterval:(NSString* requestURLString, int tInterval)
 *	\brief The given NSURL contains a URL that the web page will navigate to.
 *  
 *	\param requestURL The NSString containing the URL for the web page.
 *	\param tInterval The timeout interval.
 *	\return n/a
 */
- (void)loadURLRequest:(NSString*)requestURLString withTimeOutInterval:(int)tInterval;

/*!	\fn appendGenericParamsWithURL:(NSString*)theURL
 *	\brief Appends the TJC generic parameters to the given URL.
 *  
 *	\param theURL The URL to append the generic params to.
 *	\return The URL string constructed from appending the generic parameters to the given URL.
 */
- (NSString*)appendGenericParamsWithURL:(NSString*)theURL;

- (void)setDelegate:(id)delegate;

@end
