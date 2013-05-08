//
//  MPBannerCustomEventAdapter.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPBaseAdapter.h"

#import "MPBannerCustomEventDelegate.h"

@class MPBannerCustomEvent;

@interface MPBannerCustomEventAdapter : MPBaseAdapter <MPBannerCustomEventDelegate>
{
    MPBannerCustomEvent *_bannerCustomEvent;
}

@end
