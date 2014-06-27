#import "caml/mlvalues.h"
#import "SponsorPaySDK.h"
#import "SPLogger.h"
#import <objc/runtime.h>
#import "LightViewController.h"
#import <caml/memory.h>
#import "VideoDelegate.h"
#import "mlwrapper.h"

value ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken, value v_networks) {
	CAMLparam4(v_appId, v_userId, v_securityToken, v_networks);
	CAMLlocal2(ntwks, ntwk);

	NSString* m_appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
	NSString* m_userId = Is_block(v_userId) ? [NSString stringWithCString:String_val(Field(v_userId, 0)) encoding:NSASCIIStringEncoding] : nil;
	NSString* m_securityToken = Is_block(v_securityToken) ? [NSString stringWithCString:String_val(Field(v_securityToken, 0)) encoding:NSASCIIStringEncoding] : nil;

	NSMutableArray* networks = [[NSMutableArray alloc] init];

	if (Is_block(v_networks)) {
		ntwks = Field(v_networks, 0);

		value applifier_variant = caml_hash_variant("applifier");
		value applovin_variant = caml_hash_variant("applovin");

		while (Is_block(ntwks)) {
			ntwk = Field(ntwks, 0);
			ntwks = Field(ntwks, 1);

			while (1) {
				if (Field(ntwk, 0) == applifier_variant) {
					NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:@YES, @"SPApplifierShowOffers", [NSString stringWithUTF8String:String_val(Field(ntwk, 1))], @"SPApplifierGameId", nil];
					NSDictionary* network = [NSDictionary dictionaryWithObjectsAndKeys:@"Applifier", @"SPNetworkName", params, @"SPNetworkParameters", nil];
					[networks addObject:network];

					break;
				}

				if (Field(ntwk, 0) == applovin_variant) {
					NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:String_val(Field(ntwk, 1))], @"SPAppLovinSdkKey", nil];
					NSDictionary* network = [NSDictionary dictionaryWithObjectsAndKeys:@"AppLovin", @"SPNetworkName", params, @"SPNetworkParameters", nil];
					[networks addObject:network];
					
					break;
				}
			}
		}

		NSLog(@"networks %@", networks);
		[SponsorPaySDK startForAppId:m_appId userId:m_userId securityToken:m_securityToken withNetworks:networks];
	} else {
		[SponsorPaySDK startForAppId:m_appId userId:m_userId securityToken:m_securityToken];
	}

	CAMLreturn(Val_unit);
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

SPBrandEngageClient* engageClient = nil;
VideoDelegate* delegate = nil;

#define INIT_ENGAGE_CLIENT 	if (!engageClient) {			\
		engageClient = [SponsorPaySDK brandEngageClient];	\
		delegate = [[VideoDelegate alloc] init];			\
		engageClient.delegate = delegate;					\
	}

value ml_request_video(value callback) {
	CAMLparam1(callback);
	INIT_ENGAGE_CLIENT;

	NSLog(@"ml_request_video call");
	
	if ([engageClient canRequestOffers]) {
		[delegate setRequestCallback:callback];
		[engageClient requestOffers];		
	} else {
		RUN_CALLBACK(callback, Val_false);
	}

	CAMLreturn(Val_unit);
}

value ml_show_video(value callback) {
	CAMLparam1(callback);
	INIT_ENGAGE_CLIENT;

	NSLog(@"canStartOffers %d", [engageClient canStartOffers]);

	if ([engageClient canStartOffers]) {
		[delegate setShowCallback:callback];
		[engageClient startWithParentViewController:[LightViewController sharedInstance]];
	}

	CAMLreturn(Val_unit);
}