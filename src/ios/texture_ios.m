
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
#import <caml/threads.h>


#import "common_ios.h"
#import "texture.h"


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
*/

typedef struct {
	int format;
	float width;
	float realWidth;
	float height;
	float realHeight;
	BOOL premultipliedAlpha;
	float scale;
	unsigned int dataLen;
	unsigned char* imgData;
} textureInfo;



typedef void (*drawingBlock)(CGContextRef context,void *data);

void createTextureInfo(float width, float height, float scale, drawingBlock draw, void *data,textureInfo *tInfo) {
		int legalWidth  = nextPowerOfTwo(width  * scale);
		int legalHeight = nextPowerOfTwo(height * scale);
    
    CGColorSpaceRef cgColorSpace;
    CGBitmapInfo bitmapInfo;
    int bytesPerPixel;

    /*if (colorSpace == SPColorSpaceRGBA)
    {*/
        bytesPerPixel = 4;
        tInfo->format = SPTextureFormatRGBA;
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        tInfo->premultipliedAlpha = YES;
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
    CGContextRef context = CGBitmapContextCreate(imageData, legalWidth, legalHeight, 8, bytesPerPixel * legalWidth, cgColorSpace, bitmapInfo);
    CGColorSpaceRelease(cgColorSpace);
    
    // UIKit referential is upside down - we flip it and apply the scale factor
    CGContextTranslateCTM(context, 0.0f, legalHeight);
		CGContextScaleCTM(context, scale, -scale);
    
    UIGraphicsPushContext(context);
		draw(context,data);
    UIGraphicsPopContext();        
    
    //uint textureID = createGLTexture(textureFormat,legalWidth,legalHeight,0,YES,premultipliedAlpha,imageData,scale);
    CGContextRelease(context);
		tInfo->width = legalWidth;
		tInfo->realWidth = width;
		tInfo->height = legalHeight;
		tInfo->realHeight = height;
		tInfo->scale = scale;
		tInfo->dataLen = dataLen;
		tInfo->imgData = imageData;
}

void drawImage(CGContextRef context, void* data) {
	UIImage *image = (UIImage*)data;
	[image drawAtPoint:CGPointMake(0, 0)];
}

void loadImageFile(UIImage *image, textureInfo *tInfo) {
	float scale = [image respondsToSelector:@selector(scale)] ? [image scale] : 1.0f;
	float width = image.size.width;
	float height = image.size.height;
	createTextureInfo(width,height,scale,*drawImage,(void*)image,tInfo);
}

void loadPvrFile(NSString *path,textureInfo *tIfno) {
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

CAMLprim value ml_loadImage (value opath, value ocontentScaleFactor) {
    CAMLparam2(opath,ocontentScaleFactor);
		CAMLlocal2(oImgData,res);
   
    NSString *path = [NSString stringWithCString:String_val(opath) encoding:NSASCIIStringEncoding];
    NSString *fullPath = pathForResource(path,Double_val(ocontentScaleFactor));

		caml_release_runtime_system();

		textureInfo tInfo;

    NSString *imgType = [[path pathExtension] lowercaseString];
    
    if ([imgType rangeOfString:@"pvr"].location == 0)
        loadPvrFile(fullPath, &tInfo);
    else
        loadImageFile([UIImage imageWithContentsOfFile:fullPath], &tInfo);

		caml_acquire_runtime_system();

		intnat dims[1];
		dims[0] = tInfo.dataLen;
    
		oImgData = caml_ba_alloc(CAML_BA_MANAGED | CAML_BA_UINT8, 1, tInfo.imgData, dims); 

		res = caml_alloc_tuple(10);
		Store_field(res,0,Val_int(tInfo.format));
		Store_field(res,1,Val_int((unsigned int)tInfo.realWidth));
    Store_field(res,2,Val_int(tInfo.width));
		Store_field(res,3,Val_int((unsigned int)tInfo.realHeight));
    Store_field(res,4,Val_int(tInfo.height));
    Store_field(res,5,Val_int(0));
    Store_field(res,6,Val_int(1));
    Store_field(res,7,Val_int(tInfo.premultipliedAlpha));
    Store_field(res,8,caml_copy_double(tInfo.scale));
    Store_field(res,9,oImgData);

		CAMLreturn(res);
}

CAMLprim value ml_textureWithText(value text) {
	caml_failwith("not implemented");
}

