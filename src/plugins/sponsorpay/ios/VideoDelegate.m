#import "VideoDelegate.h"
#import "LightViewController.h"
#import "mlwrapper.h"
#import <caml/memory.h>

@implementation VideoDelegate

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient
         didReceiveOffers:(BOOL)areOffersAvailable
{
	RUN_CALLBACK(_requestCallback, areOffersAvailable ? Val_true : Val_false);
}

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient
          didChangeStatus:(SPBrandEngageClientStatus)newStatus
{
	NSLog(@"brandEngageClient didChangeStatus %d", newStatus);

	switch (newStatus) {
		case STARTED:
			break;

		case CLOSE_FINISHED:
			RUN_CALLBACK(_showCallback, Val_unit);
			break;

		case CLOSE_ABORTED:
			break;

		case ERROR:
			break;
	}
}

- (void)setRequestCallback:(value)c
{
	FREE_CALLBACK(_requestCallback);
	REG_CALLBACK(c, _requestCallback);
}

- (void)setShowCallback:(value)c
{
	FREE_CALLBACK(_showCallback);
	REG_CALLBACK(c, _showCallback);
}

- (id)init
{
	_requestCallback = 0;
	_showCallback = 0;

	return [super init];
}

@end