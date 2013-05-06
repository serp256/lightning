//
//  MPAnalyticsTracker.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPAnalyticsTracker.h"
#import "MPAdConfiguration.h"

@interface MPAnalyticsTracker ()

@property (nonatomic, retain) NSString *userAgentString;

@end

@implementation MPAnalyticsTracker

+ (MPAnalyticsTracker *)trackerWithUserAgentString:(NSString *)userAgentString
{
    MPAnalyticsTracker *tracker = [[[MPAnalyticsTracker alloc] init] autorelease];
    tracker.userAgentString = userAgentString;
    return tracker;
}

- (void)trackImpressionForConfiguration:(MPAdConfiguration *)configuration
{
    [NSURLConnection connectionWithRequest:[self requestForURL:configuration.impressionTrackingURL]
                                  delegate:nil];
}

- (void)trackClickForConfiguration:(MPAdConfiguration *)configuration
{
    [NSURLConnection connectionWithRequest:[self requestForURL:configuration.clickTrackingURL]
                                  delegate:nil];
}

- (NSURLRequest *)requestForURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [request setValue:self.userAgentString forHTTPHeaderField:@"User-Agent"];
    return request;
}

@end
