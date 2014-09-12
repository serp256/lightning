//
//  SPSchemeParser.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/18/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPSchemeParser.h"

static BOOL isEmptyString(NSString *string);

@interface SPSchemeParser ()

@property (assign, nonatomic, readwrite) BOOL requestsContinueWebViewLoading;
@property (assign, nonatomic, readwrite) BOOL requestsOpeningExternalDestination;
@property (strong, nonatomic, readwrite) NSURL *externalDestination;
@property (assign, nonatomic, readwrite) BOOL requestsClosing;
@property (assign, nonatomic, readwrite) BOOL requestsStopShowingLoadingActivityIndicator;
@property (assign, nonatomic, readwrite) NSInteger closeStatus;

@property (copy, nonatomic, readwrite) NSString *command;
@property (copy, nonatomic, readwrite) NSString *appId;


@end

@implementation SPSchemeParser

- (id)init
{
    self = [super init];
    
    if (self) {
        [self resetOutputs];
    }
    
    return self;
}

- (void)setURL:(NSURL *)URL
{
    _URL = URL;
    
    [self determineOutputsBasedOnURL];
}

- (void)determineOutputsBasedOnURL
{
	[self resetOutputs];

    NSString *scheme = [self.URL scheme];
	
    if (![scheme isEqualToString:SPONSORPAY_URL_SCHEME]) {
        return;
    }
    
    _requestsContinueWebViewLoading = NO;
    
    NSString *command = [self.URL host];
    self.command = command;
    if ([command isEqualToString:SPONSORPAY_EXIT_PATH]) {
        [self processExitCommand];
    } else if ([command isEqualToString:SPONSORPAY_START_PATH]) {
        [self processStartCommand];
    } else if ([command isEqualToString:SPONSORPAY_INSTALL_PATH]) {
        [self processInstallCommand];
    }
}

- (void)resetOutputs
{
    self.requestsContinueWebViewLoading = YES;
    self.requestsOpeningExternalDestination = NO;
    self.requestsClosing = NO;
    self.requestsStopShowingLoadingActivityIndicator = NO;
    self.closeStatus = 0;
    self.command = nil;
    self.appId = nil;
    self.externalDestination = nil;
}

- (void)processStartCommand
{
    self.requestsStopShowingLoadingActivityIndicator = YES;
}

- (void)processExitCommand
{
    NSDictionary *queryDict = [self.URL SPQueryDictionary];
    NSString *destination = [[queryDict[@"url"] SPURLDecodedString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    BOOL isDestinationEmpty = isEmptyString(destination);

    if (isDestinationEmpty) {
        self.requestsClosing = YES;
    } else {
        self.externalDestination = [[NSURL alloc] initWithString:destination];
        self.requestsOpeningExternalDestination = YES;
        self.requestsClosing =  self.shouldRequestCloseWhenOpeningExternalURL;
    }

    if (self.requestsClosing) {
        self.closeStatus = [[queryDict objectForKey:@"status"] intValue];
    }
}

- (void)processInstallCommand
{
    NSDictionary *queryDict = [self.URL SPQueryDictionary];
    self.appId = [[queryDict valueForKey:@"id"] SPURLDecodedString];
    self.requestsClosing =  self.shouldRequestCloseWhenOpeningExternalURL;
}

@end

static BOOL isEmptyString(NSString *string)
{
    return string == nil || [string isEqualToString:@""];
}
