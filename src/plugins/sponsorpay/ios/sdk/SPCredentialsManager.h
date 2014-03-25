//
//  SPCredentialsManager.h
//  SponsorPayTestApp
//
//  Created by David Davila on 21/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPCredentials.h"

extern NSString *const SPNoCredentialsException;
extern NSString *const SPNoUniqueCredentialsException;
extern NSString *const SPInvalidCredentialsTokenException;

// Credentials status (none, unique, multiple)
typedef NS_ENUM(NSInteger, SPSDKCredentialsStatus) {
    SPSDKHasNoCredentials = 0,
    SPSDKHasUniqueCredentialsItem = 1,
    SPSDKHasMultipleCredentialsItems = 2
};

@interface SPCredentialsManager : NSObject

@property (readonly) SPSDKCredentialsStatus credentialsStatus;

- (id)initWithCapacity:(NSUInteger)expectedNumberOfDifferentCredentials;

- (void)addCredentialsItem:(SPCredentials *)credentials forToken:(NSString *)token;

- (SPCredentials *)uniqueCredentialsItem;

- (SPCredentials *)credentialsForToken:(NSString *)credentialsToken;

- (SPCredentials *)credentialsForProduct:(NSString *)productKey;

- (void)setDefaultCredentials:(NSString *)credentialsToken forProduct:(NSString *)productKey;

- (void)clearCredentials;


- (SPCredentials *)setConfigurationValue:(id)value
                                  forKey:(NSString *)key
                  inCredentialsWithToken:(NSString *)token;

- (void)setConfigurationValueInAllCredentials:(id)value
                                       forKey:(NSString *)key;

@end
