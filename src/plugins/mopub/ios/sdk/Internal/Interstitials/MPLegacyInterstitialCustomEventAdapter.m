//
//  MPLegacyInterstitialCustomEventAdapter.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPLegacyInterstitialCustomEventAdapter.h"
#import "MPAdConfiguration.h"
#import "MPLogging.h"

@implementation MPLegacyInterstitialCustomEventAdapter

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    MPLogInfo(@"Looking for custom event selector named %@.", configuration.customSelectorName);

    SEL customEventSelector = NSSelectorFromString(configuration.customSelectorName);
    if ([self.delegate.interstitialDelegate respondsToSelector:customEventSelector]) {
        [self.delegate.interstitialDelegate performSelector:customEventSelector];
        return;
    }

    NSString *oneArgumentSelectorName = [configuration.customSelectorName
                                         stringByAppendingString:@":"];

    MPLogInfo(@"Looking for custom event selector named %@.", oneArgumentSelectorName);

    SEL customEventOneArgumentSelector = NSSelectorFromString(oneArgumentSelectorName);
    if ([self.delegate.interstitialDelegate respondsToSelector:customEventOneArgumentSelector]) {
        [self.delegate.interstitialDelegate performSelector:customEventOneArgumentSelector
                                                 withObject:self.delegate.interstitialAdController];
        return;
    }

    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)customEventDidLoadAd
{
    [self trackImpression];
}

- (void)customEventDidFailToLoadAd
{
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)customEventActionWillBegin
{
    [self trackClick];
}

@end
