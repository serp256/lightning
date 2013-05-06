//
//  MPAdConfiguration.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdConfiguration.h"

#import "MPConstants.h"
#import "MPGlobal.h"

#import "CJSONDeserializer.h"

NSString * const kAdTypeHeaderKey = @"X-Adtype";
NSString * const kClickthroughHeaderKey = @"X-Clickthrough";
NSString * const kCustomSelectorHeaderKey = @"X-Customselector";
NSString * const kCustomEventClassNameHeaderKey = @"X-Custom-Event-Class-Name";
NSString * const kCustomEventClassDataHeaderKey = @"X-Custom-Event-Class-Data";
NSString * const kFailUrlHeaderKey = @"X-Failurl";
NSString * const kHeightHeaderKey = @"X-Height";
NSString * const kImpressionTrackerHeaderKey = @"X-Imptracker";
NSString * const kInterceptLinksHeaderKey = @"X-Interceptlinks";
NSString * const kLaunchpageHeaderKey = @"X-Launchpage";
NSString * const kNativeSDKParametersHeaderKey = @"X-Nativeparams";
NSString * const kNetworkTypeHeaderKey = @"X-Networktype";
NSString * const kRefreshTimeHeaderKey = @"X-Refreshtime";
NSString * const kScrollableHeaderKey = @"X-Scrollable";
NSString * const kWidthHeaderKey = @"X-Width";

NSString * const kInterstitialAdTypeHeaderKey = @"X-Fulladtype";
NSString * const kOrientationTypeHeaderKey = @"X-Orientation";

NSString * const kAdTypeHtml = @"html";
NSString * const kAdTypeInterstitial = @"interstitial";
NSString * const kAdTypeMraid = @"mraid";

@interface MPAdConfiguration ()

@property (nonatomic, copy) NSString *adResponseHTMLString;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdConfiguration

@synthesize headers = _headers;
@synthesize adType = _adType;
@synthesize networkType = _networkType;
@synthesize preferredSize = _preferredSize;
@synthesize clickTrackingURL = _clickTrackingURL;
@synthesize impressionTrackingURL = _impressionTrackingURL;
@synthesize failoverURL = _failoverURL;
@synthesize interceptURLPrefix = _interceptURLPrefix;
@synthesize shouldInterceptLinks = _shouldInterceptLinks;
@synthesize scrollable = _scrollable;
@synthesize refreshInterval = _refreshInterval;
@synthesize adResponseData = _adResponseData;
@synthesize adResponseHTMLString = _adResponseHTMLString;
@synthesize nativeSDKParameters = _nativeSDKParameters;
@synthesize orientationType = _orientationType;
@synthesize customEventClass = _customEventClass;
@synthesize customEventClassData = _customEventClassData;
@synthesize adSize = _adSize;

- (id)init
{
    self = [super init];
    if (self) {
        _adType = MPAdTypeUnknown;
        _networkType = @"";
        _shouldInterceptLinks = YES;
        _scrollable = NO;
    }
    return self;
}

- (id)initWithHeaders:(NSDictionary *)headers data:(NSData *)data
{
    self = [self init];
    if (self) {
        _headers = [headers retain];
        _adType = [self adTypeFromHeaders:headers];

        _networkType = [[self networkTypeFromHeaders:headers] copy];
        _preferredSize = CGSizeMake([[headers objectForKey:kWidthHeaderKey] floatValue],
                                    [[headers objectForKey:kHeightHeaderKey] floatValue]);
        _clickTrackingURL = [[self URLFromHeaders:headers forKey:kClickthroughHeaderKey] retain];
        _impressionTrackingURL = [[self URLFromHeaders:headers forKey:kImpressionTrackerHeaderKey] retain];
        _failoverURL = [[self URLFromHeaders:headers forKey:kFailUrlHeaderKey] retain];
        _interceptURLPrefix = [[self URLFromHeaders:headers forKey:kLaunchpageHeaderKey] retain];
        _shouldInterceptLinks = [headers objectForKey:kInterceptLinksHeaderKey] ?
            [[headers objectForKey:kInterceptLinksHeaderKey] boolValue] : YES;

        _scrollable = [[headers objectForKey:kScrollableHeaderKey] boolValue];
        _refreshInterval = [self refreshIntervalFromHeaders:headers];
        _adResponseData = [data copy];
        _nativeSDKParameters = [[self dictionaryFromHeaders:headers
                                                     forKey:kNativeSDKParametersHeaderKey] retain];
        _customSelectorName = [[headers objectForKey:kCustomSelectorHeaderKey] copy];

        NSString *orientationTemp = [headers objectForKey:kOrientationTypeHeaderKey];
        if ([orientationTemp isEqualToString:@"p"]) {
            _orientationType = MPInterstitialOrientationTypePortrait;
        } else if ([orientationTemp isEqualToString:@"l"]) {
            _orientationType = MPInterstitialOrientationTypeLandscape;
        } else {
            _orientationType = MPInterstitialOrientationTypeAll;
        }

        NSString *className = [headers objectForKey:kCustomEventClassNameHeaderKey];
        _customEventClass = NSClassFromString(className);

        NSString *customEventJSONString = [headers objectForKey:kCustomEventClassDataHeaderKey];
        NSData *customEventJSONData = [customEventJSONString dataUsingEncoding:NSUTF8StringEncoding];
        CJSONDeserializer *deserializer = [CJSONDeserializer deserializerWithNullObject:NULL];
        _customEventClassData = [[deserializer deserializeAsDictionary:customEventJSONData
                                                                 error:NULL] retain];
    }
    return self;
}

- (void)dealloc
{
    [_headers release];
    [_networkType release];
    [_clickTrackingURL release];
    [_impressionTrackingURL release];
    [_failoverURL release];
    [_interceptURLPrefix release];
    [_adResponseData release];
    [_adResponseHTMLString release];
    [_nativeSDKParameters release];
    [_customSelectorName release];
    [_customEventClassData release];

    [super dealloc];
}

- (MPAdType)adTypeFromHeaders:(NSDictionary *)headers
{
    NSString *adTypeString = [headers objectForKey:kAdTypeHeaderKey];

    if ([adTypeString isEqualToString:@"interstitial"]) {
        return MPAdTypeInterstitial;
    } else if ([adTypeString isEqualToString:@"mraid"] &&
               [headers objectForKey:kOrientationTypeHeaderKey]) {
        return MPAdTypeInterstitial;
    } else if (adTypeString) {
        return MPAdTypeBanner;
    } else {
        return MPAdTypeUnknown;
    }
}

- (NSString *)networkTypeFromHeaders:(NSDictionary *)headers
{
    NSString *adTypeString = [headers objectForKey:kAdTypeHeaderKey];
    if ([adTypeString isEqualToString:@"interstitial"]) {
        return [headers objectForKey:kInterstitialAdTypeHeaderKey];
    } else {
        return adTypeString;
    }
}

- (NSURL *)URLFromHeaders:(NSDictionary *)headers forKey:(NSString *)key
{
    NSString *URLString = [headers objectForKey:key];
    return URLString ? [NSURL URLWithString:URLString] : nil;
}

- (NSDictionary *)dictionaryFromHeaders:(NSDictionary *)headers forKey:(NSString *)key
{
    NSData *data = [(NSString *)[headers objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding];
    CJSONDeserializer *deserializer = [CJSONDeserializer deserializerWithNullObject:NULL];
    return [deserializer deserializeAsDictionary:data error:NULL];
}

- (NSTimeInterval)refreshIntervalFromHeaders:(NSDictionary *)headers
{
    NSString *intervalString = [headers objectForKey:kRefreshTimeHeaderKey];
    NSTimeInterval interval = -1;
    if (intervalString) {
        interval = [intervalString doubleValue];
        if (interval < MINIMUM_REFRESH_INTERVAL) {
            interval = MINIMUM_REFRESH_INTERVAL;
        }
    }
    return interval;
}

- (BOOL)hasPreferredSize
{
    return (self.preferredSize.width > 0 && self.preferredSize.height > 0);
}

- (NSString *)adResponseHTMLString
{
    if (!_adResponseHTMLString) {
        _adResponseHTMLString = [[NSString alloc] initWithData:self.adResponseData
                                                      encoding:NSUTF8StringEncoding];
    }

    return _adResponseHTMLString;
}

- (NSString *)clickDetectionURLPrefix
{
    return self.interceptURLPrefix.absoluteString ? self.interceptURLPrefix.absoluteString : @"";
}

@end
