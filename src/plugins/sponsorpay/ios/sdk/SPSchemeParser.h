//
//  SPSchemeParser.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/18/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SP_URL_scheme.h"
#import "NSString+SPURLEncoding.h"
#import "NSURL+SPParametersParsing.h"

@interface SPSchemeParser : NSObject

@property (strong, nonatomic) NSURL *URL;
@property (assign, nonatomic) BOOL shouldRequestCloseWhenOpeningExternalURL;

@property (assign, nonatomic, readonly) BOOL requestsContinueWebViewLoading;
@property (assign, nonatomic, readonly) BOOL requestsOpeningExternalDestination;
@property (strong, nonatomic, readonly) NSURL *externalDestination;
@property (assign, nonatomic, readonly) BOOL requestsClosing;
@property (assign, nonatomic, readonly) BOOL requestsStopShowingLoadingActivityIndicator;
@property (assign, nonatomic, readonly) NSInteger closeStatus;

@property (copy, nonatomic, readonly) NSString *command;

@property (copy, nonatomic, readonly) NSString *appId;

@end
