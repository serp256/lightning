//
//  MPInterstitialAdManager.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdServerCommunicator.h"
#import "MPBaseInterstitialAdapter.h"

@class MPInterstitialAdController;
@class CLLocation;
@protocol MPInterstitialAdManagerDelegate;

@interface MPInterstitialAdManager : NSObject <MPAdServerCommunicatorDelegate,
    MPBaseInterstitialAdapterDelegate>

@property (nonatomic, assign) id<MPInterstitialAdManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL ready;

- (id)initWithDelegate:(id<MPInterstitialAdManagerDelegate>)delegate;

- (void)loadInterstitialWithAdUnitID:(NSString *)ID
                            keywords:(NSString *)keywords
                            location:(CLLocation *)location
                             testing:(BOOL)testing;
- (void)presentInterstitialFromViewController:(UIViewController *)controller;

// Deprecated
- (void)customEventDidLoadAd;
- (void)customEventDidFailToLoadAd;
- (void)customEventActionWillBegin;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPInterstitialAdManagerDelegate <NSObject>

- (MPInterstitialAdController *)interstitialAdController;
- (id)interstitialDelegate;
- (void)managerDidLoadInterstitial:(MPInterstitialAdManager *)manager;
- (void)manager:(MPInterstitialAdManager *)manager
        didFailToLoadInterstitialWithError:(NSError *)error;
- (void)managerWillPresentInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidPresentInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerWillDismissInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidDismissInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidExpireInterstitial:(MPInterstitialAdManager *)manager;

@end
