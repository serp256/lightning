
#import "LightImageLoader.h"
#import <caml/memory.h>
#import <caml/threads.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import "texture_common.h"



int loadImageFile(UIImage *image, textureInfo *tInfo);

@implementation LightImageLoader 


-initWithURL:(NSString*)url successCallback:(value)scallback errorCallback:(value)ecallback {
	[super init];
	//NSLog(@"LOAD URL %@",url);
	successCallback = scallback;
	caml_register_generational_global_root(&successCallback);
	if (Is_block(ecallback)) {
		errorCallback = Field(ecallback,0);
		caml_register_generational_global_root(&errorCallback);
	} else errorCallback = 0;
	NSURL *nsurl = [[NSURL alloc] initWithString:url];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:nsurl];
	connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[nsurl release];
	[request release];
	data_ = [[NSMutableData alloc] initWithCapacity:10];
	return self;
}


-(void)start {
	[connection_ start];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	//NSLog(@"ImageLoader did fail with error");
	if (errorCallback != 0) {
		NSString *errdesc = [error localizedDescription];
		//caml_acquire_runtime_system();
		value errmessage = caml_copy_string([errdesc cStringUsingEncoding:NSUTF8StringEncoding]);
		caml_callback2(errorCallback,Val_int(error.code),errmessage);
		//caml_release_runtime_system();
	}
	[connection_ release];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	//NSLog(@"Image loader did recieve data: %d",data.length);
	[data_ appendData:data];
}

-(void)badImageData {
	if (errorCallback != 0) {
		//caml_acquire_runtime_system();
		caml_callback2(errorCallback,Int_val(0),caml_copy_string("Bad image data"));
		//caml_release_runtime_system();
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// сделать текстуру и заебись
	UIImage *image = [UIImage alloc];
	if ([image initWithData:data_]) {
		//float width = image.size.width;
		//float height = image.size.height;
		//NSLog(@"Laded external image of size: %f:%f",width,height);
		textureInfo tInfo;
		int r = loadImageFile(image,&tInfo);
		[image release];
		if (r) [self badImageData];
		else {
			//caml_acquire_runtime_system();
			value textureID = createGLTexture(1,&tInfo,Val_int(1));
			value mlTex = 0;
			Begin_roots2(textureID,mlTex);
			//NSLog(@"loaded external texture: %d",textureID);
			free(tInfo.imgData);
			checkGLErrors("after load texture");
			ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
			caml_callback(successCallback,mlTex);
			End_roots();
			//caml_release_runtime_system();
		}
	} else {
		[self badImageData];
	};
	[connection_ release];
}


-(void)dealloc {
	//NSLog(@"dealloc external image loader");
	//caml_acquire_runtime_system();
	caml_remove_generational_global_root(&successCallback);
	if (errorCallback != 0) caml_remove_generational_global_root(&errorCallback);
	//caml_release_runtime_system();
	[data_ release];
	[super dealloc];
}



@end
