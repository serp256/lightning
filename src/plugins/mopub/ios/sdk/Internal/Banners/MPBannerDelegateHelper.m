//
//  MPBannerDelegateHelper.m
//  MoPub
//
//  Copyright (c) 2012 MoPub. All rights reserved.
//

#import "MPBannerDelegateHelper.h"

@implementation MPBannerDelegateHelper

@synthesize adView = _adView;
@synthesize adViewDelegate;
@synthesize rootViewController;

- (id)initWithAdView:(MPAdView *)adView
{
    self = [super init];
    if (self) {
        _adView = adView;
    }
    return self;
}

- (void)dealloc
{
    _adView = nil;
    [super dealloc];
}

- (MPAdView *)adView
{
    return _adView;
}

- (id<MPAdViewDelegate>)adViewDelegate
{
    return [_adView delegate];
}

- (UIViewController *)rootViewController
{
    return [[self adViewDelegate] viewControllerForPresentingModalView];
}

@end
