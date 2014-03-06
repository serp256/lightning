//
//  SPNetworkOperation.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 11/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPNetworkOperation.h"
#import "SPURLGenerator.h"
#import "SPLogger.h"

static const NSTimeInterval SPCallbackOperationTimeout = 60.0;

@implementation SPNetworkOperation

- (void)main
{
    if (self.isCancelled) {
        return;
    }
    @autoreleasepool {

        SPLogDebug(@"%@ will send callback on thread: %@ using url:\n%@", self, [NSThread currentThread], self.url);

        if (!self.url) {
            self.didRequestSucceed = NO;
            SPLogError(@"%@ failed to send callback due to a nil NSURL", self);
            return;
        }

        NSURLRequest *request=[NSURLRequest requestWithURL:self.url
                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                           timeoutInterval:SPCallbackOperationTimeout];

        NSHTTPURLResponse *response = nil;
        NSError *requestError = nil;

        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];

        if (requestError) {
            SPLogError(@"Callback request failed with error: %@", requestError);

            return;
        }

        SPLogDebug(@"%@ received response to callback with status code: %d", self, response.statusCode);

        self.httpStatusCode = response.statusCode;
        self.response = response;
        self.didRequestSucceed = self.httpStatusCode == 200;
    }
}

- (id)init
{
    self = [super init];
    return self;
}

- (id)initWithAppId:(NSString *)appId
      url:(NSString *)url
{
    self = [self init];

    if (self) {
        self.url = [NSURL URLWithString:url];
    }

    return self;

}
@end
