//
//  MPInterstitialCustomEventAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialCustomEventAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInterstitialAdManager.h"
#import "MPInterstitialAdController.h"
#import "MPLogging.h"
#import "MPInstanceProvider.h"

@interface MPInstanceProvider (CustomEventInterstitials)

- (MPInterstitialCustomEvent *)buildInterstitialCustomEventFromCustomClass:(Class)customClass
                                                                  delegate:(id<MPInterstitialCustomEventDelegate>)delegate;

@end

@implementation MPInstanceProvider (CustomEventInterstitials)

- (MPInterstitialCustomEvent *)buildInterstitialCustomEventFromCustomClass:customClass
                                                                  delegate:(id<MPInterstitialCustomEventDelegate>)delegate
{
    MPInterstitialCustomEvent *customEvent = [[[customClass alloc] init] autorelease];
    customEvent.delegate = delegate;
    return customEvent;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPInterstitialCustomEventAdapter ()

@property (nonatomic, retain) MPInterstitialCustomEvent *interstitialCustomEvent;

@end

@implementation MPInterstitialCustomEventAdapter

@synthesize interstitialCustomEvent = _interstitialCustomEvent;

- (void)dealloc
{
    self.interstitialCustomEvent.delegate = nil;
    self.interstitialCustomEvent = nil;

    [super dealloc];
}


- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    Class customEventClass = configuration.customEventClass;

    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);

    if (customEventClass) {
        [self loadAdFromCustomClass:customEventClass configuration:configuration];
        return;
    }

    MPLogInfo(@"Could not handle custom event request.");

    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}


- (void)loadAdFromCustomClass:(Class)customClass configuration:(MPAdConfiguration *)configuration
{
    self.interstitialCustomEvent = [[MPInstanceProvider sharedProvider] buildInterstitialCustomEventFromCustomClass:customClass delegate:self];
    [self.interstitialCustomEvent requestInterstitialWithCustomEventInfo:configuration.customEventClassData];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self.interstitialCustomEvent showInterstitialFromRootViewController:controller];
}

#pragma mark - MPInterstitialCustomEventDelegate

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
                      didLoadAd:(id)ad
{
    [self.delegate adapterDidFinishLoadingAd:self];
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
       didFailToLoadAdWithError:(NSError *)error
{
    [self.delegate adapter:self didFailToLoadAdWithError:error];
}

- (void)interstitialCustomEventWillAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillAppearForAdapter:self];
}

- (void)interstitialCustomEventDidAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self trackImpression];
    [self.delegate interstitialDidAppearForAdapter:self];
}

- (void)interstitialCustomEventWillDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillDisappearForAdapter:self];
}

- (void)interstitialCustomEventDidDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialDidDisappearForAdapter:self];
}

- (void)interstitialCustomEventDidReceiveTapEvent:(MPInterstitialCustomEvent *)customEvent
{
    [self trackClick];
}

- (void)interstitialCustomEventWillLeaveApplication:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillLeaveApplicationForAdapter:self];
}

@end
