//
//  MPAdConfiguration.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPInterstitialViewController.h"

enum {
    MPAdTypeUnknown = -1,
    MPAdTypeBanner = 0,
    MPAdTypeInterstitial = 1
};
typedef NSUInteger MPAdType;

extern NSString * const kAdTypeHeaderKey;
extern NSString * const kClickthroughHeaderKey;
extern NSString * const kCustomSelectorHeaderKey;
extern NSString * const kCustomEventClassNameHeaderKey;
extern NSString * const kCustomEventClassDataHeaderKey;
extern NSString * const kFailUrlHeaderKey;
extern NSString * const kHeightHeaderKey;
extern NSString * const kImpressionTrackerHeaderKey;
extern NSString * const kInterceptLinksHeaderKey;
extern NSString * const kLaunchpageHeaderKey;
extern NSString * const kNativeSDKParametersHeaderKey;
extern NSString * const kNetworkTypeHeaderKey;
extern NSString * const kRefreshTimeHeaderKey;
extern NSString * const kScrollableHeaderKey;
extern NSString * const kWidthHeaderKey;

extern NSString * const kInterstitialAdTypeHeaderKey;
extern NSString * const kOrientationTypeHeaderKey;

extern NSString * const kAdTypeHtml;
extern NSString * const kAdTypeInterstitial;
extern NSString * const kAdTypeMraid;

@interface MPAdConfiguration : NSObject
{
    NSDictionary *_headers;

    MPAdType _adType;
    NSString *_networkType;
    CGSize _preferredSize;
    NSURL *_clickTrackingURL;
    NSURL *_impressionTrackingURL;
    NSURL *_failoverURL;
    NSURL *_interceptURLPrefix;
    BOOL _shouldInterceptLinks;
    BOOL _scrollable;
    NSTimeInterval _refreshInterval;
    NSData *_adResponseData;
    NSString *_adResponseHTMLString;
    NSDictionary *_nativeSDKParameters;
    NSString *_customSelectorName;
    Class _customEventClass;
    NSDictionary *_customEventClassData;
    MPInterstitialOrientationType _orientationType;
}

@property (nonatomic, retain) NSDictionary *headers;
@property (nonatomic, assign) MPAdType adType;
@property (nonatomic, copy) NSString *networkType;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) CGSize preferredSize;
@property (nonatomic, retain) NSURL *clickTrackingURL;
@property (nonatomic, retain) NSURL *impressionTrackingURL;
@property (nonatomic, retain) NSURL *failoverURL;
@property (nonatomic, retain) NSURL *interceptURLPrefix;
@property (nonatomic, assign) BOOL shouldInterceptLinks;
@property (nonatomic, assign) BOOL scrollable;
@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, copy) NSData *adResponseData;
@property (nonatomic, retain) NSDictionary *nativeSDKParameters;
@property (nonatomic, copy) NSString *customSelectorName;
@property (nonatomic, assign) Class customEventClass;
@property (nonatomic, retain) NSDictionary *customEventClassData;
@property (nonatomic, assign) MPInterstitialOrientationType orientationType;

- (id)init;
- (id)initWithHeaders:(NSDictionary *)headers data:(NSData *)data;
- (NSURL *)URLFromHeaders:(NSDictionary *)headers forKey:(NSString *)key;
- (BOOL)hasPreferredSize;
- (NSString *)adResponseHTMLString;
- (NSString *)clickDetectionURLPrefix;

@end
