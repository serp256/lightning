//
//  MPHTMLBannerAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPHTMLBannerAdapter.h"

#import "MPAdConfiguration.h"
#import "MPAdDestinationDisplayAgent.h"
#import "MPAdWebView.h"
#import "MPInstanceProvider.h"

@interface MPHTMLBannerAdapter ()

@property (nonatomic, retain) MPAdWebViewAgent *bannerAgent;

@end

@implementation MPHTMLBannerAdapter

@synthesize bannerAgent = _bannerAgent;

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    MPLogTrace(@"Loading banner with HTML source: %@", [configuration adResponseHTMLString]);

    self.bannerAgent = [[MPInstanceProvider sharedProvider] buildMPAdWebViewAgentWithAdWebViewFrame:CGRectMake(0, 0, 1, 1)
                                                                                           delegate:self
                                                                               customMethodDelegate:[self.delegate adViewDelegate]];
    [self.bannerAgent loadConfiguration:configuration];
}

- (void)dealloc
{
    self.bannerAgent = nil;

    [super dealloc];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    [self.bannerAgent rotateToOrientation:newOrientation];
}

#pragma mark - MPAdWebViewAgentDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)adDidFinishLoadingAd:(MPAdWebView *)ad
{
    [self.delegate adapter:self
        didFinishLoadingAd:self.bannerAgent.view
     shouldTrackImpression:NO];
}

- (void)adDidFailToLoadAd:(MPAdWebView *)ad
{
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)adDidClose:(MPAdWebView *)ad
{

}

- (void)adActionWillBegin:(MPAdWebView *)ad
{
    [self.delegate userActionWillBeginForAdapter:self];
}

- (void)adActionDidFinish:(MPAdWebView *)ad
{
    [self.delegate userActionDidFinishForAdapter:self];
}

- (void)adActionWillLeaveApplication:(MPAdWebView *)ad
{
    [self.delegate userWillLeaveApplicationFromAdapter:self];
}

#pragma mark - Metrics

- (void)trackImpression
{
    // HTML banners perform their own impression tracking.
}

- (void)trackClick
{
    // HTML banners perform their own click tracking.
}

@end
