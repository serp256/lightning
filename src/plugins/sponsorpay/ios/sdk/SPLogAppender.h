//
//  SPLogAppender.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SPLogAppender<NSObject>

+ (id<SPLogAppender>)logger;
- (void)logFormat:(NSString *)format arguments:(va_list)arguments;

@end
