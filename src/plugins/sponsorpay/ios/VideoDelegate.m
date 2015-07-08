#import "VideoDelegate.h"
#import "LightViewController.h"
#import "mlwrapper.h"
#import <caml/memory.h>

@implementation VideoDelegate

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient didReceiveOffers:(BOOL)areOffersAvailable {
	RUN_CALLBACK(_requestCallback, areOffersAvailable ? Val_true : Val_false);
	FREE_CALLBACK(_requestCallback);
}

- (void)runShowCallback {
	if (_showCallback != 0) {
			RUN_CALLBACK(_showCallback, Val_false);
			FREE_CALLBACK(_showCallback);
			_showCallback = 0;
	}
}

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient didChangeStatus:(SPBrandEngageClientStatus)newStatus {
	NSLog(@"brandEngageClient didChangeStatus %ld", newStatus);

	switch (newStatus) {
		case STARTED:
			break;

		case CLOSE_FINISHED:
			RUN_CALLBACK(_showCallback, Val_true);
			FREE_CALLBACK(_showCallback);
			break;

		case CLOSE_ABORTED:
			RUN_CALLBACK(_showCallback, Val_false);
			FREE_CALLBACK(_showCallback);
			break;

		case ERROR:
			[self runShowCallback];
			break;
	}
}

- (void)setRequestCallback:(value)c {
	NSLog(@"set req cb");
	REG_CALLBACK(c, _requestCallback);
}

- (void)setShowCallback:(value)c {
	NSLog(@"set show cb");
	REG_CALLBACK(c, _showCallback);
}

- (id)init {
	_requestCallback = 0;
	_showCallback = 0;

	return [super init];
}

- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC isFinishedWithStatus:(int)status {
	NSLog(@"offerWall status %d", status);
	if (status == SPONSORPAY_ERR_NETWORK) {
		NSLog(@"SPONSORPAY_ERR_NETWORK");
	}
 }
@end
