//
//  SPURLGenerator.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//


#import "SPURLParametersProvider.h"
#import "SPBaseURLProvider.h"


FOUNDATION_EXPORT NSString *const kSPURLParamKeyAllowCampaign;
FOUNDATION_EXPORT NSString *const kSPURLParamValueAllowCampaignOn;
FOUNDATION_EXPORT NSString *const kSPURLParamKeySkin;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyOffset;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyBackground;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyCurrencyName;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyClient;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyPlatform;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyRewarded;
FOUNDATION_EXPORT NSString *const kSPURLParamKeyAdFormat;

@class SPCredentials;


@interface SPURLGenerator : NSObject

@property (nonatomic, copy) NSString *baseURLString;

- (id)initWithBaseURLString:(NSString *)baseURLString;

- (id)initWithEndpoint:(SPURLEndpoint)endpoint;

+ (SPURLGenerator *)URLGeneratorWithBaseURLString:(NSString *)baseUrl;

- (void)setCredentials:(SPCredentials *)credentials;

+ (SPURLGenerator *)URLGeneratorWithEndpoint:(SPURLEndpoint)endpointKey;

- (void)setParameterWithKey:(NSString *)key stringValue:(NSString *)stringValue;

- (void)setParameterWithKey:(NSString *)key integerValue:(NSInteger)integerValue;

- (void)setParametersFromDictionary:(NSDictionary *)dictionary;

- (void)addParametersProvider:(id<SPURLParametersProvider>)paramsProvider;

+ (void)setGlobalCustomParametersProvider:(id<SPURLParametersProvider>)provider;


- (NSURL *)generatedURL;

- (NSURL *)signedURLWithSecretToken:(NSString *)secretToken addTimestamp:(BOOL)addTimestamp;

@end
