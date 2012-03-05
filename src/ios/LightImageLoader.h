

#import <UIKit/UIKit.h>
#import <caml/mlvalues.h>

@interface LightImageLoader : NSObject {
	NSURLConnection *connection_;
	NSMutableData *data_;
	value successCallback;
	value errorCallback;
}

-(LightImageLoader*)initWithURL:(NSString*)url successCallback:(value)scallback errorCallback:(value)ecallback;
-(void)start;

@end
