// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import "TJCEventTrackingRequestHandler.h"
#import "TJCCoreFetcherHandler.h"
#import "TJCLog.h"
#import "TapjoyConnect.h"
#import "TJCCoreFetcher.h"
#import "TJCUtil.h"
#import "TJCConstants.h"

@implementation TJCEventTrackingRequestHandler

-(id)initRequestWithDelegate:(id<TJCFetchResponseDelegate>) aDelegate andRequestTag:(int)aTag
{
	if((self = [super initRequestWithDelegate:aDelegate andRequestTag:aTag]))
	{
	}
	return self;
}

- (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode
{
    NSString *requestString = [NSString stringWithFormat:@"%@%@", TJC_SERVICE_URL, TJC_EVENT_TRACKING_API];
	NSString *alternateString = [NSString stringWithFormat:@"%@%@", TJC_SERVICE_URL_ALTERNATE, TJC_EVENT_TRACKING_API];
	
	NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] initWithDictionary:[[TapjoyConnect sharedTapjoyConnect] genericParameters]];
	
	// Add the publisher user ID to the generic parameters dictionary.
	if ([TapjoyConnect getUserID])
	{
		[paramDict setObject:[TapjoyConnect getUserID] forKey:TJC_URL_PARAM_USER_ID];
	}
    
    // Add the IAP data to the params
    [paramDict setObject:@"1" forKey:TJC_URL_PARAM_EVENT_TYPE];
    [paramDict setObject:name forKey:[NSString stringWithFormat:@"ue[%@]", TJC_URL_PARAM_EVENT_DATA_NAME]];
    [paramDict setObject:[NSNumber numberWithFloat:price] forKey:[NSString stringWithFormat:@"ue[%@]", TJC_URL_PARAM_EVENT_DATA_PRICE]];
	[paramDict setObject:[NSNumber numberWithInt:quantity] forKey:[NSString stringWithFormat:@"ue[%@]", TJC_URL_PARAM_EVENT_DATA_QUANTITY]];
	[paramDict setObject:currencyCode forKey:[NSString stringWithFormat:@"ue[%@]", TJC_URL_PARAM_EVENT_DATA_CURRENCY_CODE]];

	NSString *newVerifier = [TapjoyConnect TJCSHA256CommonParamsWithTimeStamp:nil string:@"1"];
	[paramDict setObject:newVerifier forKey:TJC_VERIFIER];
	
    // Make a POST request
    [self makeGenericPOSTRequestWithURL:requestString
                           alternateURL:alternateString
                                   data:NULL
                                 params:paramDict 
                               selector:@selector(eventTrackingResponseRecieved:)];
	
	[paramDict release];
}

- (void)eventTrackingResponseRecieved:(TJCCoreFetcher*)myFetcher
{
    [TJCLog logWithLevel:LOG_DEBUG format:@"TJCEventTrackingRequestHandler Response Returned: %d", myFetcher.responseCode];

    if (myFetcher.responseCode == 200)
    {
        [deleg_ fetchResponseSuccessWithData:nil withRequestTag:myFetcher.responseCode];
    }
    else
    {
        [deleg_ fetchResponseError:kTJCStatusNotOK errorDescription:nil requestTag:myFetcher.responseCode];
    }
}


- (void)dealloc
{
	[super dealloc];
}

@end
