//
//  SPLogger.h
//  SponsoPay iOS SDK
//
//  Created by David Davila on 8/21/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SPLogLevel.h"

@protocol SPLogAppender;

#define LogInvocation NSLog(@"%s", __PRETTY_FUNCTION__)

#define SPLogVerbose(...) _SPLogVerbose(__VA_ARGS__)
#define SPLogDebug(...) _SPLogDebug(__VA_ARGS__)
#define SPLogInfo(...) _SPLogInfo(__VA_ARGS__)
#define SPLogWarn(...) _SPLogWarn(__VA_ARGS__)
#define SPLogError(...) _SPLogError(__VA_ARGS__)
#define SPLogFatal(...) _SPLogFatal(__VA_ARGS__)

void SPLogSetLevel(SPLogLevel level);
void _SPLogVerbose(NSString *format, ...);
void _SPLogDebug(NSString *format, ...);
void _SPLogInfo(NSString *format, ...);
void _SPLogWarn(NSString *format, ...);
void _SPLogError(NSString *format, ...);
void _SPLogFatal(NSString *format, ...);

@interface SPLogger : NSObject

+ (instancetype)sharedInstance;

+ (void)addLogger:(id<SPLogAppender>)logger;
+ (void)removeLogger:(id<SPLogAppender>)logger;
+ (void)removeAllLoggers;

+ (void)checkDynamicLogLevel;

- (void)logFormat:(NSString *)format arguments:(va_list)arguments;

@end
