#import "FBRequest.h"

@interface FacebookRequestDelegate : NSObject <FBRequestDelegate> {
    int _requestID;
}
- (id)initWithRequestID: (int)requestID;
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error;
- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data;
- (void)request:(FBRequest *)request didLoad:(id)result;
@end