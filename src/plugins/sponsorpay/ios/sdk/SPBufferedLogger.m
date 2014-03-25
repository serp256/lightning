//
//  SPBufferedLogger.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPBufferedLogger.h"

#define kSPLoggerBufferedMessagesStringPropertyName @"bufferedMessagesString"

@interface SPBufferedLogger()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableString *logMessagesBuffer;
@end

@implementation SPBufferedLogger

+ (instancetype)logger
{
    static SPBufferedLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPBufferedLogger alloc] init];
        
    });

    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"HH:mm:ss"];
    }
    return self;
}
- (void)logFormat:(NSString *)format arguments:(va_list)arguments
{
    NSDate *now = [NSDate date];
    NSString *timeString = [self.dateFormatter stringFromDate:now];
    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments:arguments];
    NSString *timestampedLogMessage = [NSString stringWithFormat:@"%@ %@", timeString, logMessage];

    [self willChangeValueForKey:kSPLoggerBufferedMessagesStringPropertyName];
    if (!_logMessagesBuffer) {
        _logMessagesBuffer = [[NSMutableString alloc] initWithString:timestampedLogMessage];
    } else {
        [_logMessagesBuffer appendString:timestampedLogMessage];
    }
    [self didChangeValueForKey:kSPLoggerBufferedMessagesStringPropertyName];

}

- (NSString *)bufferedMessagesString
{
    if (_logMessagesBuffer) {
        return [NSString stringWithString:_logMessagesBuffer];
    }
    return nil;
}

- (void)clearBuffer
{
    if (!_logMessagesBuffer)
        return;

    [self willChangeValueForKey:kSPLoggerBufferedMessagesStringPropertyName];
    [_logMessagesBuffer deleteCharactersInRange:NSMakeRange(0, _logMessagesBuffer.length)];
    [self didChangeValueForKey:kSPLoggerBufferedMessagesStringPropertyName];
}

@end
