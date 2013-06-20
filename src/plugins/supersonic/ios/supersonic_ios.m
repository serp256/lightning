#import "caml/mlvalues.h"
#import "SupersonicAdsPublisher.h"
#import "LightViewController.h"
#import <objc/runtime.h>
#import "supersonic_ios.h"

@implementation OfferWallDelegate

- (void)offerWallDidClose {
	NSLog(@"offerWallDidClose %@", [LightViewController sharedInstance].presentedViewController);

	if (![LightViewController sharedInstance].presentedViewController) {
		[[LightViewController sharedInstance] becomeActive];
		[tmr invalidate];
	}
}

- (void)runTimer {
	tmr = [NSTimer scheduledTimerWithTimeInterval:1.0
							target:self
							selector:@selector(offerWallDidClose)
							userInfo:nil
							repeats:YES];
}

@end

void ml_supersonicShowOffers(value v_appKey, value v_appUid) {
	NSString* m_appKey = [NSString stringWithCString:String_val(v_appKey) encoding:NSASCIIStringEncoding];
	NSString* m_appUid = [NSString stringWithCString:String_val(v_appUid) encoding:NSASCIIStringEncoding];

	static id delegate = nil;
	if (!delegate) delegate = [[OfferWallDelegate alloc] init];

	[[SupersonicAdsPublisher sharedSupersonicAds] showOfferWallWithApplicationKey:m_appKey userId:m_appUid delegate:nil shouldGetLocation:NO extraParameters:nil parentView:[LightViewController sharedInstance]];
	[delegate runTimer];
} 