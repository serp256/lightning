//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

/**
 *  The state of the Interstitial controller
 */
typedef NS_ENUM(NSInteger, FYBInterstitialControllerState) {
    FYBInterstitialControllerStateReadyToQuery,     // The controller is ready to query interstitial offers
    FYBInterstitialControllerStateQuerying,         // The controller is querying interstitial offers
    FYBInterstitialControllerStateValidatingOffers, // The controller is validating the offers
    FYBInterstitialControllerStateReadyToShow,      // The controller received an interstitial offer and is ready to show it
    FYBInterstitialControllerStateShowing           // The controller is showing the interstitial
};
