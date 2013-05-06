//
//  MPBannerCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPBannerCustomEventDelegate.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * MPBannerCustomEvent is a base class for custom events that support banners. By implementing
 * subclasses of MPBannerCustomEvent, you can enable the MoPub SDK to natively support a wider
 * variety of third-party ad networks, or execute any of your application code on demand.
 *
 * At runtime, the MoPub SDK will find and instantiate a MPBannerCustomEvent subclass as needed and
 * invoke its -requestAdWithSize:customEventInfo: method.
 */
@interface MPBannerCustomEvent : NSObject

/*
 * When the MoPub SDK receives a response indicating it should load a custom event, it will send
 * this message to your custom event class. Your implementation of this method can either load a
 * banner ad from a third-party ad network, or execute any application code. It must also notify the
 * MPBannerCustomEventDelegate of certain lifecycle events.
 *
 * The `size` parameter tells you the current size of the parent MPAdView. You should use this
 * information in order to create a banner of the appropriate size.
 *
 * The `info` parameter is a dictionary containing additional custom data that you want to
 * associate with a given custom event request. This data is configurable on the MoPub website,
 * and may be used to pass dynamic information, such as publisher IDs.
 */
- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info;

/*
 * The `delegate` object defines several methods that you should call in order to inform both MoPub
 * and your MPAdView's delegate of the progress of your custom event. At a minimum, the MoPub SDK
 * requires that you call -bannerCustomEvent:didLoadAd: upon success, and
 * -bannerCustomEvent:didFailToLoadAdWithError: upon failure, in order for mediation to work
 * properly.
 */
@property (nonatomic, assign) id<MPBannerCustomEventDelegate> delegate;

@end
