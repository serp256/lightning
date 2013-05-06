//
//  MPBannerDelegateHelper.h
//  MoPub
//
//  Copyright (c) 2012 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPAdView.h"

@interface MPBannerDelegateHelper : NSObject
{
    MPAdView *_adView;
}

@property (nonatomic, readonly) MPAdView *adView;
@property (nonatomic, readonly) id<MPAdViewDelegate> adViewDelegate;
@property (nonatomic, readonly) UIViewController *rootViewController;

- (id)initWithAdView:(MPAdView *)adView;

@end
