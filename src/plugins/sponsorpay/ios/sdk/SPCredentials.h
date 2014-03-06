//
//  SPCredentials.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCredentials : NSObject <NSCopying>

@property (strong) NSString *appId;
@property (strong) NSString *userId;
@property (strong) NSString *securityToken;
@property (weak, readonly) NSString *credentialsToken;
@property (readonly) NSMutableDictionary *userConfig;

+ (SPCredentials *)credentialsWithAppId:(NSString *)appId
                                 userId:(NSString *)userId
                          securityToken:(NSString *)securityToken;

+ (NSString *)credentialsTokenForAppId:(NSString *)appId
                                userId:(NSString *)userId;

@end
