//
//  MPBaseInterstitialAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 4/27/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "MPBaseInterstitialAdapter.h"
#import "MPAdConfiguration.h"
#import "MPGlobal.h"
#import "MPAnalyticsTracker.h"
#import "MPInstanceProvider.h"

@interface MPBaseInterstitialAdapter ()

@property (nonatomic, retain) MPAdConfiguration *configuration;
@property (nonatomic, retain) MPAnalyticsTracker *analyticsTracker;
@property (nonatomic, assign) BOOL hasTrackedImpression;
@property (nonatomic, assign) BOOL hasTrackedClick;

@end

@implementation MPBaseInterstitialAdapter

@synthesize delegate = _delegate;
@synthesize configuration = _configuration;
@synthesize hasTrackedImpression = _hasTrackedImpression;
@synthesize hasTrackedClick = _hasTrackedClick;

- (id)initWithDelegate:(id<MPBaseInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.analyticsTracker = [[MPInstanceProvider sharedProvider] buildMPAnalyticsTracker];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterDelegate];
    self.configuration = nil;
    self.analyticsTracker = nil;
    [super dealloc];
}

- (void)unregisterDelegate
{
    self.delegate = nil;
}

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    // To be implemented by subclasses.
    [self doesNotRecognizeSelector:_cmd];
}

- (void)_getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    [self retain];
    self.configuration = configuration;
    [self getAdWithConfiguration:configuration];
    [self release];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)trackImpression
{
    if (!self.hasTrackedImpression) {
        self.hasTrackedImpression = YES;
        [self.analyticsTracker trackImpressionForConfiguration:self.configuration];
    }
}

- (void)trackClick
{
    if (!self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self.analyticsTracker trackClickForConfiguration:self.configuration];
    }
}

@end

