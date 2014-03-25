//
//  SPApplifierAdapter.m
//  SponsorPaySample
//
//  Created by David Davila on 10/1/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPApplifierRewardedVideoAdapter.h"
#import "SPApplifierNetwork.h"
#import "SPLogger.h"

static NSString *const SPApplifierShowOffers = @"SPApplifierShowOffers";

@interface SPApplifierRewardedVideoAdapter()

@property (assign, nonatomic) BOOL videoFullyWatched;
@property (strong, nonatomic) NSMutableDictionary *showOptions;

@end

@implementation SPApplifierRewardedVideoAdapter

@synthesize delegate = _delegate;

- (NSString *)networkName
{
    return self.network.name;
}

- (BOOL)startAdapterWithDictionary:(NSDictionary *)dict
{
    ApplifierImpact *applifierInstance = [ApplifierImpact sharedInstance];
#ifdef APPLIFIER_TEST_MODE
#warning Applifier Test mode enabled
    [applifierInstance setDebugMode:YES];
    [applifierInstance setTestMode:YES];
#endif

    self.showOptions = [[NSMutableDictionary alloc] initWithDictionary:@{kApplifierImpactOptionVideoUsesDeviceOrientation:@true, kApplifierImpactOptionNoOfferscreenKey: @true}];

    if (dict[SPApplifierShowOffers]) {
        BOOL hideOffers = ![dict[SPApplifierShowOffers] boolValue];
        self.showOptions[kApplifierImpactOptionNoOfferscreenKey] = [NSNumber numberWithBool:hideOffers];
    }
    
    [applifierInstance setDelegate:self];
    return YES;
}

- (void)checkAvailability
{
    BOOL videoAvailable = [ApplifierImpact sharedInstance].canShowImpact;
    [self.delegate adapter:self didReportVideoAvailable:videoAvailable];
}

- (void)playVideoWithParentViewController:(UIViewController *)parentVC
{
    [[ApplifierImpact sharedInstance] setViewController:parentVC
                         showImmediatelyInNewController:NO];
    [[ApplifierImpact sharedInstance] showImpact:self.showOptions];
}

#pragma mark - ApplifierImpactDelegate selectors
- (void)applifierImpactCampaignsAreAvailable:(ApplifierImpact *)applifierImpact
{
    SPLogInfo(@"Applifier campaigns available");
}

- (void)applifierImpactCampaignsFetchFailed:(ApplifierImpact *)applifierImpact
{
    [self.delegate adapter:self didFailWithError:nil]; // TODO provide a meaningful error
}

- (void)applifierImpactVideoStarted:(ApplifierImpact *)applifierImpact
{
    [self.delegate adapterVideoDidStart:self];
}

- (void)applifierImpact:(ApplifierImpact *)applifierImpact
completedVideoWithRewardItemKey:(NSString *)rewardItemKey
        videoWasSkipped:(BOOL)skipped
{
    if (skipped) {
        [self.delegate adapterVideoDidAbort:self];
    } else {
        self.videoFullyWatched = YES;
        [self.delegate adapterVideoDidFinish:self];
    }
}

- (void)applifierImpactDidClose:(ApplifierImpact *)applifierImpact
{
    if (self.videoFullyWatched) {
        [self.delegate adapterVideoDidClose:self];
    } else {
        [self.delegate adapterVideoDidAbort:self];
    }
    self.videoFullyWatched = NO;
}

@end
