#import "caml/mlvalues.h"
#import "SponsorPaySDK.h"
#import <objc/runtime.h>
#import "LightViewController.h"

void ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken) {
	NSString* m_appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
	NSString* m_userId = Is_block(v_userId) ? [NSString stringWithCString:String_val(Field(v_userId, 0)) encoding:NSASCIIStringEncoding] : nil;
	NSString* m_securityToken = Is_block(v_securityToken) ? [NSString stringWithCString:String_val(Field(v_securityToken, 0)) encoding:NSASCIIStringEncoding] : nil;

	[SponsorPaySDK startForAppId:m_appId userId:m_userId securityToken:m_securityToken];	
}

void offerWallViewControllerIMP(id self, SEL _cmd, SPOfferWallViewController* controller, NSInteger status) {
}

void ml_sponsorPay_showOffers() {
	static int protoAdded = 0;
	if (!protoAdded) {
		Class cls = [LightViewController class];
		SEL sel = @selector(offerWallViewController:isFinishedWithStatus:);

		class_addMethod(cls, sel, (IMP)offerWallViewControllerIMP, "v@:@l");
		class_addProtocol(cls, @protocol(SPOfferWallViewControllerDelegate));

		protoAdded = 1;
	}

	if (class_conformsToProtocol([LightViewController class], objc_getProtocol("SPOfferWallViewControllerDelegate"))) {
		[SponsorPaySDK showOfferWallWithParentViewController:[LightViewController sharedInstance]];	
	}	
}
