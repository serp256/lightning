//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>


/**
 *  Provides methods to control the precaching flow on the FyberSDK and on the mediated networks
 */
@interface FYBCacheManager : NSObject

/**
 *  Starts the video cache download operations
 *
 *  @discussion This method is only useful if you prevented the SDK from starting precaching videos by passing a FYBSDKOptions object
 *              configured with startVideoPrecaching = NO
 *
 *  @discussion Use -pausePrecaching to pause the downloads
 */
- (void)startPrecaching;

/**
 *  Pauses the video cache download operations
 *
 *  @discussion Use -resumePrecaching to reschedule the downloads
 *
 *  @discussion If they provide this feature, this will also pause the downloads triggered by third party networks
 */
- (void)pausePrecaching;

/**
 *  Resumes the downloads for rewarded video caching
 *
 *  @discussion Use -pausePrecaching to pause the downloads
 *
 *  @discussion If they provide this feature, this will also resume the downloads triggered by third party networks
 */
- (void)resumePrecaching;

@end
