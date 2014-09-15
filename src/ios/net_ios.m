
#import <Foundation/Foundation.h>
#import "LightViewController.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>

#import "LightDownloaderDelegate.h"

#import "light_common.h"

CAMLprim value ml_URLConnection(value url, value method, value headers, value data) {
	CAMLparam4(url,method,headers,data);
	NSURL *nsurl = [[NSURL alloc] initWithString:[NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding]];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
	static value ml_POST = 0;
	if (ml_POST == 0) ml_POST = caml_hash_variant("POST");
	if (method == ml_POST) [request setHTTPMethod:@"POST"];
	//[request setHTTPMethod:[NSString stringWithCString:String_val(method) encoding:NSASCIIStringEncoding]];
	// add headers
	value el = headers;
	value mlh;
	while (Is_block(el)) {
		mlh = Field(el,0);
		[request addValue:[NSString stringWithCString:String_val(Field(mlh,1)) encoding:NSASCIIStringEncoding] forHTTPHeaderField:[NSString stringWithCString:String_val(Field(mlh,0)) encoding:NSASCIIStringEncoding]];
		el = Field(el,1);
	};
	// set body
	if (Is_block(data)) {
		value d = Field(data,0);
		NSData *nsdata = [[NSData alloc] initWithBytes:String_val(d) length:caml_string_length(d)];
		[request setHTTPBody:nsdata];
		[nsdata release];
	}
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:[LightViewController sharedInstance] startImmediately:YES];
	[nsurl release];
	[request release];
	CAMLreturn((value)connection);
}

value ml_URLConnection_cancel(value connection) {
  [(NSURLConnection*)connection cancel];
	return Val_unit;
}

value ml_DownloadFile(value vurl, value vpath, value verr, value vprgrss, value vsccss) {
	CAMLparam5(vurl, vpath, verr, vprgrss, vsccss);

	NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithUTF8String:String_val(vurl)]];
	NSURLRequest* req = [[NSURLRequest alloc] initWithURL:url];
	LightDownloaderDelegate* delegate = [[LightDownloaderDelegate alloc] initWithSuccess:vsccss error:verr progress:vprgrss filename:[NSString stringWithUTF8String:String_val(vpath)]];
	[[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];

	[url release];
	[req release];
	[delegate release];

	CAMLreturn(Val_unit);
}
