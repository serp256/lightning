//
//  MPAdServerURLBuilder.m
//  MoPub
//
//  Copyright (c) 2012 MoPub. All rights reserved.
//

#import "MPAdServerURLBuilder.h"

#import "MPConstants.h"
#import "MPGlobal.h"
#import "MPKeywordProvider.h"
#import "MPIdentityProvider.h"

NSString * const kMoPubInterfaceOrientationPortrait = @"p";
NSString * const kMoPubInterfaceOrientationLandscape = @"l";

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPAdServerURLBuilder ()

+ (NSString *)queryParameterForKeywords:(NSString *)keywords;
+ (NSString *)queryParameterForOrientation;
+ (NSString *)queryParameterForScaleFactor;
+ (NSString *)queryParameterForTimeZone;
+ (NSString *)queryParameterForLocationArray:(NSArray *)locationArray;
+ (NSString *)queryParameterForMRAID;
+ (NSString *)queryParameterForDNT;
+ (BOOL)advertisingTrackingEnabled;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdServerURLBuilder

+ (NSURL *)URLWithAdUnitID:(NSString *)adUnitID
                  keywords:(NSString *)keywords
             locationArray:(NSArray *)locationArray
                   testing:(BOOL)testing
{
    NSString *URLString = [NSString stringWithFormat:@"http://%@/m/ad?v=8&udid=%@&id=%@&nv=%@",
                           testing ? HOSTNAME_FOR_TESTING : HOSTNAME,
                           [MPIdentityProvider identifier],
                           [adUnitID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           MP_SDK_VERSION];

    URLString = [URLString stringByAppendingString:[self queryParameterForKeywords:keywords]];
    URLString = [URLString stringByAppendingString:[self queryParameterForOrientation]];
    URLString = [URLString stringByAppendingString:[self queryParameterForScaleFactor]];
    URLString = [URLString stringByAppendingString:[self queryParameterForTimeZone]];
    URLString = [URLString stringByAppendingString:[self queryParameterForLocationArray:locationArray]];
    URLString = [URLString stringByAppendingString:[self queryParameterForMRAID]];
    URLString = [URLString stringByAppendingString:[self queryParameterForDNT]];

    return [NSURL URLWithString:URLString];
}

+ (NSURL *)URLWithAdUnitID:(NSString *)adUnitID
                  keywords:(NSString *)keywords
                  location:(CLLocation *)location
                   testing:(BOOL)testing
{
    NSMutableArray *locationArray = [NSMutableArray array];
    if (location) {
        [locationArray addObject:[NSNumber numberWithDouble:location.coordinate.latitude]];
        [locationArray addObject:[NSNumber numberWithDouble:location.coordinate.longitude]];
    }
    return [self URLWithAdUnitID:adUnitID
                        keywords:keywords
                   locationArray:locationArray
                         testing:testing];
}


+ (NSString *)queryParameterForKeywords:(NSString *)keywords
{
    NSMutableArray *keywordsArray = [NSMutableArray array];
    NSString *trimmedKeywords = [keywords stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
    if ([trimmedKeywords length] > 0) {
        [keywordsArray addObject:trimmedKeywords];
    }

    // Append the Facebook attribution keyword (if available).
    Class fbKeywordProviderClass = NSClassFromString(@"MPFacebookKeywordProvider");
    if ([fbKeywordProviderClass conformsToProtocol:@protocol(MPKeywordProvider)])
    {
        NSString *fbAttributionKeyword = [(Class<MPKeywordProvider>) fbKeywordProviderClass keyword];
        if ([fbAttributionKeyword length] > 0) {
            [keywordsArray addObject:fbAttributionKeyword];
        }
    }

    if ([keywordsArray count] == 0) {
        return @"";
    } else {
        NSString *keywords = [[keywordsArray componentsJoinedByString:@","]
                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return [NSString stringWithFormat:@"&q=%@", keywords];
    }
}

+ (NSString *)queryParameterForOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    NSString *orientString = UIInterfaceOrientationIsPortrait(orientation) ?
        kMoPubInterfaceOrientationPortrait : kMoPubInterfaceOrientationLandscape;
    return [NSString stringWithFormat:@"&o=%@", orientString];
}

+ (NSString *)queryParameterForScaleFactor
{
    return [NSString stringWithFormat:@"&sc=%.1f", MPDeviceScaleFactor()];
}

+ (NSString *)queryParameterForTimeZone
{
    static NSDateFormatter *formatter;
    @synchronized(self)
    {
        if (!formatter) formatter = [[NSDateFormatter alloc] init];
    }
    [formatter setDateFormat:@"Z"];
    NSDate *today = [NSDate date];
    return [NSString stringWithFormat:@"&z=%@", [formatter stringFromDate:today]];
}

+ (NSString *)queryParameterForLocationArray:(NSArray *)locationArray
{
    NSString *result = @"";

    if ([locationArray count] == 2) {
        result = [result stringByAppendingFormat:
                  @"&ll=%@,%@",
                  [locationArray objectAtIndex:0],
                  [locationArray objectAtIndex:1]];
    }

    return result;
}

+ (NSString *)queryParameterForMRAID
{
    if (NSClassFromString(@"MPMRAIDBannerAdapter") &&
        NSClassFromString(@"MPMRAIDInterstitialAdapter")) {
        return @"&mr=1";
    } else {
        return @"";
    }
}

+ (NSString *)queryParameterForDNT
{
    return [self advertisingTrackingEnabled] ? @"" : @"&dnt=1";
}

+ (BOOL)advertisingTrackingEnabled
{
    return [MPIdentityProvider advertisingTrackingEnabled];
}

@end
