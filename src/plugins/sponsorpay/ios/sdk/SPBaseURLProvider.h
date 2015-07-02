//
//  SPBaseURLProvider.h
//  SponsorPayTestApp
//
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPURLEndpoint) {
    SPURLEndPointActions,
    SPURLEndpointInstalls,
    SPURLEndpointVCS,
    SPURLEndpointMBE,
    SPURLEndpointOfferWall,
    SPURLEndpointInterstitial,
    SPURLEndpointTracker,
    SPURLEndpointMBEJSCore,
    SPURLEndpointAdaptersConfig,
    SPURLEndpointVideoCache
};

@protocol SPURLProvider<NSObject>

@required
- (NSString *)urlForEndpoint:(SPURLEndpoint)endpointKey;
- (void)useSSLURLs:(BOOL)ssl;

@end


@interface SPBaseURLProvider : NSObject<SPURLProvider>

+ (SPBaseURLProvider *)sharedInstance;
- (NSString *)urlForEndpoint:(SPURLEndpoint)endpointKey;

#ifdef ENABLE_STAGING

@property (strong, nonatomic) id<SPURLProvider> customProvider;

- (void)overrideWithUrl:(NSString *)customUrl;
- (void)restoreUrlsToDefault;

#endif

@end
