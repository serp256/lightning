
#import <Foundation/Foundation.h>
#import "LightViewController.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>

CAMLprim value ml_URLConnection(value url, value method, value headers, value data) {
	CAMLparam4(url,method,headers,data);
	NSURL *nsurl = [[NSURL alloc] initWithString:[NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding]];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
	[request setHTTPMethod:[NSString stringWithCString:String_val(method) encoding:NSASCIIStringEncoding]];
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

void ml_URLConnection_cancel(value connection) {
  [(NSURLConnection*)connection cancel];
}
