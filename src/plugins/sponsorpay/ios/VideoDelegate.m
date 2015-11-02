#import "VideoDelegate.h"
#import "LightViewController.h"
#import "mlwrapper.h"
#import <caml/memory.h>

@implementation VideoDelegate

/*
- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient didReceiveOffers:(BOOL)areOffersAvailable {
	RUN_CALLBACK(_requestCallback, areOffersAvailable ? Val_true : Val_false);
	FREE_CALLBACK(_requestCallback);
}

*/
- (void)runShowFailCallback {
	if (_showCallback != 0) {
			RUN_CALLBACK(_showCallback, Val_false);
			FREE_CALLBACK(_showCallback);
			_showCallback = 0;
	}
}

/*
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
			[self runShowCallback];
			break;

		case ERROR:
			[self runShowCallback];
			break;
	}
}
*/
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

#pragma mark FYBRewardedVideoControllerDelegate - Request Video

- (void)rewardedVideoControllerDidReceiveVideo:(FYBRewardedVideoController *)rewardedVideoController
{
    NSLog(@"Did receive offer");
    
    didReceiveOffers = YES;
		RUN_CALLBACK(_requestCallback, didReceiveOffers ? Val_true : Val_false);
		FREE_CALLBACK(_requestCallback);

}

- (void)rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController didFailToReceiveVideoWithError:(NSError *)error
{
    NSLog(@"Did not receive any offer %@", [error localizedDescription]);
    
    didReceiveOffers = NO;
		RUN_CALLBACK(_requestCallback, didReceiveOffers ? Val_true : Val_false);
		FREE_CALLBACK(_requestCallback);
    
}


#pragma mark FYBRewardedVideoControllerDelegate - Show Video

- (void)rewardedVideoControllerDidStartVideo:(FYBRewardedVideoController *)rewardedVideoController
{
}

- (void)rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController didDismissVideoWithReason:(FYBRewardedVideoControllerDismissReason)reason
{
		NSLog(@"didDismissVideoWithReason %d", reason);

		switch (reason) {
			case FYBRewardedVideoControllerDismissReasonUserEngaged:
				NSLog(@"User engaged");
				RUN_CALLBACK(_showCallback, Val_true);
				FREE_CALLBACK(_showCallback);
				break;

			case FYBRewardedVideoControllerDismissReasonAborted:
				[self runShowFailCallback];
				break;

			case FYBRewardedVideoControllerDismissReasonError:
				[self runShowFailCallback];
				break;
		}
    
}

- (void)rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController didFailToStartVideoWithError:(NSError *)error
{
		NSLog(@"didFailToStartVideoWithError %@", [error localizedDescription]);
   didReceiveOffers = NO;
	 [self runShowFailCallback];
    
}



/*
- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC isFinishedWithStatus:(int)status {
	NSLog(@"offerWall status %d", status);
	if (status == SPONSORPAY_ERR_NETWORK) {
		NSLog(@"SPONSORPAY_ERR_NETWORK");
	}
 }
*/
- (void)virtualCurrencyClient:(FYBVirtualCurrencyClient *)client didReceiveResponse:(FYBVirtualCurrencyResponse *)response
{
    NSLog(@"Received %@ %@", @(response.deltaOfCoins), response.currencyName);
			RUN_CALLBACK(_showCallback, Val_true);
			FREE_CALLBACK(_showCallback);
}

- (void)virtualCurrencyClient:(FYBVirtualCurrencyClient *)client didFailWithError:(NSError *)error
{
    NSLog(@"Failed to receive virtual currency %@", error);
}

@end
