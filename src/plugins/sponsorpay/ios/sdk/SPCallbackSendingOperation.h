//
//  SPCallbackSendingOperation.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 12/3/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPNetworkOperation.h"

@interface SPCallbackSendingOperation : SPNetworkOperation

@property (strong) NSString *appId;
@property (strong) NSString *actionId;
@property (strong) NSString *baseURLString;

@property (assign) BOOL answerAlreadyReceived;

- (id)init;

- (id)initWithAppId:(NSString *)appId
      baseURLString:(NSString *)baseURLString
           actionId:(NSString *)actionId
     answerReceived:(BOOL)answerReceived;

+ (id)operationForAppId:(NSString *)appId
          baseURLString:(NSString *)baseURLString
               actionId:(NSString *)actionId
         answerReceived:(BOOL)answerReceived;

@end
