//
//  SPCacheManager.h
//  SponsorPaySDK
//
//  Created by tito on 02/02/15.
//  Copyright (c) 2015 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSTimeInterval const SPRefreshIntervalDefaultValue;
extern NSTimeInterval const SPRefreshIntervalMinimumValue;


@interface SPCacheManager : NSObject

/**
 *  Pause the video cache download operations
 *
 *  Pause the current video downloads to free up the bandwidth for the application's download
 *  Use -resumeDownloads to reschedule the downloads
 */
- (void)pauseDownloads;

/**
 *  Resume the downloads for rewarded video caching
 *
 *  This method will re-evaluate the videos to the cached and re-scheduled it's operation.
 *  Must be preceded by a call to -pauseDownloads, otherwise this call has no effect.
 */
- (void)resumeDownloads;

@end
