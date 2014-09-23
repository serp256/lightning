#import "LightDownloaderDelegate.h"

@implementation LightDownloaderDelegate

- (id)initWithSuccess: (value) sccss error: (value) err progress: (value) prgrss filename: (NSString*) fname tmpFilename: (NSString*) tmpFname tmpFile: (NSFileHandle*) tmpF {
	REG_CALLBACK(sccss, success);
	REG_OPT_CALLBACK(err, error);
	REG_OPT_CALLBACK(prgrss, progress);
	tmpFilename = tmpFname;
	filename = fname;
	tmpFile = tmpF;
	[tmpFilename retain];
	[filename retain];
	[tmpFile retain];

	return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSError* err = nil;
	[tmpFile closeFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager fileExistsAtPath:filename]) {
		[fileManager removeItemAtPath:filename error:nil];
	}
	
	if ([fileManager moveItemAtPath:tmpFilename toPath:filename error:&err]) {
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
	[[NSFileManager defaultManager] removeItemAtPath:tmpFilename error:nil];
	[connection release];
	[tmpFile closeFile];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"connection didReceiveResponse %lld", [response expectedContentLength]);
	expectedLen = [response expectedContentLength];
	loadedLen = 0;
	resumeFrom = [tmpFile offsetInFile];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk {
	@try {
    [tmpFile writeData:chunk];
		loadedLen += [chunk length];
		if (progress) {
			RUN_CALLBACK3(progress, caml_copy_double((double)(loadedLen + resumeFrom)), caml_copy_double((double)(expectedLen + resumeFrom)), Val_unit);
		}
  }
	@catch ( NSException *e ) {
		[connection cancel];
		[connection release];
		RUN_CALLBACK2(error, Val_int(-1), caml_copy_string([[e reason] UTF8String]));
  }
}

- (void) dealloc {
    FREE_CALLBACK(success);
    FREE_CALLBACK(error);
    FREE_CALLBACK(progress);
    [filename release];
    [tmpFile release];
    [tmpFilename release];

    [super dealloc];
}

@end
