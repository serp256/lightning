//
//  MPMRAIDBannerAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPMRAIDBannerAdapter.h"

#import "MPAdConfiguration.h"

@implementation MPMRAIDBannerAdapter

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    CGRect adViewFrame = CGRectZero;
    if ([configuration hasPreferredSize]) {
        adViewFrame = CGRectMake(0, 0, configuration.preferredSize.width,
                                 configuration.preferredSize.height);
    }
    
    _adView = [[MRAdView alloc] initWithFrame:adViewFrame
                              allowsExpansion:YES
                             closeButtonStyle:MRAdViewCloseButtonStyleAdControlled
                                placementType:MRAdViewPlacementTypeInline];
    _adView.delegate = self;
    [_adView loadCreativeWithHTMLString:[configuration adResponseHTMLString]
                                baseURL:nil];
}

- (void)dealloc
{
    _adView.delegate = nil;
    [_adView release];
    [super dealloc];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    [_adView rotateToOrientation:newOrientation];
}

#pragma mark - MRAdViewControllerDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)adDidLoad:(MRAdView *)adView
{
    [self.delegate adapter:self didFinishLoadingAd:adView shouldTrackImpression:YES];
}

- (void)adDidFailToLoad:(MRAdView *)adView
{
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)appShouldSuspendForAd:(MRAdView *)adView
{
    [self.delegate userActionWillBeginForAdapter:self];
}

- (void)appShouldResumeFromAd:(MRAdView *)adView
{
    [self.delegate userActionDidFinishForAdapter:self];
}

- (void)closeButtonPressed
{
    
}

@end
