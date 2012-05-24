#include "texture_pvr.h"

// --- PVR 2 structs & enums -------------------------------------------------------------------------

#define PVRTEX_IDENTIFIER 0x21525650 // = the characters 'P', 'V', 'R'

typedef struct
{
  uint headerSize;          // size of the structure
  uint height;              // height of surface to be created
  uint width;               // width of input surface
  uint numMipmaps;          // number of mip-map levels requested
  uint pfFlags;             // pixel format flags
  uint textureDataSize;     // total size in bytes
  uint bitCount;            // number of bits per pixel
  uint rBitMask;            // mask for red bit
  uint gBitMask;            // mask for green bits
  uint bBitMask;            // mask for blue bits
  uint alphaBitMask;        // mask for alpha channel
  uint pvr;                 // magic number identifying pvr file
  uint numSurfs;            // number of surfaces present in the pvr
} PVRTextureHeader;

enum PVRPixelType
{
  OGL_RGBA_4444 = 0x10,
  OGL_RGBA_5551,
  OGL_RGBA_8888,
  OGL_RGB_565,
  OGL_RGB_555,
  OGL_RGB_888,
  OGL_I_8,
  OGL_AI_88,
  OGL_PVRTC2,
  OGL_PVRTC4
};

int loadPvrFile2(FILE *fildes, textureInfo *tInfo) {

	PRINT_DEBUG("LoadPvrFile2");

	PVRTextureHeader header;

	if (!fread(&header,sizeof(PVRTextureHeader),1,fildes)) {return 1;};
	if (header.pvr != PVRTEX_IDENTIFIER) {ERROR("bad pvr2 IDENTIFIER");return 1;};

  int hasAlpha = header.alphaBitMask ? 1 : 0;

	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	//printf("width: %d, height: %d\n",header.width,header.height);
	tInfo->numMipmaps = header.numMipmaps;
	tInfo->premultipliedAlpha = 0;
  
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
				ERROR("UNKNOWN header: %x\n",header.pfFlags & 0xff);
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


// -- PVR 3 
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
} __attribute__((packed)) PVRTextureHeader3;

int loadPvrFile3(FILE* fildes,size_t fsize, textureInfo *tInfo) {

	PRINT_DEBUG("LoadPvrFile3 of size: %d, %d, %u",fsize,ftell(fildes),sizeof(PVRTextureHeader3));
	if (fsize < sizeof(PVRTextureHeader3)) {return 1;};

	PVRTextureHeader3 header;
	if (!fread(&header,sizeof(PVRTextureHeader3),1,fildes)) {ERROR("can't read pvr header");return 1;};
	if (header.u32Version != PVRTEX3_IDENT) {
		ERROR("bad pvr3 version");
		return 1;
	};
	tInfo->width = tInfo->realWidth = header.u32Width;
	tInfo->height = tInfo->realHeight = header.u32Height;
	tInfo->numMipmaps = header.u32MIPMapCount - 1;
	tInfo->premultipliedAlpha = header.u32Flags & PVRTEX3_PREMULTIPLIED;
	PRINT_DEBUG("width: %d, height: %d, pma: %d",tInfo->width,tInfo->height,tInfo->premultipliedAlpha);
	union PVR3PixelType pt = (union PVR3PixelType)(header.u64PixelFormat);
	if (pt.Part.High == 0) {
		switch (pt.PixelTypeID)
		{
			case ePVRTPF_PVRTCI_2bpp_RGB:
				PRINT_DEBUG("PVRTCI 2bpp RGB");
				tInfo->format = LTextureFormatPvrtcRGB2;
				break;
			case ePVRTPF_PVRTCI_2bpp_RGBA:
				PRINT_DEBUG("PVRTCI 2bpp RGBA");
				tInfo->format = LTextureFormatPvrtcRGBA2;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGB:
				PRINT_DEBUG("PVRTCI 4bpp RGB");
				tInfo->format = LTextureFormatPvrtcRGB4;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGBA:
				PRINT_DEBUG("PVRTCI 4bpp RGBA");
				tInfo->format = LTextureFormatPvrtcRGBA4;
				break;
			case ePVRTPF_PVRTCII_2bpp:
				ERROR("unsupported: PVRTCII 2bpp");
				return 1;
				break;
			case ePVRTPF_PVRTCII_4bpp:
				ERROR("unsupported: PVRTCII 4bpp");
				return 1;
				break;
		}
	} else {
		ERROR("unsupported: SPEC PVR format");
		return 1;
	};
	// skip meta
	int p;
	if (header.u32MetaDataSize > 0) {
		PRINT_DEBUG("move on metaSize");
		p = fseek(fildes,header.u32MetaDataSize,SEEK_CUR);
	} else p = ftell(fildes);
	PRINT_DEBUG("metadataSize: %d, curlp: %d",header.u32MetaDataSize,p);

	tInfo->dataLen = fsize - sizeof(PVRTextureHeader3) - header.u32MetaDataSize;
	//printf("pvr data size: %d\n",tInfo->dataLen);
	tInfo->imgData = (unsigned char*)malloc(tInfo->dataLen);

	if (!fread(tInfo->imgData,tInfo->dataLen,1,fildes)) {free(tInfo->imgData);return 1;};
	tInfo->scale = 1;
	return 0;
}
