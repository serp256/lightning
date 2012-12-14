#import <FacebookSDK/FacebookSDK.h>
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/alloc.h>

@interface FacebookController : NSObject
{
	FBSession* fbSession;
}

-(void)connect:(NSString*)appId;

@end
/*#import "FBConnect.h"

@interface FacebookController : NSObject <FBSessionDelegate> {
  Facebook * _facebook;
}
-(id)initWithAppId:(NSString *)appid;
@property (nonatomic, retain) Facebook * facebook;
@end


*/