//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

/**
 *  The state of the Rewarded Video controller
 */
typedef NS_ENUM(NSInteger, FYBRewardedVideoControllerState) {
    FYBRewardedVideoControllerStateReadyToQuery, // The controller is ready to query video offers
    FYBRewardedVideoControllerStateQuerying,     // The controller is querying video offers
    FYBRewardedVideoControllerStateReadyToShow,  // The controller received a video offer and is ready to show it
    FYBRewardedVideoControllerStateShowing       // The controller is showing the video
};