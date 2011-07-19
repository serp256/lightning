
#import <Foundation/Foundation.h>

void ml_URLConnection(value url, value method, value headers, value data) {
	CAMLparam4(url,method,headers,data);
	NSUrl *nsurl = [[NSUrl alloc] initWithString:[NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding]];
	NSRequest *request = [[NSMutableRequest alloc] initWithURL:nsurl];
	[nsurl release];
	[request setHTTPMethod:[NSString stringWithCString:String_val(method) encoding:NSASCIIStringEncoding]];
	// add headers
	value el = headers;
	value mlh;
	while (Is_block(el)) {
		mlh = Field(el,0);
		[request addValue:[NSString stringWithCString:String_val(Field(mlh,0)) encoding:NSASCIIStringEncoding] forHTTPHeaderFields:[NSString stringWithCString:String_val(Field(mlh,1)) encoding:NSASCIIStringEncoding]];
		el = Field(el,1);
	};
	// set body
	if (Is_block(data)) {
		value d = Field(data,0);
		NSData *nsdata = [[NSData alloc] initWithBytes:String_val(d) length:String_len(d)];
		[request setHTTPBody:nsdata];
		[nsdata release];
	}
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:[LightViewController sharedInstance] startImmediately:YES];
	[nsurl release];
}
