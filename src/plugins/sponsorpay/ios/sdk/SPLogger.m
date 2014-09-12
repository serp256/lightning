//
//  SPLogger.m
//  SponsoPay iOS SDK
//
//  Created by David Davila on 8/21/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPLogger.h"
#import "SPLogAppender.h"

static SPLogLevel SPCurrentLogLevel = SPLogLevelVerbose;

void SPLogSetLevel(SPLogLevel level)
{
    SPCurrentLogLevel = level;
}

void _SPLogDebug(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelDebug)
    {
        format = [NSString stringWithFormat:@"[SP Debug]: %@", format];

        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);

    }
}

void _SPLogWarn(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelWarn)
    {
        format = [NSString stringWithFormat:@"[SP Warn]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogInfo(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelInfo)
    {
        format = [NSString stringWithFormat:@"[SP Info]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogError(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelError)
    {
        format = [NSString stringWithFormat:@"[SP Error]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogFatal(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelFatal)
    {
        format = [NSString stringWithFormat:@"[SP Fatal]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

@interface SPLogger ()

@property (strong, nonatomic) NSMutableArray *loggers;

@end

@implementation SPLogger

+ (void)addLogger:(id<SPLogAppender>)logger
{
    if ([logger conformsToProtocol:@protocol(SPLogAppender)]) {
        [[SPLogger sharedInstance] addLogger:logger];
    } else {
        SPLogError(@"Logger %@ does not conform to protocol SPLogAppender", NSStringFromClass([logger class]));
    }
}


- (id)init
{
    self = [super init];
    if (self) {
        _loggers = [NSMutableArray array];
    }
    return self;
}

- (void)logFormat:(NSString *)format arguments:(va_list)arguments
{
    for (id<SPLogAppender>logger in self.loggers) {
        va_list args_copy;
        va_copy(args_copy, arguments);

        [logger logFormat:format arguments:args_copy];
        va_end(args_copy);
    };
}

- (void)addLogger:(id<SPLogAppender>)logger
{
    [self.loggers addObject:logger];
}

+ (SPLogger *)sharedInstance
{
    static SPLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPLogger alloc] init];
    });

    return sharedInstance;
}

@end
