
#import <caml/mlvalues.h>
#import <caml/fail.h>
#import <MobileAppTracker/MobileAppTracker.h>

static int initialized = 0;


/*
@interface MyDelegateHandler : NSObject <MobileAppTrackerDelegate> @end


@implementation MyDelegateHandler

#pragma mark - MobileAppTrackerDelegate Methods

- (void)mobileAppTracker:(MobileAppTracker *)tracker didSucceedWithData:(NSData *)data {
		NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"MAT.didSucceed:");
		NSLog(@"%@", response); 
}

- (void)mobileAppTracker:(MobileAppTracker *)tracker didFailWithError:(NSError *)error {
		NSLog(@"MAT.didFail:");
		NSLog(@"%@", error); 
}
@end
*/


value ml_MATinit(value advertiser_id, value conversion_key, value site_id, value unit) {
	if (initialized) return Val_unit;
	NSString *adv = [NSString stringWithCString:String_val(advertiser_id) encoding:NSASCIIStringEncoding];
	NSString *ck = [NSString stringWithCString:String_val(conversion_key) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] startTrackerWithMATAdvertiserId:adv MATConversionKey:ck withError:nil];
	if (site_id != 1) {
		NSString *siteId = [NSString stringWithCString:String_val(Field(site_id,0)) encoding:NSASCIIStringEncoding];
		[[MobileAppTracker sharedManager] setSiteId:siteId];
	}
	initialized = 1;
	//[[MobileAppTracker sharedManager] setDebugMode:YES];
	//[[MobileAppTracker sharedManager] setAllowDuplicateRequests:YES];
	//MyDelegateHandler *matHandler = [[[MyDelegateHandler alloc] init] autorelease];
	//[[MobileAppTracker sharedManager] setDelegate:matHandler];
	return Val_unit;
}


value ml_MATsetUserId(value user_id) {
	if (!initialized) caml_failwith("MobileAppTracker not initialized");
	NSString *uid = [NSString stringWithCString:String_val(user_id) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] setUserId:uid];
	return Val_unit;
}


value ml_MATinstall(value unit) {
	if (!initialized) caml_failwith("MobileAppTracker not initialized");
	[[MobileAppTracker sharedManager] trackInstall];
	return Val_unit;
}

value ml_MATupdate(value unit) {
	if (!initialized) caml_failwith("MobileAppTracker not initialized");
	[[MobileAppTracker sharedManager] trackUpdate];
	return Val_unit;
}

value ml_MATtrackAction(value eventID) {
	if (!initialized) caml_failwith("MobileAppTracker not initialized");
	NSString *ns_eventID = [NSString stringWithCString:String_val(eventID) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] trackActionForEventIdOrName:ns_eventID eventIsId:YES];
	return Val_unit;
}


value ml_MATtrackPurchase(value eventID,value amount,value currency) {
	if (!initialized) caml_failwith("MobileAppTracker not initialized");
	NSString *ns_eventID = [NSString stringWithCString:String_val(eventID) encoding:NSASCIIStringEncoding];
	NSString *currencyCode = [NSString stringWithCString:String_val(currency) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] trackActionForEventIdOrName:ns_eventID eventIsId:YES revenueAmount:Double_val(amount) currencyCode:currencyCode];
	return Val_unit;
};
