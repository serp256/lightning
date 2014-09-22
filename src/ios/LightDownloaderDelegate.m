#import "LightDownloaderDelegate.h"

@implementation LightDownloaderDelegate

- (id)initWithSuccess: (value) sccss error: (value) err progress: (value) prgrss filename: (NSString*) fname {
	REG_CALLBACK(sccss, success);
	REG_OPT_CALLBACK(err, error);
	REG_OPT_CALLBACK(prgrss, progress);
	filename = fname;
	[filename retain];

	return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSError* err = nil;

	if ([data writeToFile:filename options:NSDataWritingAtomic error:&err]) {
		RUN_CALLBACK(success, Val_unit);
	} else if (error && err) {
		RUN_CALLBACK2(error, Val_int([err code]), caml_copy_string([[err localizedDescription] UTF8String]));
	}

	[connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
	if (error) {
		RUN_CALLBACK2(error, Val_int([err code]), caml_copy_string([[err localizedDescription] UTF8String]));
	}
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"!!!!connection didReceiveResponse %lld, %@", [response expectedContentLength], [response allHeaderFields]);

	expectedLen = [response expectedContentLength];
	loadedLen = 0;

	if (expectedLen != NSURLResponseUnknownLength) {
			data = [[NSMutableData alloc] initWithCapacity:expectedLen];
	} else {
			data = [[NSMutableData alloc] initWithLength:1];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk {
	loadedLen += [chunk length];
	[data appendData:chunk];

	if (progress) {
		RUN_CALLBACK3(progress, caml_copy_double((double)loadedLen), caml_copy_double((double)expectedLen), Val_unit);
	}
}

- (void) dealloc {
    FREE_CALLBACK(success);
    FREE_CALLBACK(error);
    FREE_CALLBACK(progress);
    [data release];
    [filename release];

    [super dealloc];
}

@end
