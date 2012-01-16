#import "FBConnect.h"

@interface FacebookController : NSObject <FBSessionDelegate> {
  Facebook * _facebook;
}
-(id)initWithAppId:(NSString *)appid;
@property (nonatomic, retain) Facebook * facebook;
@end


