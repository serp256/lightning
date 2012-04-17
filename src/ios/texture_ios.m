
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
#import "LightImageLoader.h"


typedef void (*drawingBlock)(CGContextRef context,void *data);

void createTextureInfo(int colorSpace, float width, float height, float scale, drawingBlock draw, void *data, textureInfo *tInfo) {
	//int legalWidth  = nextPowerOfTwo(width  * scale);
	//int legalHeight = nextPowerOfTwo(height * scale);
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
	float scale = 1.0f;
	float width = image.size.width;
	float height = image.size.height;
	//CGImageRef  CGImage = uiImage.CGImage;
	//CGImageAlphaInfo info = CGImageGetAlphaInfo(CGImage);
	//int colorSpace = LTextureFormatRGBA;
	//createTextureInfo(colorSpace,width,height,scale,*drawImage,(void*)image,tInfo);
	int legalWidth  = nextPowerOfTwo(width);
	int legalHeight = nextPowerOfTwo(height);
    
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
	NSLog(@"IMAGE LOADED");
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


//Compressed pixel formats
const uint32_t PVRTEX3_IDENT = 0x03525650;  // 'P''V''R'3

// PVR Header file flags.                   Condition if true. If false, opposite is true unless specified.
const uint32_t PVRTEX3_PREMULTIPLIED    = (1<<1);   //  Texture has been premultiplied by alpha value.  

enum EPVRTPixelFormat
{
  ePVRTPF_PVRTCI_2bpp_RGB,
  ePVRTPF_PVRTCI_2bpp_RGBA,
  ePVRTPF_PVRTCI_4bpp_RGB,
  ePVRTPF_PVRTCI_4bpp_RGBA,
  ePVRTPF_PVRTCII_2bpp,
  ePVRTPF_PVRTCII_4bpp,
  ePVRTPF_ETC1,
  ePVRTPF_DXT1,
  ePVRTPF_DXT2,
  ePVRTPF_DXT3,
  ePVRTPF_DXT4,
  ePVRTPF_DXT5
};

union PVR3PixelType {struct LowHigh {uint32_t Low; uint32_t High;} Part; uint64_t PixelTypeID; uint8_t PixelTypeChar[8];};

typedef struct 
{
	uint32_t  u32Version;     //Version of the file header, used to identify it.
  uint32_t  u32Flags;     //Various format flags.
  uint64_t  u64PixelFormat;   //The pixel format, 8cc value storing the 4 channel identifiers and their respective sizes.
  uint32_t u32ColourSpace;   //The Colour Space of the texture, currently either linear RGB or sRGB.
  uint32_t u32ChannelType;   //Variable type that the channel is stored in. Supports signed/unsigned int/short/byte or float for now.
  uint32_t  u32Height;      //Height of the texture.
  uint32_t  u32Width;     //Width of the texture.
  uint32_t  u32Depth;     //Depth of the texture. (Z-slices)
  uint32_t  u32NumSurfaces;   //Number of members in a Texture Array.
  uint32_t  u32NumFaces;    //Number of faces in a Cube Map. Maybe be a value other than 6.
  uint32_t  u32MIPMapCount;   //Number of MIP Maps in the texture - NB: Includes top level.
  uint32_t  u32MetaDataSize;  //Size of the accompanying meta data.
} PVRTextureHeader3;

int loadPvrFile3(FILE* fildes,textureInfo *tInfo) {
	fseek(fildes, 0, SEEK_END); /* Seek to the end of the file */
	long fsize = ftell(fildes); /* Find out how many bytes into the file we are */
	fseek(fildes, 0, SEEK_SET); /* Go back to the beginning of the file */

	if (fsize < sizeof(PVRTextureHeader3)) {return 1;};

	PVRTextureHeader3 header;
	if (!fread(&header,sizeof(PVRTextureHeader3),1,fildes)) {fprintf(stderr,"can't read pvr header\n");return 1;};
	if (header.u32Version != PVRTEX3_IDENT) {
		fprintf(stderr,"bad pvr3 version\n");
		return 1;
	};
	tInfo->width = tInfo->realWidth = header.u32Width;
	tInfo->height = tInfo->realHeight = header.u32Height;
	tInfo->numMipmaps = header.u32MIPMapCount - 1;
	tInfo->premultipliedAlpha = header.u32Flags & PVRTEX3_PREMULTIPLIED;
	union PVR3PixelType pt = (union PVR3PixelType)(header.u64PixelFormat);
	if (pt.Part.High == 0) {
		switch (pt.PixelTypeID)
		{
			case ePVRTPF_PVRTCI_2bpp_RGB:
				//fprintf(stderr,"PVRTCI 2bpp RGB\n");
				tInfo->format = LTextureFormatPvrtcRGB2;
				break;
			case ePVRTPF_PVRTCI_2bpp_RGBA:
				//fprintf(stderr,"PVRTCI 2bpp RGBA\n");
				tInfo->format = LTextureFormatPvrtcRGBA2;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGB:
				//fprintf(stderr,"PVRTCI 4bpp RGB\n");
				tInfo->format = LTextureFormatPvrtcRGB4;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGBA:
				//fprintf(stderr,"PVRTCI 4bpp RGBA\n");
				tInfo->format = LTextureFormatPvrtcRGBA4;
				break;
			case ePVRTPF_PVRTCII_2bpp:
				//fprintf(stderr,"PVRTCII 2bpp\n");
				return 1;
				break;
			case ePVRTPF_PVRTCII_4bpp:
				fprintf(stderr,"unsupported: PVRTCII 2bpp\n");
				return 1;
				break;
		}
	} else {
		fprintf(stderr,"unsupported: SPEC PVR format\n");
		return 1;
	};
	// skip meta
	if (header.u32MetaDataSize > 0) {
		fseek(fildes,header.u32MetaDataSize,SEEK_CUR);
	};

	tInfo->dataLen = fsize - sizeof(PVRTextureHeader3) - header.u32MetaDataSize;
	printf("pvr data size: %d\n",tInfo->dataLen);
	tInfo->imgData = (unsigned char*)malloc(tInfo->dataLen);

	if (!fread(tInfo->imgData,tInfo->dataLen,1,fildes)) {free(tInfo->imgData);return 1;};
	tInfo->scale = 1;
	return 0;
}

int loadPvrFile2(FILE *fildes, textureInfo *tInfo) {

	PVRTextureHeader header;

	if (!fread(&header,sizeof(PVRTextureHeader),1,fildes)) {return 1;};
	if (header.pvr != PVRTEX_IDENTIFIER) {fprintf(stderr,"bad pvr2 IDENTIFIER\n");return 1;};

  int hasAlpha = header.alphaBitMask ? 1 : 0;

	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	//printf("width: %d, height: %d\n",header.width,header.height);
	tInfo->numMipmaps = header.numMipmaps;
	tInfo->premultipliedAlpha = NO;
  
  switch (header.pfFlags & 0xff)
  {
      case OGL_RGB_565:
        tInfo->format = LTextureFormat565;
        break;
      case OGL_RGBA_5551:
				tInfo->format = LTextureFormat5551;
				break;
      case OGL_RGBA_4444:
				tInfo->format = LTextureFormat4444;
				break;
      case OGL_RGBA_8888:
				tInfo->format = LTextureFormatRGBA;
				break;
      case OGL_PVRTC2:
				tInfo->format = hasAlpha ? LTextureFormatPvrtcRGBA2 : LTextureFormatPvrtcRGB2;
				break;
      case OGL_PVRTC4:
				tInfo->format = hasAlpha ? LTextureFormatPvrtcRGBA4 : LTextureFormatPvrtcRGB4;
				break;
      default:
				printf("UNKNOWN header: %x\n",header.pfFlags & 0xff);
				return 1;
  }

	tInfo->dataLen = header.textureDataSize;
	// make buffer
	tInfo->imgData = (unsigned char*)malloc(header.textureDataSize);
	if (!tInfo->imgData) {return 1;};
	if (!fread(tInfo->imgData,tInfo->dataLen,1,fildes)) {free(tInfo->imgData);return 1;};
	tInfo->scale = 1.0;
	return 0;
}


int loadPvrFile(NSString *path, textureInfo *tInfo) {
	FILE* fildes = fopen([path cStringUsingEncoding:NSASCIIStringEncoding],"ro");
	if (fildes < 0) return 1;
	int r = loadPvrFile3(fildes,tInfo);
	fclose(fildes);
	if (r != 0) {
		fildes = fopen([path cStringUsingEncoding:NSASCIIStringEncoding],"ro");
		r = loadPvrFile2(fildes,tInfo);
		fclose(fildes);
	}
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


int _load_image(NSString *path,char *suffix,textureInfo *tInfo) {

	NSLog(@"LOAD IMAGE: %@\n",path);
	NSString *fullPath = NULL;
	NSString *imgType = [[path pathExtension] lowercaseString];
	NSBundle *bundle = [NSBundle mainBundle];

	int r;
	int is_pvr = 0;
	int is_plx = 0;
	int is_alpha = 0;
	int is_plt = 0;

	do  {
		if ([imgType rangeOfString:@"pvr"].location == 0) is_pvr = 1;
		else if ([imgType rangeOfString:@"plx"].location == 0) is_plx = 1;
		else if ([imgType rangeOfString:@"alpha"].location == 0) is_alpha = 1;
		else if ([imgType rangeOfString:@"plt"].location == 0) {}
		else {
			do {
				NSString *fname = NULL;
				NSString *pathWithoutExt = [path stringByDeletingPathExtension];
				if (suffix != NULL) {

					NSString *pathWithSuffix = [pathWithoutExt stringByAppendingString:[NSString stringWithCString:suffix encoding:NSASCIIStringEncoding]];
					fname = [pathWithSuffix stringByAppendingPathExtension:@"pvr"];
					fullPath = pathForBundleResource(fname, bundle); 
					if (fullPath) {
						is_pvr = 1; 
						break; 
					}

					// try plx with with suffix
					fname = [pathWithSuffix stringByAppendingPathExtension:@"plx"];
					fullPath = pathForBundleResource(fname,bundle);
					if (fullPath) {
						is_plx = 1;
						break;
					};

					// try original ext with this suffix
					fname = [pathWithSuffix stringByAppendingPathExtension:imgType];
					fullPath = pathForBundleResource(fname, bundle); 

					if (fullPath) break;
				} 

				// try pvr 
				fname = [pathWithoutExt stringByAppendingPathExtension:@"pvr"];
				fullPath = pathForBundleResource(fname, bundle);
				if (fullPath) {is_pvr = 1; break;};

				// try plx
				fname = [pathWithoutExt stringByAppendingPathExtension:@"plx"];
				fullPath = pathForBundleResource(fname, bundle);
				if (fullPath) {is_plx = 1; break;};

				fullPath = pathForBundleResource(path, bundle);
			} while (0);
			break;
		}
		// if not needed try other exts
		if (suffix != NULL) {
			NSString *fname = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", [NSString stringWithCString:suffix encoding:NSASCIIStringEncoding], imgType];
			fullPath = pathForBundleResource(fname, bundle);
			if (!fullPath) fullPath = pathForBundleResource(path, bundle); 
		} else fullPath = pathForBundleResource(path, bundle); 
	} while(0);

	if (!fullPath) r = 2;
	else {
		if (is_pvr) r = loadPvrFile(fullPath,tInfo);
		else if (is_plx) r = loadPlxFile([fullPath cStringUsingEncoding:NSASCIIStringEncoding],tInfo);
		else if (is_alpha) r = loadAlphaFile([fullPath cStringUsingEncoding:NSASCIIStringEncoding],tInfo);
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
	return r;
}

int load_image_info(char *cpath,char *suffix, textureInfo *tInfo) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *path = [NSString stringWithCString:cpath encoding:NSASCIIStringEncoding];
	int r = _load_image(path,suffix,tInfo);
	[pool release];
	return r;
}

/*
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
*/


CAMLprim value ml_loadImage(value oldTexture, value opath, value osuffix) { // if old texture exists when replace
	CAMLparam2(opath,osuffix);
	CAMLlocal1(mlTex);
	NSLog(@"ml_loade image: %s\n",String_val(opath));
	NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
	checkGLErrors("start load image");

	textureInfo tInfo;
	char *suffix = Is_block(osuffix) ? String_val(Field(osuffix,0)) : NULL;
	int r = _load_image(path,suffix,&tInfo);

	//double gt1 = CACurrentMediaTime();
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};

	value textureID = createGLTexture(oldTexture,&tInfo);
	free(tInfo.imgData);

	checkGLErrors("after load texture");

	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));

	CAMLreturn(mlTex);
}


void ml_loadExternalImage(value url,value successCallback, value errorCallback) {
	LightImageLoader *imageLoader = [[LightImageLoader alloc] initWithURL:[NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding] successCallback:successCallback errorCallback:errorCallback];
	[imageLoader start];
	[imageLoader release];
}
