#import <caml/mlvalues.h>
#import "FyberSDK.h"

@interface VideoDelegate : NSObject <FYBRewardedVideoControllerDelegate, FYBVirtualCurrencyClientDelegate>
{
	value *_requestCallback;
	value *_showCallback;
  BOOL didReceiveOffers;
}

- (void)setRequestCallback:(value)c;
- (void)setShowCallback:(value)c;
- (void)runShowCallback;

@end
