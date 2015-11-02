//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

/**
 *  Reason why the Rewarded Video Controller has been dismissed
 */
typedef NS_ENUM(NSInteger, FYBRewardedVideoControllerDismissReason) {
    FYBRewardedVideoControllerDismissReasonError = -1,  // An error occurred while playing the video
    FYBRewardedVideoControllerDismissReasonUserEngaged, // The video played until the end and the player was dismissed
    FYBRewardedVideoControllerDismissReasonAborted      // The video was aborted by the user
};
