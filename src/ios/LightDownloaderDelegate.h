#import <Foundation/Foundation.h>
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"

@interface LightDownloaderDelegate : NSObject <NSURLConnectionDataDelegate> {
	value success;
	value error;
	value progress;

	NSMutableData* data;
	NSString* filename;
	long long expectedLen;
	long long loadedLen;
}

- (id)initWithSuccess: (value) sccss error: (value) err progress: (value) prgrss filename: (NSString*) fname;

@end
