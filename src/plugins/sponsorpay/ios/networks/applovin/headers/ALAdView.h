//
//  ALAdView.h
//  sdk
//
//  Created by Basil on 3/1/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ALSdk.h"
#import "ALAdService.h"

@interface ALAdView : UIView<ALAdLoadDelegate>

@property (strong, atomic) id<ALAdLoadDelegate> adLoadDelegate;
@property (strong, atomic) id<ALAdDisplayDelegate> adDisplayDelegate;
@property (strong, atomic) id<ALAdVideoPlaybackDelegate> adVideoPlaybackDelegate;

@property (strong)         NSNumber * autoload;
@property (strong, atomic) ALAdSize * adSize;

@property (strong, atomic) UIViewController * parentController;

// AppLovin SDK no longer uses placements; this is left for compatibility reasons.
@property (strong, atomic) NSString * adPlacement __deprecated;

/**
 * Start loading next advertisement. This method will return immediately. An
 * advertisement will be rendered by this view when available.
 */
-(void)loadNextAd;

/**
 * Render specified ad.
 *
 * @param ad Ad to render. Must not be null.
 */
-(void)render:(ALAd *)ad;

/**
 * Initialize ad view as a banner.
 */
-(id)initBannerAd;

/**
 * Initialize ad view as a MRec.
 */
-(id) initMRecAd;

/**
 * Initialize ad view as a banner.
 *
 * @param sdk    Instace of AppLovin SDK to use.
 */
-(id)initBannerAdWithSdk: (ALSdk *)anSdk;

/**
 * Initialize ad view as a mrec.
 *
 * @param sdk    Instance of AppLovin SDK to use.
 */
-(id)initMRecAdWithSdk: (ALSdk *)anSdk;

/**
 * Initialize ad view with given frame and size
 *
 * @param frame  Ad frame to use.
 * @param size   Ad size to use.
 * @param sdk    Instace of AppLovin SDK to use.
 */
- (id)initWithFrame:(CGRect)frame size:(ALAdSize *)aSize sdk:(ALSdk *) anSdk;

@end
