#import <Foundation/Foundation.h>
#import "ALAd.h"
/**
 * This protocol defines a listener for ad video playback events.
 * For ads which do not contain videos, no callbacks will be triggered.
 *
 * @author Matt Szaro
 * @since 2.1.0
 */
@class ALAdService;

@protocol ALAdVideoPlaybackDelegate <NSObject>

/**
 * This method is invoked when a video starts playing in an ad.
 *
 * This method is invoked on the main UI thread.
 *
 * @param ad Ad in which video playback began.
 */
-(void) videoPlaybackBeganInAd: (ALAd*) ad;

/**
 * This method is invoked when a video stops playing in an ad.
 *
 * This method is invoked on the main UI thread.
 *
 * @param ad             Ad in which video playback ended.
 * @param percentPlayed  How much of the video was watched, as a percent.
 * @param fullyWatched   Whether or not the video was watched to, or very near to, completion.
 *                       This can be used for incentivized advertising, for example to award your
 *                       users virtual in-game currency if the video ad was fully viewed.
 */
-(void) videoPlaybackEndedInAd: (ALAd*) ad atPlaybackPercent:(NSNumber*) percentPlayed fullyWatched: (BOOL) wasFullyWatched;

@end
