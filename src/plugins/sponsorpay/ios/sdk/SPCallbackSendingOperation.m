//
//  SPCallbackSendingOperation.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 12/3/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPCallbackSendingOperation.h"
#import "SPURLGenerator.h"
#import "SPLogger.h"

static NSString *const SPURLParamKeySuccessfulAnswerReceived = @"answer_received";
static NSString *const SPURLParameterKeyActionId = @"action_id";

@implementation SPCallbackSendingOperation

- (void)main
{
    self.url = [self callbackURL];
    [super main];
}

- (NSURL *)callbackURL
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithBaseURLString:self.baseURLString];
    
    [urlGenerator setAppID:self.appId];
    
    [urlGenerator setParameterWithKey:SPURLParamKeySuccessfulAnswerReceived
                          stringValue:self.answerAlreadyReceived ? @"1" : @"0"];
    
    if (self.actionId) {
        [urlGenerator setParameterWithKey:SPURLParameterKeyActionId
                              stringValue:self.actionId];
    }
    
    return [urlGenerator generatedURL];
}

- (id)init
{
    self = [super init];
    return self;
}

- (id)initWithAppId:(NSString *)appId
      baseURLString:(NSString *)baseURLString
           actionId:(NSString *)actionId
     answerReceived:(BOOL)answerReceived
{
    self = [self init];
    
    if (self) {
        self.appId = appId;
        self.baseURLString = baseURLString;
        self.actionId = actionId;
        self.answerAlreadyReceived = answerReceived;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {appId = %@ actionId = %@ "
            "answerAlreadyReceived = %d}",
            [super description], self.appId, self.actionId,
            self.answerAlreadyReceived];
}

+ (id)operationForAppId:(NSString *)appId
          baseURLString:(NSString *)baseURLString
               actionId:(NSString *)actionId
         answerReceived:(BOOL)answerReceived
{
    SPCallbackSendingOperation *operation =
    [[SPCallbackSendingOperation alloc] initWithAppId:appId
                                        baseURLString:baseURLString
                                             actionId:actionId
                                       answerReceived:answerReceived];

    return operation;
}
@end
