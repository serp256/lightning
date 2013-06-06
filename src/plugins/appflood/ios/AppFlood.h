//
//  AppFlood.h
//  AppFlood
//
//  Created by wodes lee on 12-9-12.
//  Copyright (c) 2012年 papaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CAAnimation.h>
#import <UIKit/UIKit.h>

#define APPFLOOD_BANNER_LARGE 10
#define APPFLOOD_BANNER_MIDDLE 11
#define APPFLOOD_BANNER_SMALL 12

#define APPFLOOD_PANEL_LANDSCAPE 20
#define APPFLOOD_PANEL_PORTRAIT 21

#define APPFLOOD_AD_NONE 0
#define APPFLOOD_AD_BANNER 1
#define APPFLOOD_AD_PANEL 2
#define APPFLOOD_AD_FULLSCREEN 4
#define APPFLOOD_AD_LIST 8
#define APPFLOOD_AD_DATA 16
#define APPFLOOD_AD_ALL 31

#define APPFLOOD_PANEL_TOP kCATransitionFromBottom
#define APPFLOOD_PANEL_BOTTOM kCATransitionFromTop

@protocol AFEventDelegate 

@optional
- (void) onClicked:(NSString *) ret;
- (void) onClosed:(NSString *) ret;
@end

@protocol AFRequestDelegate

@optional
- (void) onFinish: (id) ret;
@end

typedef void(^AFRequestDelegateBlock)(id ret);

@interface AFRequestDelegateWrapper : NSObject<AFRequestDelegate>
{
    AFRequestDelegateBlock _block;
}
@property(nonatomic, copy, readwrite) AFRequestDelegateBlock block;
- (id) initWithBlock:(AFRequestDelegateBlock) block;
@end




@interface AppFlood : NSObject
/**
 * initial AppFlood, you must use this function to init.
 * params:
 *  appId: the app key you get from www.appflood.com
 *  secretKey: the secret key you get from www.appflood.com
 *  adType: the ad type you want to show
 *
 **/
+ (void) initializeWithId : (NSString *) appId 
                      key : (NSString *) secretKey 
                   adType : (int) adType;

/**
 *
 * return: the ad type can shown. the ad type was set in initial.
 **/
+ (int) getAdType;

/**
 *  check does AppFlood conect to server success.
 **/
+ (BOOL) isConnected;

/**
 *  preload ad message.
 *  params:
 *   type: the ad type you want to preload.
 *   delegate: a delegate, if preload success the delegate would be called.
 **/
+ (void) preload: (int) type delegate: (id<AFRequestDelegate>) delegate;

/**
 * show fullscreen ad.
 **/
+ (void) showFullscreen;

/**
 * get a banner ad view controller.
 * params:
 *  type: banner type
 *  isAuto: does auto refresh ad.
 *
 * return: a view controller. You can use it in your codes.
 **/
+ (UIViewController*) newBannerViewController:(int) type isAuto: (BOOL) isAuto frame: (CGRect) frame;

/**
 * show panel ad.
 * params:
 *  type: the animate type when panel shown.
 **/
+ (void) showPanel: (NSString*) type;

/**
 * show list ad.
 * params:
 *  type: the animate type when list shown.
 **/
+ (void) showOfferWall: (NSString*) type;

/**
 * get ads data.
 * params:
 *  delegate: the animate type when panel shown.
 **/
+ (void) getRawData: (id<AFRequestDelegate>) delegate;

/**
 * used with getRawData, when the ad clicked, you should call this function for open download page and send cb.
 **/
+ (void) handleAFClick:(NSString*) backUrl clickUrl: (NSString*) clickUrl;
+ (void) setEventDelegate:(id<AFEventDelegate>) delegate;
+ (void) consumePoint: (int) point delegate: (id<AFRequestDelegate>) delegate;
+ (void) queryPoint: (id<AFRequestDelegate>) delegate;

/**
 * call it to release AppFlood.
 **/
+ (void) destroy;
@end
