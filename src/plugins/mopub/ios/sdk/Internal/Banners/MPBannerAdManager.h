//
//  MPBannerAdManager.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdBrowserController.h"
#import "MPAdServerCommunicator.h"
#import "MPBannerAdapterManager.h"
#import "MPBaseAdapter.h"
#import "MPProgressOverlayView.h"

extern const CGFloat kMoPubRequestRetryInterval;

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPBannerAdManagerDelegate;
@class MPAdView, MPBaseAdapter, MPBannerDelegateHelper, MPTimer, MPTimerTarget;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPBannerAdManager : NSObject <MPAdServerCommunicatorDelegate,
    MPBannerAdapterManagerDelegate>
{
    MPAdServerCommunicator *_communicator;
    BOOL _loading;
    
    MPBannerAdapterManager *_adapterManager;
    MPBannerDelegateHelper *_delegateHelper;
    
    MPAdView *_adView;
    
    BOOL _adActionInProgress;
    UIView *_nextAdContentView;
    
    MPTimer *_autorefreshTimer;
    MPTimerTarget *_timerTarget;
    BOOL _ignoresAutorefresh;
    BOOL _previousIgnoresAutorefresh;
    BOOL _autorefreshTimerNeedsScheduling;
}

@property (nonatomic, assign, getter=isLoading) BOOL loading;

@property (nonatomic, assign) MPAdView *adView;

@property (nonatomic, retain) MPTimer *autorefreshTimer;
@property (nonatomic, assign) BOOL ignoresAutorefresh;

- (void)loadAdWithURL:(NSURL *)URL;
- (void)refreshAd;
- (void)forceRefreshAd;
- (void)cancelAd;

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;
- (void)customEventDidLoadAd;
- (void)customEventDidFailToLoadAd;
- (void)customEventActionWillBegin;
- (void)customEventActionDidEnd;

- (NSTimeInterval)refreshInterval;

@end
