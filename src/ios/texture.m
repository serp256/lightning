
// iOS specific bindings
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

int nextPowerOfTwo(int number) {
    int result = 1;
    while (result < number) result *= 2;
    return result;
}

typedef enum 
{
    SPTextureFormatRGBA,
    SPTextureFormatAlpha,
    SPTextureFormatPvrtcRGB2,
    SPTextureFormatPvrtcRGBA2,
    SPTextureFormatPvrtcRGB4,
    SPTextureFormatPvrtcRGBA4,
    SPTextureFormat565,
    SPTextureFormat5551,
    SPTextureFormat4444
} SPTextureFormat;

/*


uint createGLTexture(SPTextureFormat format, int width, int height, int numMipmaps, BOOL generateMipmaps, BOOL premultipliedAlpha, const void *imgData, float scale) { //{{{
    BOOL mRepeat = NO;    
    
    GLenum glTexType = GL_UNSIGNED_BYTE;
    GLenum glTexFormat;
    int bitsPerPixel;
    BOOL compressed = NO;
    uint mTextureID;
    
    switch (format)
    {
        default:
        case SPTextureFormatRGBA:
            bitsPerPixel = 8;
            glTexFormat = GL_RGBA;
            break;
        case SPTextureFormatAlpha:
            bitsPerPixel = 8;
            glTexFormat = GL_ALPHA;
            break;
        case SPTextureFormatPvrtcRGBA2:
            compressed = YES;
            bitsPerPixel = 2;
            glTexFormat = GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            break;
        case SPTextureFormatPvrtcRGB2:
            compressed = YES;
            bitsPerPixel = 2;
            glTexFormat = GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            break;
        case SPTextureFormatPvrtcRGBA4:
            compressed = YES;
            bitsPerPixel = 4;
            glTexFormat = GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            break;
        case SPTextureFormatPvrtcRGB4:
            compressed = YES;
            bitsPerPixel = 4;
            glTexFormat = GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            break;
        case SPTextureFormat565:
            bitsPerPixel = 16;
            glTexFormat = GL_RGB;
            glTexType = GL_UNSIGNED_SHORT_5_6_5;
            break;
        case SPTextureFormat5551:
            bitsPerPixel = 16;                    
            glTexFormat = GL_RGBA;
            glTexType = GL_UNSIGNED_SHORT_5_5_5_1;                    
            break;
        case SPTextureFormat4444:
            bitsPerPixel = 16;
            glTexFormat = GL_RGBA;
            glTexType = GL_UNSIGNED_SHORT_4_4_4_4;                    
            break;
    }
    
    glGenTextures(1, &mTextureID);
    glBindTexture(GL_TEXTURE_2D, mTextureID);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    
    if (!compressed)
    {       
        if (numMipmaps > 0 || generateMipmaps)
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        else
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        if (numMipmaps == 0 && generateMipmaps)
            glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);  
        
        int levelWidth = width;
        int levelHeight = height;
        unsigned char *levelData = (unsigned char *)imgData;
        
        for (int level=0; level<=numMipmaps; ++level)
        {                    
            int size = levelWidth * levelHeight * bitsPerPixel / 8;
            glTexImage2D(GL_TEXTURE_2D, level, glTexFormat, levelWidth, levelHeight, 
                         0, glTexFormat, glTexType, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }            
    }
    else
    {
        // 'generateMipmaps' not supported for compressed textures
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, numMipmaps == 0 ? GL_LINEAR : GL_LINEAR_MIPMAP_NEAREST);
        
        int levelWidth = width;
        int levelHeight = height;
        unsigned char *levelData = (unsigned char *)imgData;
        
        for (int level=0; level<= numMipmaps; ++level)
        {                    
            int size = MAX(32, levelWidth * levelHeight * bitsPerPixel / 8);
            glCompressedTexImage2D(GL_TEXTURE_2D, level, glTexFormat, levelWidth, levelHeight, 0, size, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    return mTextureID;
} //}}}

typedef struct {
    float width;
    float height;
    BOOL premultipliedAlpha;
    float scale;
    uint textureID;
} textureInfo;


value toMLResult(textureInfo *texInfo) {
    CAMLparam0();
    CAMLlocal1(res);
    res = caml_alloc_tuple(5);
    Store_field(res,0,caml_copy_double(texInfo->width));
    Store_field(res,1,caml_copy_double(texInfo->height));
    Store_field(res,2,Val_int(texInfo->premultipliedAlpha));
    Store_field(res,3,caml_copy_double(texInfo->scale));
    Store_field(res,4,Val_long(texInfo->textureID));
    CAMLreturn(res);
}
*/



typedef void (*drawingBlock)(CGContextRef context,void *data);

value createTextureInfo(float width, float height, float scale, drawingBlock draw, void *data) {
		CAMLparam0();
		CAMLlocal2(oImgData,res);
		int legalWidth  = nextPowerOfTwo(width  * scale);
		int legalHeight = nextPowerOfTwo(height * scale);
    
    SPTextureFormat textureFormat;
    CGColorSpaceRef cgColorSpace;
    CGBitmapInfo bitmapInfo;
    BOOL premultipliedAlpha;
    int bytesPerPixel;

    /*if (colorSpace == SPColorSpaceRGBA)
    {*/
        bytesPerPixel = 4;
        textureFormat = SPTextureFormatRGBA;
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        premultipliedAlpha = YES;
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
    void *imageData = caml_stat_alloc(dataLen);
    CGContextRef context = CGBitmapContextCreate(imageData, legalWidth, legalHeight, 8, 
                                                 bytesPerPixel * legalWidth, cgColorSpace, 
                                                 bitmapInfo);
    CGColorSpaceRelease(cgColorSpace);
    
    // UIKit referential is upside down - we flip it and apply the scale factor
    CGContextTranslateCTM(context, 0.0f, legalHeight);
		CGContextScaleCTM(context, scale, -scale);
    
    UIGraphicsPushContext(context);
		draw(context,data);
    UIGraphicsPopContext();        
    
    //uint textureID = createGLTexture(textureFormat,legalWidth,legalHeight,0,YES,premultipliedAlpha,imageData,scale);
    CGContextRelease(context);
    //caml_stat_free(imageData);    

		intnat dims[1];
		dims[0] = dataLen;
    
		oImgData = caml_ba_alloc(CAML_BA_MANAGED | CAML_BA_UINT8, 1, imageData, dims); 

		/*
    textureInfo texInfo = {
        .width = width,
        .height = height,
        .premultipliedAlpha = premultipliedAlpha,
        .scale = scale,
        .textureID = textureID
    };*/

		res = caml_alloc_tuple(8);
		Store_field(res,0,Val_int(textureFormat));
		Store_field(res,1,Val_int((unsigned int)width));
    Store_field(res,2,Val_int(legalWidth));
		Store_field(res,3,Val_int((unsigned int)height));
    Store_field(res,4,Val_int(legalHeight));
    Store_field(res,5,Val_int(0));
    Store_field(res,6,Val_int(1));
    Store_field(res,7,Val_int(premultipliedAlpha));
    Store_field(res,8,caml_copy_double(scale));
    Store_field(res,9,oImgData);


    /*
    SPRectangle *region = [SPRectangle rectangleWithX:0 y:0 width:width height:height];
    SPTexture *subTexture = [[SPTexture alloc] initWithRegion:region ofTexture:glTexture];
    [glTexture release];
    return subTexture;*/

    //return toMLResult(&texInfo);
		CAMLreturn(res);
}

void drawImage(CGContextRef context, void* data) {
	UIImage *image = (UIImage*)data;
	[image drawAtPoint:CGPointMake(0, 0)];
}

value loadImageFile(UIImage *image) {
    float scale = [image respondsToSelector:@selector(scale)] ? [image scale] : 1.0f;
    float width = image.size.width;
    float height = image.size.height;
		return createTextureInfo(width,height,scale,*drawImage,(void*)image);
}

value loadPvrFile(NSString *path) {
    return 0;
}

CAMLprim value ml_path_for_resource(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal(res);
	NSString *path = [[NSString stringWithCString:String_val(mlpath) encoding:NSASCIIStringEncoding];
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
	if (bundlePath == nil) {
		res = caml_alloc(1);
		Store_field(res,0,caml_copy_string([bundlePath cStringUsingEncoding:NSASCIIStringEncoding]));
	} else {
		res = Val_int(0);
	}
	CAMLreturn(res);
}

NSString *pathForResource(NSString *path, float contentScaleFactor) {
	printf("get path for resource: %s\n",[path cStringUsingEncoding:NSASCIIStringEncoding]);
    NSString *fullPath = NULL;
    if ([path isAbsolutePath]) {
        fullPath = path; 
    } else {
        NSBundle *bundle = [NSBundle mainBundle];
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
}

CAMLprim value ml_resourcePath(value opath, value ocontentScaleFactor) {
    CAMLparam2(opath,ocontentScaleFactor);
    CAMLlocal1(res);
    NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
    NSString *fullPath = pathForResource(path,Double_val(ocontentScaleFactor));
    res = caml_copy_string([fullPath cStringUsingEncoding:NSASCIIStringEncoding]);
    CAMLreturn(res);
}

CAMLprim value ml_loadImage (value opath, value ocontentScaleFactor) {
    CAMLparam2(opath,ocontentScaleFactor);
    CAMLlocal1(res);
   
    NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
    NSString *fullPath = pathForResource(path,Double_val(ocontentScaleFactor));
    NSString *imgType = [[path pathExtension] lowercaseString];
    
    if ([imgType rangeOfString:@"pvr"].location == 0)
        res = loadPvrFile(fullPath);
    else
        res = loadImageFile([UIImage imageWithContentsOfFile:fullPath]);
    CAMLreturn(res);
}

CAMLprim value ml_textureWithText(value text) {
	caml_failwith("not implemented");
}

