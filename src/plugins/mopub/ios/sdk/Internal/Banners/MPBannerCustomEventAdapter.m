//
//  MPBannerCustomEventAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPBannerCustomEventAdapter.h"

#import "MPAdConfiguration.h"
#import "MPBannerCustomEvent.h"

@interface MPBannerCustomEventAdapter ()

- (void)loadAdWithConfiguration:(MPAdConfiguration *)configuration
                fromCustomClass:(Class)customClass;

@end

@implementation MPBannerCustomEventAdapter

- (void)dealloc
{
    _bannerCustomEvent.delegate = nil;
    [_bannerCustomEvent release];
    
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    Class customEventClass = configuration.customEventClass;
    
    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    
    if (customEventClass) {
        [self loadAdWithConfiguration:configuration fromCustomClass:customEventClass];
        return;
    }
    
    MPLogInfo(@"Could not find custom event class named %@.", configuration.customEventClass);
    MPLogInfo(@"Looking for custom event selector named %@.", configuration.customSelectorName);
    
    SEL customEventSelector = NSSelectorFromString(configuration.customSelectorName);
    if ([[self.delegate adViewDelegate] respondsToSelector:customEventSelector]) {
        [[self.delegate adViewDelegate] performSelector:customEventSelector];
        return;
    }
    
    NSString *oneArgumentSelectorName = [configuration.customSelectorName
                                         stringByAppendingString:@":"];
    
    MPLogInfo(@"Could not find custom event selector named %@.",
              configuration.customSelectorName);
    MPLogInfo(@"Looking for custom event selector named %@.", oneArgumentSelectorName);
    
    SEL customEventOneArgumentSelector = NSSelectorFromString(oneArgumentSelectorName);
    if ([[self.delegate adViewDelegate] respondsToSelector:customEventOneArgumentSelector]) {
        [[self.delegate adViewDelegate] performSelector:customEventOneArgumentSelector
                                             withObject:[self.delegate adView]];
        return;
    }
    
    MPLogInfo(@"Could not handle custom event request.");
    
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)loadAdWithConfiguration:(MPAdConfiguration *)configuration
                fromCustomClass:(Class)customClass
{
    _bannerCustomEvent = [[customClass alloc] init];
    _bannerCustomEvent.delegate = self;
    [_bannerCustomEvent requestAdWithSize:configuration.adSize
                          customEventInfo:configuration.customEventClassData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - MPBannerCustomEventDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didLoadAd:(UIView *)ad
{
    [self.delegate adapter:self didFinishLoadingAd:ad shouldTrackImpression:YES];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didFailToLoadAdWithError:(NSError *)error
{
    [self.delegate adapter:self didFailToLoadAdWithError:error];
}

- (void)bannerCustomEventWillBeginAction:(MPBannerCustomEvent *)event
{
    [self.delegate userActionWillBeginForAdapter:self];
}

- (void)bannerCustomEventDidFinishAction:(MPBannerCustomEvent *)event
{
    [self.delegate userActionDidFinishForAdapter:self];
}

- (void)bannerCustomEventWillLeaveApplication:(MPBannerCustomEvent *)event
{
    [self.delegate userWillLeaveApplicationFromAdapter:self];
}

@end
