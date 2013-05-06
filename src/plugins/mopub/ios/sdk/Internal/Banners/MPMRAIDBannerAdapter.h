//
//  MPMRAIDBannerAdapter.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPBaseAdapter.h"

#import "MRAdView.h"

@interface MPMRAIDBannerAdapter : MPBaseAdapter <MRAdViewDelegate>
{
    MRAdView *_adView;
}

@end
