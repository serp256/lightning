// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import "TJCEventTrackingManager.h"
#import "SynthesizeSingleton.h"
#import "TJCEventTrackingRequestHandler.h"
#import "TapjoyConnect.h"

@implementation TJCEventTrackingManager

TJC_SYNTHESIZE_SINGLETON_FOR_CLASS(TJCEventTrackingManager)


- (id)init
{
    if ((self = [super init]))
    {
        eventTrackingSendIAPItems_ = nil;
        waitingForResponse_ = NO;
    }
    return self;
}

- (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode
{
    if (!name)
    {
		[TJCLog logWithLevel: LOG_NONFATAL_ERROR
                      format: @"TJCEventTrackingManager warning: sendIAPEventWithName:andPrice: cannot be called with no IAPs to send."];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TJC_EVENT_TRACKING_RESPONSE_NOTIFICATION_ERROR 
                                                            object:nil];
		
		return;
    }
    
    if (waitingForResponse_)
	{
		[TJCLog logWithLevel: LOG_NONFATAL_ERROR
                      format: @"TJCEventTrackingManager warning: sendIAPEventWithName:andPrice: cannot be called until response from the server has been received."];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TJC_EVENT_TRACKING_RESPONSE_NOTIFICATION_ERROR 
                                                            object:nil];
		
		return;
	}
	
	if (eventTrackingSendIAPItems_)
	{
		[eventTrackingSendIAPItems_ release];
		eventTrackingSendIAPItems_ = nil;
	}
	
	eventTrackingSendIAPItems_ = [[TJCEventTrackingRequestHandler alloc] initRequestWithDelegate:self 
                                                                                  andRequestTag:0];
	
	[eventTrackingSendIAPItems_ sendIAPEventWithName:name price:price quantity:quantity currencyCode:currencyCode];
	
	waitingForResponse_ = YES;
}

// called when request succeeeds
- (void)fetchResponseSuccessWithData:(void*)dataObj withRequestTag:(int)aTag
{
	waitingForResponse_ = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TJC_EVENT_TRACKING_RESPONSE_NOTIFICATION
                                                        object:nil];
}

// raised when error occurs
- (void)fetchResponseError:(TJCResponseError)errorType errorDescription:(id)errorDescObj requestTag:(int) aTag
{
	waitingForResponse_ = NO;
    
    [TJCLog logWithLevel: LOG_NONFATAL_ERROR
                  format: @"TJCEventTrackingManager sendIAPEvent error"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TJC_EVENT_TRACKING_RESPONSE_NOTIFICATION_ERROR 
                                                        object:nil];
}

- (void) dealloc
{
	[eventTrackingSendIAPItems_ release];
	[super dealloc];
}

@end

@implementation TapjoyConnect (TJCEventTrackingManager)
+ (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode
{
    [[TJCEventTrackingManager sharedTJCEventTrackingManager] sendIAPEventWithName:name price:price quantity:quantity currencyCode:currencyCode];
}

@end
