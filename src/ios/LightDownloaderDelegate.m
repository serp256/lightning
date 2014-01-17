#import "LightDownloaderDelegate.h"

#define REG_CALLBACK(src, dst) { dst = src; caml_register_generational_global_root(&dst); }
#define REG_OPT_CALLBACK(src, dst) if (Is_block(src)) { dst = Field(src, 0); caml_register_generational_global_root(&dst); } else { dst = 0; }
#define FREE_CALLBACK(callback) if (callback) { caml_remove_generational_global_root(&callback); }

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
	NSError* err = [[NSError alloc] init];

	if ([data writeToFile:filename options:NSDataWritingAtomic error:&err]) {
		caml_callback(success, Val_unit);	
	} else if (error) {
		caml_callback2(error, Val_int([err code]), caml_copy_string([[err localizedDescription] UTF8String]));
	}

	[err release];
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
	if (error) {
		caml_callback2(error, Val_int([err code]), caml_copy_string([[err localizedDescription] UTF8String]));
	}
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	expectedLen = [response expectedContentLength];
	loadedLen = 0;
	data = [[NSMutableData alloc] initWithCapacity:expectedLen];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk {
	loadedLen += [chunk length];
	[data appendData:chunk];

	if (progress) {
		caml_callback3(progress, caml_copy_double((double)loadedLen), caml_copy_double((double)expectedLen), Val_unit);
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