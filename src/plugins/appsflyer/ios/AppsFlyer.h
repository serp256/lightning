//
//  AppsFlyer.h
//
//  Copyright 2013 AppsFlyer. All rights reserved.
//  Version 2.5.1.9.7

#import <Foundation/Foundation.h>


@interface AppsFlyer : NSObject{
    
}

+(void)notifyAppID: (NSString*) strdata;
+(void)notifyAppID: (NSString*) strdata event:(NSString*)eventName eventValue:(NSString*)eventValue;

// Set custom device ID. 
+(void) setAppUID:(NSString*)appUID;

// Get AppsFlyer device ID
+(NSString *) getAppsFlyerUID;

// Set currency 
+(void) setCurrencyCode:(NSString*)code;
@end
