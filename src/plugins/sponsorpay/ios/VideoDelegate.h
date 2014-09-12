#import <caml/mlvalues.h>
#import "SponsorPaySDK.h"

@interface VideoDelegate : NSObject <SPBrandEngageClientDelegate>
{
	value *_requestCallback;
	value *_showCallback;
}

- (void)setRequestCallback:(value)c;
- (void)setShowCallback:(value)c;

@end
