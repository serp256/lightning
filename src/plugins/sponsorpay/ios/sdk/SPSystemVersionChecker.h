//
//  SPSystemVersionChecker.h
//  SponsorPayTestApp
//
//  Created by tito on 04/09/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPSystemVersionChecker : NSObject

+ (BOOL)runningOniOS5OrNewer;
+ (BOOL)runningOniOS6OrNewer;
+ (BOOL)runningOniOS7OrNewer;
+ (BOOL)checkForiOSVersion:(NSString *)versionString;

@end