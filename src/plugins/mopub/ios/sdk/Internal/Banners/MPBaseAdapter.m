//
//  MPBaseAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPBaseAdapter.h"

#import "MPAdConfiguration.h"
#import "MPLogging.h"

@interface MPBaseAdapter ()
{
    NSMutableURLRequest *_metricsURLRequest;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPBaseAdapter

@synthesize delegate = _delegate;
@synthesize impressionTrackingURL = _impressionTrackingURL;
@synthesize clickTrackingURL = _clickTrackingURL;

- (id)initWithAdapterDelegate:(id<MPAdapterDelegate>)delegate
{
	if (self = [super init]) {
		_delegate = delegate;
        
        _metricsURLRequest = [[NSMutableURLRequest alloc] init];
        [_metricsURLRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [_metricsURLRequest setValue:MPUserAgentString() forHTTPHeaderField:@"User-Agent"];
	}
	return self;
}

- (void)dealloc
{
	[self unregisterDelegate];
    [_impressionTrackingURL release];
    [_clickTrackingURL release];
    [_metricsURLRequest release];
	[super dealloc];
}

- (void)unregisterDelegate
{
	_delegate = nil;
}

#pragma mark - Requesting Ads

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    // To be implemented by subclasses.
    [self doesNotRecognizeSelector:_cmd];
}

- (void)_getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    self.impressionTrackingURL = [configuration impressionTrackingURL];
    self.clickTrackingURL = [configuration clickTrackingURL];
    
    [self retain];
    [self getAdWithConfiguration:configuration];
    [self release];
}

#pragma mark - Rotation

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	// Do nothing by default. Subclasses can override.
	MPLogDebug(@"rotateToOrientation %d called for adapter %@ (%p)",
		  newOrientation, NSStringFromClass([self class]), self);
}

#pragma mark - Metrics

- (void)trackImpression
{
    MPLogDebug(@"Tracking banner impression: %@", self.impressionTrackingURL);
    [_metricsURLRequest setURL:self.impressionTrackingURL];
    [NSURLConnection connectionWithRequest:_metricsURLRequest delegate:nil];
}

- (void)trackClick
{
    MPLogDebug(@"Tracking banner click: %@", self.clickTrackingURL);
    [_metricsURLRequest setURL:self.clickTrackingURL];
    [NSURLConnection connectionWithRequest:_metricsURLRequest delegate:nil];
}

#pragma mark - Requesting Ads (Legacy)

- (void)getAd
{
	[self getAdWithParams:nil];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	// To be implemented by subclasses.
	[self doesNotRecognizeSelector:_cmd];
}

- (void)_getAdWithParams:(NSDictionary *)params
{
    [self retain];
    [self getAdWithParams:params];
    [self release];
}

@end
