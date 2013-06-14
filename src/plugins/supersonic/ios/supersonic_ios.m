#import "caml/mlvalues.h"
#import "SupersonicAdsPublisher.h"
#import "LightViewController.h"

void ml_supersonicShowOffers(value v_appKey, value v_appUid) {
	NSString* m_appKey = [NSString stringWithCString:String_val(v_appKey) encoding:NSASCIIStringEncoding];
	NSString* m_appUid = [NSString stringWithCString:String_val(v_appUid) encoding:NSASCIIStringEncoding];

	[[SupersonicAdsPublisher sharedSupersonicAds] showOfferWallWithApplicationKey:m_appKey userId:m_appUid delegate:nil shouldGetLocation:NO extraParameters:nil parentView:[LightViewController sharedInstance]];
}