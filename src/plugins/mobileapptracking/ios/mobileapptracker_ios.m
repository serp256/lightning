
#import <caml/mlvalues.h>
#import <MobileAppTracker/MobileAppTracker.h>



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


void ml_MATinit(value advertiser_id, value conversion_key, value site_id, value unit) {
	NSString *adv = [NSString stringWithCString:String_val(advertiser_id) encoding:NSASCIIStringEncoding];
	NSString *ck = [NSString stringWithCString:String_val(conversion_key) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] startTrackerWithMATAdvertiserId:adv MATConversionKey:ck withError:nil];
	if (site_id != 1) {
		NSString *siteId = [NSString stringWithCString:String_val(Field(site_id,0)) encoding:NSASCIIStringEncoding];
		[[MobileAppTracker sharedManager] setSiteId:siteId];
	}
	//[[MobileAppTracker sharedManager] setDebugMode:YES];
	//[[MobileAppTracker sharedManager] setAllowDuplicateRequests:YES];
	//MyDelegateHandler *matHandler = [[[MyDelegateHandler alloc] init] autorelease];
	//[[MobileAppTracker sharedManager] setDelegate:matHandler];
}


void ml_MATsetUserId(value user_id) {
	NSString *uid = [NSString stringWithCString:String_val(user_id) encoding:NSASCIIStringEncoding];
	[[MobileAppTracker sharedManager] setUserId:uid];
}


void ml_MATinstall(value unit) {
	[[MobileAppTracker sharedManager] trackInstall];
}

void ml_MATupdate(value unit) {
	[[MobileAppTracker sharedManager] trackUpdate];
}
