
// iOS specific bindings
#import <fcntl.h>
#import <sys/stat.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import <caml/bigarray.h>
#import <caml/alloc.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/fail.h>
#import <caml/callback.h>
#import <caml/threads.h>

#import "common_ios.h"
#import "texture_common.h"
#import "texture_pvr.h"
#import "LightImageLoader.h"

typedef void (*drawingBlock)(CGContextRef context,void *data);

/*
void createTextureInfo(int colorSpace, float width, float height, float scale, drawingBlock draw, void *data, textureInfo *tInfo) {
	int legalWidth  = nextPowerOfTwo(width);
	int legalHeight = nextPowerOfTwo(height);
    
    CGColorSpaceRef cgColorSpace;
    CGBitmapInfo bitmapInfo;
    int bytesPerPixel;

    
    if (colorSpace == LTextureFormatRGBA)
    {
        bytesPerPixel = 4;
        tInfo->format = LTextureFormatRGBA;
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        tInfo->premultipliedAlpha = YES;
		}
		else { // assume it's rgb
			bytesPerPixel = 3;
			tInfo->format = LTextureFormatRGB;
			cgColorSpace = CGColorSpaceCreateDeviceRGB();
			bitmapInfo = kCGImageAlphaNone;// kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
        tInfo->premultipliedAlpha = NO;
		}
    }
    else
    {
        bytesPerPixel = 1;
        textureFormat = SPTextureFormatAlpha;
        cgColorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone;
        premultipliedAlpha = NO;
    }

		size_t dataLen = legalWidth * legalHeight * bytesPerPixel;
    void *imageData = malloc(dataLen);
    CGContextRef context = CGBitmapContextCreate(imageData, legalWidth, legalHeight, 8, bytesPerPixel * legalWidth, cgColorSpace, bitmapInfo);
    CGColorSpaceRelease(cgColorSpace);
    
    // UIKit referential is upside down - we flip it and apply the scale factor
    CGContextTranslateCTM(context, 0.0f, legalHeight);
		//CGContextScaleCTM(context, scale, -scale);
		CGContextScaleCTM(context, 1.0, -1.0);
    
		UIGraphicsPushContext(context);
	draw(context,data);
	UIGraphicsPopContext();        
    
	CGContextRelease(context);
	tInfo->width = legalWidth;
	tInfo->realWidth = width;
	tInfo->height = legalHeight;
	tInfo->realHeight = height;
	tInfo->generateMipmaps = 0;
	tInfo->numMipmaps = 0;
	tInfo->scale = scale;
	tInfo->dataLen = dataLen;
	tInfo->imgData = imageData;
}

void drawImage(CGContextRef context, void* data) {
	UIImage *image = (UIImage*)data;
	//CGImageRef imageRef = (CGImageRef)data;
	//size_t width = CGImageGetWidth(imageRef); 
	//size_t height = CGImageGetHeight(imageRef); 
	//CGRect rect = CGRectMake(0, 0, width, height);  
	//CGContextDrawImage(context, rect, imageRef); 
  [image drawAtPoint:CGPointMake(0, 0)];
}
*/

int loadImageFile(UIImage *image, textureInfo *tInfo) {
	//float scale = [image respondsToSelector:@selector(scale)] ? [image scale] : 1.0f;
	float scale = 1.0f;
	float width = image.size.width;
	float height = image.size.height;
	//CGImageRef  CGImage = uiImage.CGImage;
	//CGImageAlphaInfo info = CGImageGetAlphaInfo(CGImage);
	//int colorSpace = LTextureFormatRGBA;
	//createTextureInfo(colorSpace,width,height,scale,*drawImage,(void*)image,tInfo);
	//int legalWidth  = nextPOT((unsigned long)width);
	//int legalHeight = nextPOT((unsigned long)height);
	//int legalWidth  = nextPOT(ceil(width));
	//int legalHeight = nextPOT(ceil(height));
	int legalWidth = width < 64 ? 64 : width;
	int legalHeight = height < 64 ? 64 : height;
	//fprintf(stderr,"%f -> %d, %f -> %d\n",width,legalWidth,height,legalHeight);
	//int legalWidth  = width;
	//int legalHeight = height;
    
	CGColorSpaceRef cgColorSpace;
	CGBitmapInfo bitmapInfo;
	int bytesPerPixel;

	bytesPerPixel = 4;
	tInfo->format = LTextureFormatRGBA;
	cgColorSpace = CGColorSpaceCreateDeviceRGB();
	bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
	tInfo->premultipliedAlpha = YES;

	size_t dataLen = legalWidth * legalHeight * bytesPerPixel;
	void *imageData = malloc(dataLen);
	CGContextRef context = CGBitmapContextCreate(imageData, legalWidth, legalHeight, 8, bytesPerPixel * legalWidth, cgColorSpace, bitmapInfo);
	CGColorSpaceRelease(cgColorSpace);
    
	// UIKit referential is upside down - we flip it and apply the scale factor
	CGContextTranslateCTM(context, 0.0f, legalHeight);
	CGContextScaleCTM(context, 1.0, -1.0);
    
	UIGraphicsPushContext(context);
  [image drawAtPoint:CGPointMake(0, 0)];
	UIGraphicsPopContext();        
    
	CGContextRelease(context);
	tInfo->width = legalWidth;
	tInfo->realWidth = width;
	tInfo->height = legalHeight;
	tInfo->realHeight = height;
	tInfo->generateMipmaps = 0;
	tInfo->numMipmaps = 0;
	tInfo->scale = scale;
	tInfo->dataLen = dataLen;
	tInfo->imgData = imageData;
	return 0;
}


/*
int loadImageFile(UIImage *image,textureInfo *tInfo) {
	 CGImageRef CGImage = image.CGImage;
	 size_t bpp = CGImageGetBitsPerPixel(CGImage);
	 tInfo->realWidth = CGImageGetWidth(CGImage);
	 tInfo->realHeight = CGImageGetHeight(CGImage);
	 switch (bpp) {
		 case 32: 
		 {
			 tInfo->format = SPTextureFormatRGBA;
			 CGBitmapInfo info = CGImageGetBitmapInfo(CGImage);
			 switch(info & kCGBitmapAlphaInfoMask) {
				 case kCGImageAlphaPremultipliedFirst:
				 case kCGImageAlphaFirst:
				 case kCGImageAlphaNoneSkipFirst:
					 fprintf(stderr,"unsupported alpha format\n",bpp); 
					 return 1;
			 };
			 tInfo->premultipliedAlpha = YES;
			 break;
		 }
		 case 24:
		 {
			 tInfo->format = SPTextureFormatRGB;
			 tInfo->premultipliedAlpha = NO;
			 break;
		 }
		 default: fprintf(stderr,"unsupported bpp [%d]\n",bpp); return 1; // not supported yet
	 }
	 double t1 = CACurrentMediaTime();
	 CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(CGImage));
	 GLubyte *pixels = (GLubyte *)CFDataGetBytePtr(data);
	 double t2 = CACurrentMediaTime();
	 fprintf(stderr,"get image data: %f\n",(t2 - t1));

	 tInfo->width = nextPowerOfTwo(tInfo->realWidth);
	 tInfo->height = nextPowerOfTwo(tInfo->realHeight);

	 int components = bpp >> 3;
	 int rowBytes = components * tInfo->width;
	 tInfo->dataLen = rowBytes * tInfo->height;

	 if (tInfo->width != tInfo->realWidth || tInfo->height != tInfo->realHeight)
	 {
		 t1 = CACurrentMediaTime();
		 int srcRowBytes = tInfo->realWidth * components;
		 GLuint rowBytes   = CGImageGetBytesPerRow(CGImage); 
		 GLubyte *temp = (GLubyte *)malloc(tInfo->dataLen);
		 for (int y = 0; y < tInfo->realHeight; y++)
			 memcpy(&temp[y*rowBytes], &pixels[y*srcRowBytes], srcRowBytes);

		 t2 = CACurrentMediaTime();
		 fprintf(stderr,"copy to POT: %f\n",(t2 - t1));

		 //img->s *= (float)img->wide/POTWide;
		 //img->t *= (float)img->high/POTHigh;
		 //img->wide = POTWide;
		 //img->high = POTHigh;
		 pixels = temp;
		 //rowBytes = dstBytes;
	 } else { // copy for now
		 GLubyte *temp = (GLubyte*)malloc(tInfo->dataLen);
		 memcpy(temp,pixels,tInfo->dataLen);
	 }
	 tInfo->numMipmaps = 0;
	 tInfo->generateMipmaps = 0;
	 tInfo->scale = 1.0;
	 tInfo->dataLen = rowBytes * tInfo->height;
	 tInfo->imgData = pixels;
	 CFRelease(data);
	 return 0;
}*/

int loadPvrFile(NSString *path, textureInfo *tInfo) {
	PRINT_DEBUG("LOAD PVR: %s",[path cStringUsingEncoding:NSASCIIStringEncoding]);
	gzFile* gzf = gzopen([path cStringUsingEncoding:NSASCIIStringEncoding], "rb");

	if (!gzf) return 1;
	int r = loadPvrFile3(gzf, tInfo);
	gzclose(gzf);

	return r;
}

int loadPvrPtr(gzFile* gzf, textureInfo *tInfo) {
	PRINT_DEBUG("loadPvrPtr call %d", (int)!gzf);

	if (!gzf) return 1;

	PRINT_DEBUG("before reading pvr");
	int r = loadPvrFile3(gzf, tInfo);
	PRINT_DEBUG("after reading pvr");
	gzclose(gzf);
	PRINT_DEBUG("closed");

	return r;
}

/*
CAMLprim value ml_resourcePath(value opath, value ocontentScaleFactor) {
    CAMLparam2(opath,ocontentScaleFactor);
    CAMLlocal1(res);
    NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
    NSString *fullPath = pathForResource(path,Double_val(ocontentScaleFactor));
    res = caml_copy_string([fullPath cStringUsingEncoding:NSASCIIStringEncoding]);
    CAMLreturn(res);
}*/

/*
NSString *pathForImage(NSString *path, float contentScaleFactor) {
    if ([path isAbsolutePath]) {
        fullPath = path; 
    } else {
        if (contentScaleFactor != 1.0f)
        {
            NSString *suffix = [NSString stringWithFormat:@"@%@x", [NSNumber numberWithFloat:contentScaleFactor]];
            NSString *fname = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", suffix, [path pathExtension]];
            fullPath = [bundle pathForResource:fname ofType:nil];
        }
        if (!fullPath) fullPath = [bundle pathForResource:path ofType:nil];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
			const char *fname = [path cStringUsingEncoding:NSASCIIStringEncoding];
			caml_raise_with_string(*caml_named_value("File_not_exists"), fname);
    }
    return fullPath;
}*/


NSString *pathForBundleResource(NSString * path, NSBundle * bundle) {
    NSArray * components = [path pathComponents];
    NSString * bundlePath = nil;
    if ([components count] > 1) {
      bundlePath = [bundle pathForResource: [components lastObject] ofType:nil inDirectory: [path stringByDeletingLastPathComponent]]; 
    } else {
      bundlePath = [bundle pathForResource:path ofType:nil];
    }	                     
    return bundlePath;
}

#ifdef TEXTURE_LOAD
#define CHECK_PATH(fpath, flag) \
	if (getResourceFd([fpath cStringUsingEncoding:NSUTF8StringEncoding], &res)) {	\
		strncpy(tInfo->path,[fpath cStringUsingEncoding:NSUTF8StringEncoding],255);\
		flag = 1;																									\
		break;																										\
	}																												
#else
#define CHECK_PATH(path, flag) \
	if (getResourceFd([path cStringUsingEncoding:NSUTF8StringEncoding], &res)) {	\
		flag = 1;																									\
		break;																										\
	}
#endif

int _load_image(NSString *path,char *suffix,int use_pvr,textureInfo *tInfo) {
	NSString *imgType = [[path pathExtension] lowercaseString];

	int is_pvr = 0;
	int is_plx = 0;
	int is_alpha = 0;
	int with_lum = 0;
	int not_compressed = 0;

	resource res;

	NSLog(@"_load_image call %@", path);

	if ([path isAbsolutePath]) {
		if ([imgType rangeOfString:@"pvr"].location == 0) return loadPvrFile(path,tInfo);
		else if ([imgType rangeOfString:@"plx"].location == 0) return loadPlxFile([path cStringUsingEncoding:NSASCIIStringEncoding],tInfo);
		else if ([imgType rangeOfString:@"alpha"].location == 0) return loadAlphaFile([path cStringUsingEncoding:NSASCIIStringEncoding],tInfo, 0);
		else if ([imgType rangeOfString:@"lumal"].location == 0) return loadAlphaFile([path cStringUsingEncoding:NSASCIIStringEncoding],tInfo, 1);

		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			UIImage *img = [[UIImage alloc] initWithContentsOfFile:path];
			int retval = loadImageFile(img, tInfo);
			[img release];

			return retval;
		}

		return 2;
	} else {
		PRINT_DEBUG("path not absolute");

		do {
			if ([imgType rangeOfString:@"pvr"].location == 0) {
				PRINT_DEBUG("explicit pvr");
				is_pvr = 1;
			} else if ([imgType rangeOfString:@"plx"].location == 0) {
				PRINT_DEBUG("explicit plx");
				is_plx = 1;
			} else if ([imgType rangeOfString:@"alpha"].location == 0) {
				PRINT_DEBUG("explicit alpha");
				is_alpha = 1;
			} else if ([imgType rangeOfString:@"lumal"].location == 0) {
				PRINT_DEBUG("explicit luminance alpha");
				is_alpha = 1;
				with_lum = 1;
			} else if ([imgType rangeOfString:@"plt"].location == 0) {
				PRINT_DEBUG("explicit plt");
			} else {
				do {
					NSString *pathWithoutExt = [path stringByDeletingPathExtension];

					if (suffix != NULL) {
						NSString *pathWithSuffix = [pathWithoutExt stringByAppendingString:[NSString stringWithCString:suffix encoding:NSASCIIStringEncoding]];
						if (use_pvr) {
							CHECK_PATH([pathWithSuffix stringByAppendingPathExtension:@"pvr"], is_pvr);
						};

						CHECK_PATH([pathWithSuffix stringByAppendingPathExtension:@"plx"], is_plx);
						CHECK_PATH([pathWithSuffix stringByAppendingPathExtension:imgType], not_compressed);
					} 

					if (use_pvr) {
						CHECK_PATH([pathWithoutExt stringByAppendingPathExtension:@"pvr"], is_pvr);
					}

					CHECK_PATH([pathWithoutExt stringByAppendingPathExtension:@"plx"], is_plx);
					CHECK_PATH(path, not_compressed);
				} while (0);

				break;
			};

			if (suffix != NULL) {
				NSString *fname = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", [NSString stringWithCString:suffix encoding:NSASCIIStringEncoding], imgType];

				CHECK_PATH(fname, not_compressed);
				CHECK_PATH(path, not_compressed);
			} else {
				CHECK_PATH(path, not_compressed);
			}
		} while(0);
	};

	PRINT_DEBUG("%d %d %d %d", is_pvr, is_plx, is_alpha, not_compressed);

	if (!(is_pvr || is_plx || is_alpha || not_compressed)) return 2;
	if (is_pvr) return loadPvrPtr(gzdopen(res.fd, "rb"), tInfo);
	if (is_plx) return loadPlxPtr(gzdopen(res.fd, "rb"), tInfo);
	if (is_alpha) return loadAlphaPtr(gzdopen(res.fd, "rb"), tInfo, with_lum);

	void* buf = malloc(res.length);
	if (read(res.fd, buf, res.length) != res.length) return 1;

	NSData* imgData = [[NSData alloc] initWithBytesNoCopy:buf length:res.length];
	UIImage* img = [[UIImage alloc] initWithData:imgData];
	int retval = loadImageFile(img, tInfo);

	[img release];
	[imgData release];

	return retval;
}

int load_image_info(char *cpath,char *suffix, int use_pvr,textureInfo *tInfo) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *path = [NSString stringWithCString:cpath encoding:NSASCIIStringEncoding];
	int r = _load_image(path,suffix,use_pvr,tInfo);
	[pool release];

	return r;
}


CAMLprim value ml_loadImage(value oldTexture, value opath, value osuffix, value filter, value use_pvr) { // if old texture exists when replace
	CAMLparam2(opath,osuffix);
	CAMLlocal1(mlTex);
	//NSLog(@"ml_loade image: %s\n",String_val(opath));
	NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSUTF8StringEncoding];
	checkGLErrors("start load image");

	textureInfo tInfo;
	char *suffix = Is_block(osuffix) ? String_val(Field(osuffix,0)) : NULL;
	int r = _load_image(path,suffix,Bool_val(use_pvr),&tInfo);

	//double gt1 = CACurrentMediaTime();
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_raise_with_arg(*caml_named_value("Cant_load_texture"),opath);
	};

	value textureID = createGLTexture(oldTexture,&tInfo,filter);
	free(tInfo.imgData);

	checkGLErrors("after load texture");

	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));

	CAMLreturn(mlTex);
}


value ml_loadExternalImage(value url,value successCallback, value errorCallback) {
	NSLog(@"external loader: %s",String_val(url));
	LightImageLoader *imageLoader = [[LightImageLoader alloc] initWithURL:[NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding] successCallback:successCallback errorCallback:errorCallback];
	[imageLoader start];
	[imageLoader release];
	return Val_unit;
}
