
#import "texture_save.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <caml/memory.h>


int save_png_image(value name, char* buffer, unsigned int width, unsigned int height) {
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, width*height*4, NULL);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	//CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGBitmapAlphaInfoMask;
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4*width,colorSpaceRef, bitmapInfo, provider,NULL,NO,renderingIntent);
	UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
	NSData *data = UIImagePNGRepresentation(image);
	NSString *path = [NSString stringWithCString:String_val(name) encoding:NSUTF8StringEncoding];
	NSLog(@"save data to file: %@",path);
	BOOL res = [data writeToFile:path atomically:NO];
	[image release];
	CGImageRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
	//[data release];
	caml_stat_free(buffer);
	return res;
}
