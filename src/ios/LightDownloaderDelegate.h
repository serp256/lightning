#import <Foundation/Foundation.h>
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"

@interface LightDownloaderDelegate : NSObject <NSURLConnectionDataDelegate> {
	value *success;
	value *error;
	value *progress;

	NSFileHandle *tmpFile;
	NSString* filename;
	NSString* tmpFilename;
	long long expectedLen;
	long long loadedLen;
	long long resumeFrom;
}

- (id)initWithSuccess: (value) sccss error: (value) err progress: (value) prgrss filename: (NSString*) fname tmpFilename: (NSString*) tmpFname tmpFile: (NSFileHandle*) tmpF;

@end
