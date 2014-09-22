//
//  SPVideoPlayerDelegate.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 12/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SPVideoPlaybackStateDelegate <NSObject>

/**
 Method used to notify that the video has started
 */
- (void)videoPlaybackStarted;

/**
 Method used to notify the video has ended
 
 @param videoWasAborted BOOL indicating if the movie was aborted due to the user forfeiting the reward or any other problem
 */
- (void)videoPlaybackEnded:(BOOL)videoWasAborted;

/**
 Method used to notify a time update in the movie.
 
 @param currentTime current time of the playback
 @param duration total duration of the movie
 */
- (void)timeUpdate:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;

/**
 Method used to notify the user that the browser was opened
*/
- (void)browserWillOpen;

@end
