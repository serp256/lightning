
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

#import "texture_common.h"
#import "common_ios.h"


typedef void (*drawingBlock)(CGContextRef context,void *data);

void createTextureInfo(int colorSpace, float width, float height, float scale, drawingBlock draw, void *data, textureInfo *tInfo) {
	//int legalWidth  = nextPowerOfTwo(width  * scale);
	//int legalHeight = nextPowerOfTwo(height * scale);
	int legalWidth  = nextPowerOfTwo(width);
	int legalHeight = nextPowerOfTwo(height);
    
    CGColorSpaceRef cgColorSpace;
    CGBitmapInfo bitmapInfo;
    int bytesPerPixel;

    
    if (colorSpace == SPTextureFormatRGBA)
    {
        bytesPerPixel = 4;
        tInfo->format = SPTextureFormatRGBA;
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        tInfo->premultipliedAlpha = YES;
		}
		else { // assume it's rgb
			bytesPerPixel = 3;
			tInfo->format = SPTextureFormatRGB;
			cgColorSpace = CGColorSpaceCreateDeviceRGB();
			bitmapInfo = kCGImageAlphaNone;// kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
        tInfo->premultipliedAlpha = NO;
		}
    /*}
    else
    {
        bytesPerPixel = 1;
        textureFormat = SPTextureFormatAlpha;
        cgColorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone;
        premultipliedAlpha = NO;
    }*/

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

int loadImageFile(UIImage *image, textureInfo *tInfo) {
	//float scale = [image respondsToSelector:@selector(scale)] ? [image scale] : 1.0f;
	float scale = 2.0f;
	float width = image.size.width;
	float height = image.size.height;
	//CGImageRef  CGImage = uiImage.CGImage;
	//CGImageAlphaInfo info = CGImageGetAlphaInfo(CGImage);
	int colorSpace = SPTextureFormatRGBA;
	createTextureInfo(colorSpace,width,height,scale,*drawImage,(void*)image,tInfo);
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
	//NSLog(@"read pvr [%@]\n",path);
	//NSData *fileData = gzCompressed ? [SPTexture decompressPvrFile:path] : [NSData dataWithContentsOfFile:path];

	// we need read it with c style functions
	//NSData *fileData = [NSData dataWithContentsOfFile:path];
	int fildes = open([path cStringUsingEncoding:NSASCIIStringEncoding],O_RDONLY);
	if (fildes < 0) return 1;
	//printf("fildes opened\n");
	/*
	struct stat s;
	int res = fstat(fildes,&s);
	if (res != 0) {close(fildes);return 0;};
	//printf("fstat readed\n");
	off_t fsize = s.st_size;
	if (fsize < sizeof(PVRTextureHeader)) {close(fildes);return 0;};
	*/

	PVRTextureHeader header;

	ssize_t readed = read(fildes,&header,sizeof(PVRTextureHeader));
	//printf("readed header: %d\n",readed);
	if ((readed != sizeof(PVRTextureHeader)) /*|| (header.pvr != PVRTEX_IDENTIFIER)*/) {close(fildes); return 1;};

  int hasAlpha = header.alphaBitMask ? 1 : 0;

	//printf("hasAlpha: %d\n",hasAlpha);
  
	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	//printf("width: %d, height: %d\n",header.width,header.height);
	tInfo->numMipmaps = header.numMipmaps;
	tInfo->premultipliedAlpha = NO;
  
	//printf("check pvr header\n");
  switch (header.pfFlags & 0xff)
  {
      case OGL_RGB_565:
        tInfo->format = SPTextureFormat565;
        break;
      case OGL_RGBA_5551:
				tInfo->format = SPTextureFormat5551;
				break;
      case OGL_RGBA_4444:
				tInfo->format = SPTextureFormat4444;
				break;
      case OGL_RGBA_8888:
				tInfo->format = SPTextureFormatRGBA;
				break;
      case OGL_PVRTC2:
				tInfo->format = hasAlpha ? SPTextureFormatPvrtcRGBA2 : SPTextureFormatPvrtcRGB2;
				break;
      case OGL_PVRTC4:
				tInfo->format = hasAlpha ? SPTextureFormatPvrtcRGBA4 : SPTextureFormatPvrtcRGB4;
				break;
      default:
				close(fildes);
				return 1;
  }

	tInfo->dataLen = header.textureDataSize;
	// make buffer
	tInfo->imgData = (unsigned char*)malloc(header.textureDataSize);
	if (!tInfo->imgData) {close(fildes);return 1;};
	readed = read(fildes,tInfo->imgData,tInfo->dataLen);
	if (readed != header.textureDataSize) {close(fildes);free(tInfo->imgData);return 1;};
	/*
  NSString *baseFilename = [[path lastPathComponent] stringByDeletingFullPathExtension];
  if ([baseFilename rangeOfString:@"@2x"].location == baseFilename.length - 3)
      glTexture.scale = 2.0f;
	*/
	tInfo->scale = 2.0;
	close(fildes);
	return 0;
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


NSString * pathForBundleResource(NSString * path, NSBundle * bundle) {
    NSArray * components = [path pathComponents];
    NSString * bundlePath = nil;
    if ([components count] > 1) {
      bundlePath = [bundle pathForResource: [components lastObject] ofType:nil inDirectory: [path stringByDeletingLastPathComponent]]; 
    } else {
      bundlePath = [bundle pathForResource:path ofType:nil];
    }	                     
    return bundlePath;
}


int _load_image(NSString *path,textureInfo *tInfo) {

	NSString *fullPath = NULL;
	NSString *imgType = [[path pathExtension] lowercaseString];
	NSBundle *bundle = [NSBundle mainBundle];
	float contentScaleFactor = 1;

	int r;
	int is2x = 0;
	if ([imgType rangeOfString:@"pvr"].location == 0) {
		if (contentScaleFactor != 1.0f) {
			NSString *suffix = [NSString stringWithFormat:@"@%@x", [NSNumber numberWithFloat:contentScaleFactor]];
			NSString *fname = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", suffix, imgType];
			fullPath = pathForBundleResource(fname, bundle);
			if (fullPath) {
				is2x = 1;
			}
		};

		if (!fullPath) fullPath = pathForBundleResource(path, bundle); 
		if (!fullPath) r = 2;
		else r = loadPvrFile(fullPath, tInfo);
	} else {
		// Try pvr first with right scale factor
		int is_pvr = 0;
		do {
			NSString *fname = NULL;
			NSString *pathWithoutExt = [path stringByDeletingPathExtension];
			if (contentScaleFactor != 1.0f) {

				// в файл уже передали @2x
				if ([path rangeOfString: @"@2x"].location != NSNotFound) {
					fullPath = pathForBundleResource(path, bundle); 
					if (fullPath) {
						is2x = 1;
						break; 
					}
				}

				NSString *suffix = [NSString stringWithFormat:@"@%@x", [NSNumber numberWithFloat:contentScaleFactor]];
				fname = [pathWithoutExt stringByAppendingFormat:@"%@.%@", suffix, @"pvr"];
				fullPath = pathForBundleResource(fname, bundle); 
				if (fullPath) {
					is2x = 1;
					is_pvr = 1; 
					break; 
				}

				// try original ext with this scale factor
				fname = [pathWithoutExt stringByAppendingFormat:@"%@.%@", suffix, imgType];
				fullPath = pathForBundleResource(fname, bundle); 

				if (fullPath) {
					is2x = 1;
					break;
				}
			} 

			// try pvr 
			fname = [pathWithoutExt stringByAppendingPathExtension:@"pvr"];
			fullPath = pathForBundleResource(fname, bundle);
			if (fullPath) {is_pvr = 1; break;};
			fullPath = pathForBundleResource(path, bundle);
		} while (0);

		if (!fullPath) r = 2;
		else {
			if (is_pvr) r = loadPvrFile(fullPath,tInfo);
			else {
				//double t1 = CACurrentMediaTime();
				UIImage *image = [[UIImage alloc] initWithContentsOfFile:fullPath];
				//double t2 = CACurrentMediaTime();
				//NSLog(@"load from disk: %F",(t2 - t1));
				//t1 = CACurrentMediaTime();
				r = loadImageFile(image, tInfo);
				//t2 = CACurrentMediaTime();
				//NSLog(@"decode img: [%f]",(t2 - t1));
				[image release];
			}
		}
	}
	return r;
}

value ml_load_image_info(value opath) {
	// NEED NSPool here
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
	caml_release_runtime_system();
	PRINT_DEBUG("runtime released from load image thread");
	textureInfo *tInfo = malloc(sizeof(textureInfo));
	int r = _load_image(path,tInfo);
	[pool release];
	caml_acquire_runtime_system();
	PRINT_DEBUG("runtime acquired from load image thread");
	if (r) {
		free(tInfo);
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};
	return ((value)tInfo);
}

void ml_free_image_info(value tInfo) {
	free(((textureInfo*)tInfo)->imgData);
	free((textureInfo*)tInfo);
}

CAMLprim value ml_loadImage(value oldTexture, value opath, value ocontentScaleFactor) { // if old texture exists when replace
	CAMLparam2(opath,ocontentScaleFactor);
	CAMLlocal1(mlTex);
	NSLog(@"ml_loade image: %s\n",String_val(opath));
	NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
	checkGLErrors("start load image");

	textureInfo tInfo;
	int r = _load_image(path,&tInfo);

	//double gt1 = CACurrentMediaTime();
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};

	uint textureID;
	textureID = createGLTexture(OPTION_INT(oldTexture),&tInfo);
	NSLog(@"loaded texture: %d",textureID);
	free(tInfo.imgData);

	checkGLErrors("after load texture");

	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));

	CAMLreturn(mlTex);
}


CAMLprim value ml_textureWithText(value text) {
	caml_failwith("not implemented");
}

