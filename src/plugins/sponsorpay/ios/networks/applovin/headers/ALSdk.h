//
//  AppLovinSdk.h
//
//  Created by Basil Shikin on 2/1/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ALSdkSettings.h"
#import "ALAdService.h"
#import "ALTargetingData.h"

/**
 * Current SDK version
 */
extern NSString * const AlSdkVersion;

/**
 * This is a custom URI scheme that is used to Applovin specific actions. An 
 * example of such action would be:
 * <pre>
 *        applovin://com.applovin.sdk/adservice/track_click
 * </pre>
 */
extern NSString * const AlSdkUriScheme;

/**
 * This is a host name that is used to Applovin SDK custom actions
 */
extern NSString * const AlSdkUriHost;

/**
 * This is a base class for AppLovin Ad SDK.
 *
 * @version 1.0
 */
@interface ALSdk : NSObject

@property (readonly, strong) NSString *      sdkKey;

@property (readonly, strong) ALSdkSettings * settings;


/**
 * Get an instance of AppLovin Ad service. This service is
 * used to fetch ads from AppLovin servers, track clicks and
 * conversions.
 *
 * @return Ad service. Guaranteed not to be null.
 */
-(ALAdService *) adService;

/**
 * Get an instance of AppLovin Targeting data. This object contains
 * targeting values that could be provided to AppLovin for better
 * advertisement performance.
 *
 * @return Current targeting data. Guaranteed not to be null.
 */
-(ALTargetingData *) targetingData;

/**
 * Set Plugin version.
 *
 * @param string Plugin version to set.
 */
-(void) setPluginVersion: (NSString *) version;

/**
 * Initialize currnet version of the SDK
 *
 */
-(void) initializeSdk;

/**
 * Get a shared instance of AppLovin SDK. Please make sure that application's 
 * <code>Info.plist</code> includes a property 'AppLovinSdkKey' that is set to provided SDK key.
 * 
 * @return An instance of AppLovinSDK
 */
+(ALSdk *) shared;

/**
 * Initialize the default instance of AppLovin SDK. Please make sure that application's
 * <code>Info.plist</code> includes a property 'AppLovinSdkKey' that is set to provided SDK key.
 *
 * @return An instance of AppLovinSDK
 */
+(void) initializeSdk;

/**
 * Get an instance of AppLovin SDK.
 * 
 * @param sdkKey         SDK key to use. Must not be null.
 * @param userSettings   User-provided settings. Must not be null, but can be an empty [[ALSdkSettings alloc] init] object.
 * 
 * @return An instance of AppLovinSDK
 */
+(ALSdk *) sharedWithKey: (NSString *)sdkKey settings:(ALSdkSettings *)settings;

+(NSString *) version;

@end
