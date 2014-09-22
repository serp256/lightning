//
//  SPEventHub.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialEventHub.h"
#import "SPInterstitialEvent.h"
#import "SPNetworkOperation.h"
#import "SPURLGenerator.h"
#import "SPConstants.h"
#import "SPLogger.h"

static const NSInteger SPMaxConcurrentOperations = 1;

@interface SPInterstitialEventHub() {
    NSOperationQueue *_networkQueue;
}

@property (nonatomic, copy) NSString *eventURL;

@end
@implementation SPInterstitialEventHub

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveInterstitialNotification:) name:SPInterstitialEventNotification object:nil];
        _networkQueue = [[NSOperationQueue alloc] init];
        _networkQueue.maxConcurrentOperationCount = SPMaxConcurrentOperations;
        _eventURL = SPInterstitialEventURL;
    }
    return self;
}

- (void)receiveInterstitialNotification:(NSNotification *)notification
{
    SPInterstitialEvent *event = (SPInterstitialEvent *)notification.object;
    if (![event isKindOfClass:[SPInterstitialEvent class]]) {
        [NSException raise:NSInvalidArgumentException format:@"%@", NSLocalizedString(@"Notification object is not of SPInterstitialEvent call", nil)];
    }

    SPURLGenerator *url = [SPURLGenerator URLGeneratorWithBaseURLString:self.eventURL];
    [url setAppID:self.appId];
    [url setUserID:self.userId];
    [url addParametersProvider:event];
    SPNetworkOperation *networkOp = [[SPNetworkOperation alloc] init];
    networkOp.url = [url generatedURL];

    __weak SPNetworkOperation *weak_networkOp = networkOp;
    networkOp.completionBlock = ^{
        SPLogDebug(@"Operation return with status: %d", weak_networkOp.httpStatusCode);
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:weak_networkOp.response.allHeaderFields forURL:weak_networkOp.url];
        SPLogDebug(@"Number of cookies returned %d", cookies.count);
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie *obj, NSUInteger idx, BOOL *stop) {
            SPLogDebug(@"Name: %@\nValue: %@", obj.name, obj.value);
        }];

    };

    [_networkQueue addOperation:networkOp];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_networkQueue cancelAllOperations];
}

@end
