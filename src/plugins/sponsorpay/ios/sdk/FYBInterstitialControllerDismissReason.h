//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

/**
 *  Reason why the Interstitial controller has been dismissed
 */
typedef NS_ENUM(NSInteger, FYBInterstitialControllerDismissReason) {
    FYBInterstitialControllerDismissReasonError = -1,  // The Interstitial controller was dismissed for an unknown reason
    FYBInterstitialControllerDismissReasonUserEngaged, // The Interstitial controller was closed because the user clicked on the ad
    FYBInterstitialControllerDismissReasonAborted      // The Interstitial controller was explicitly closed by the user
};
