//
//  SPCredentialsManager.m
//  SponsorPayTestApp
//
//  Created by David Davila on 21/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPCredentialsManager.h"
#import "SPLogger.h"

NSString *const SPNoCredentialsException = @"SponsorPayNoCredentialsException";
NSString *const SPNoUniqueCredentialsException = @"SponsorPayNoUniqueCredentialsException";
NSString *const SPInvalidCredentialsTokenException = @"SponsorPayInvalidCredentialsToken";

@interface SPCredentialsManager()

@property (strong) NSMutableDictionary *activeCredentialsItems;
@property (strong) NSMutableDictionary *credentialTokensByProduct;
@property (strong) NSString *defaultCredentialsToken;

@end

@implementation SPCredentialsManager

- (id)initWithCapacity:(NSUInteger)expectedNumberOfDifferentCredentials
{
    self = [super init];
    if (self) {
        self.activeCredentialsItems = [NSMutableDictionary dictionaryWithCapacity:expectedNumberOfDifferentCredentials];
        self.credentialTokensByProduct = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)init
{
    return [self initWithCapacity:1];
}

#pragma mark - Credentials management

- (void)addCredentialsItem:(SPCredentials *)credentials forToken:(NSString *)token
{
    if (!self.activeCredentialsItems.count) {
        self.defaultCredentialsToken = token;
    }

    [self.activeCredentialsItems setObject:credentials forKey:token];
}

- (void)clearCredentials
{
    [self.activeCredentialsItems removeAllObjects];
    [self.credentialTokensByProduct removeAllObjects];
    self.defaultCredentialsToken = nil;
}

- (SPCredentials *)uniqueCredentialsItem
{
    SPCredentials *credentialsToReturn = nil;
    switch ([self credentialsStatus]) {
        case SPSDKHasUniqueCredentialsItem:
            credentialsToReturn = [[[self activeCredentialsItems] allValues] lastObject];
            break;
        case SPSDKHasNoCredentials:
            [self throwNoCredentialsException];
            break;
        case SPSDKHasMultipleCredentialsItems:
            [self throwNoUniqueCredentialsException];
            break;
    }
    return credentialsToReturn;
}

- (SPSDKCredentialsStatus)credentialsStatus
{
    SPSDKCredentialsStatus status;
    switch(self.activeCredentialsItems.count) {
        case 0:
            status = SPSDKHasNoCredentials;
            break;
        case 1:
            status = SPSDKHasUniqueCredentialsItem;
            break;
        default:
            status = SPSDKHasMultipleCredentialsItems;
            break;
    }
    return status;
}

- (SPCredentials *)credentialsForToken:(NSString *)credentialsToken
{
    SPCredentials *credentials = [self.activeCredentialsItems objectForKey:credentialsToken];

    if (!credentials) {
        return nil;
    }

    return credentials;
}

#pragma mark - Credentials related exceptions

- (void)throwNoCredentialsException
{
    NSString *exceptionReason = @"Please start the SDK with "
    "[SponsorPaySDK startForAppId:userId:securityToken:] before accessing any of its resources";
    [NSException raise:SPNoCredentialsException format:@"%@", exceptionReason];
}

- (void)throwInvalidCredentialsTokenException
{
    NSString *exceptionReason = @"Please use [SponsorPaySDK startForAppId:userId:securityToken:] "
    "to obtain a valid credentials token. (No credentials found for the credentials token specified.)";
    [NSException raise:SPInvalidCredentialsTokenException format:@"%@", exceptionReason];
}

- (void)throwNoUniqueCredentialsException
{
    NSString *exceptionReason = @"More than one active SponsorPay appId / userId. Please use the credentials token "
    "to specify the appId / userId combination for which you're accessing the desired resource.";
    [NSException raise:SPNoUniqueCredentialsException format:@"%@", exceptionReason];
}

#pragma mark - Default credentials per product

- (SPCredentials *)credentialsForProduct:(NSString *)productKey
{
    SPCredentials *credentialsToReturn = nil;
    switch (self.credentialsStatus) {
        case SPSDKHasUniqueCredentialsItem: {
            credentialsToReturn = [self uniqueCredentialsItem];
            break;
        }
        case SPSDKHasNoCredentials: {
            break;
        }
        case SPSDKHasMultipleCredentialsItems: {
            NSString *token = self.credentialTokensByProduct[productKey];
            if (token) {
                credentialsToReturn = [self credentialsForToken:token];
            } else {
                credentialsToReturn = [self credentialsForToken:self.defaultCredentialsToken];
                // These will be fixed as the credentials for this product from now on
                [self setDefaultCredentials:credentialsToReturn.credentialsToken forProduct:productKey];

                SPLogWarn(@"Warning: the SponsorPay SDK has been initialized with multiple credentials, "
                 "but none of them has been set as default credentials for the product requested (%@)",
                 productKey);
            }
            break;
        }
    }
    return credentialsToReturn;
}

- (void)setDefaultCredentials:(NSString *)credentialsToken forProduct:(NSString *)productKey
{
    if (!self.credentialTokensByProduct[productKey]) {
        self.credentialTokensByProduct[productKey] = credentialsToken;
    } else {
        SPLogWarn(@"Warning: attempting to re-set default credentials for product: %@", productKey);
    }
}

#pragma mark - Configuration per credentials item

- (SPCredentials *)setConfigurationValue:(id)value
                                  forKey:(NSString *)key
                  inCredentialsWithToken:(NSString *)token
{
    SPCredentials *credentials = [self credentialsForToken:token];
    credentials.userConfig[key] = value;
    return credentials;
}

- (void)setConfigurationValueInAllCredentials:(id)value
                                       forKey:(NSString *)key
{
    if (!self.activeCredentialsItems.count) {
        NSString *exceptionReason = @"Please start the SDK with [SponsorPaySDK startForAppId:userId:securityToken:] before setting any of its configuration values.";
        [NSException raise:@"SponsorPaySDKNotStarted" format:@"%@", exceptionReason];
    }

    NSArray *allCredentialTokens = self.activeCredentialsItems.allKeys;

    for (NSString *token in allCredentialTokens)
        [self setConfigurationValue:value forKey:key inCredentialsWithToken:token];
}

@end
