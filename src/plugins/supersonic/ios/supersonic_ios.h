#import "SupersonicAdsPublisher.h"

@interface OfferWallDelegate : NSObject <OfferWallDelegate> {
	NSTimer* tmr;
}

-(void)offerWallDidClose;
-(void)runTimer;
@end