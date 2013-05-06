//
//  MPBannerAdapterManager.h
//  MoPub
//
//  Copyright (c) 2012 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPAdConfiguration.h"
#import "MPBannerAdapterManagerDelegate.h"
#import "MPBaseAdapter.h"

@interface MPBannerAdapterManager : NSObject <MPAdapterDelegate>
{
    id<MPBannerAdapterManagerDelegate> _delegate;
    MPBaseAdapter *_requestingAdapter;
    MPBaseAdapter *_currentOnscreenAdapter;
}

@property (nonatomic, assign) id<MPBannerAdapterManagerDelegate> delegate;
@property (nonatomic, readonly, retain) MPBaseAdapter *requestingAdapter;
@property (nonatomic, readonly, retain) MPBaseAdapter *currentOnscreenAdapter;

- (id)initWithDelegate:(id<MPBannerAdapterManagerDelegate>)delegate;
- (void)loadAdapterForConfig:(MPAdConfiguration *)config;
- (void)requestedAdDidBecomeVisible;

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;

- (void)customEventDidLoadAd;
- (void)customEventDidFailToLoadAd;
- (void)customEventActionWillBegin;
- (void)customEventActionDidEnd;

@end
