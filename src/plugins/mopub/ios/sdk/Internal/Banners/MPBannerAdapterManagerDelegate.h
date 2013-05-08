//
//  MPBannerAdapterManagerDelegate.h
//  MoPub
//
//  Copyright (c) 2012 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPAdView.h"
#import "MPError.h"

@class MPBannerAdapterManager;

@protocol MPBannerAdapterManagerDelegate <NSObject>

@required

#pragma mark - Helpers for adapters

- (MPAdView *)adView;
- (id<MPAdViewDelegate>)adViewDelegate;
- (UIViewController *)rootViewController;

#pragma mark - Callbacks

- (void)adapterManager:(MPBannerAdapterManager *)manager didLoadAd:(UIView *)ad;
- (void)adapterManager:(MPBannerAdapterManager *)manager didRefreshAd:(UIView *)ad;
- (void)adapterManager:(MPBannerAdapterManager *)manager didFailToLoadAdWithError:(MPError *)error;
- (void)adapterManagerUserActionWillBegin:(MPBannerAdapterManager *)manager;
- (void)adapterManagerUserActionDidFinish:(MPBannerAdapterManager *)manager;
- (void)adapterManagerUserWillLeaveApplication:(MPBannerAdapterManager *)manager;

@end
