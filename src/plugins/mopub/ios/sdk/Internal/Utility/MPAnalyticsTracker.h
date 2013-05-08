//
//  MPAnalyticsTracker.h
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPAdConfiguration;

@interface MPAnalyticsTracker : NSObject

+ (MPAnalyticsTracker *)trackerWithUserAgentString:(NSString *)userAgentString;

- (void)trackImpressionForConfiguration:(MPAdConfiguration *)configuration;
- (void)trackClickForConfiguration:(MPAdConfiguration *)configuration;

@end
