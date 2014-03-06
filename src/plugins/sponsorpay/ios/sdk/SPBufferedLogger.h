//
//  SPBufferedLogger.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLogAppender.h"

@interface SPBufferedLogger : NSObject <SPLogAppender>

+ (instancetype)logger;
@property (weak, readonly) NSString *bufferedMessagesString;

- (void)clearBuffer;
@end
