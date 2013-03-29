#include "texture_pvr.h"
#include <string.h>

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

/*int loadPvrFile2(FILE *fildes, textureInfo *tInfo) {

	PRINT_DEBUG("LoadPvrFile2");

	PVRTextureHeader header;

	if (!fread(&header,sizeof(PVRTextureHeader),1,fildes)) {return 1;};
	if (header.pvr != PVRTEX_IDENTIFIER) {ERROR("bad pvr2 IDENTIFIER");return 1;};

  int hasAlpha = header.alphaBitMask ? 1 : 0;

	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	//printf("width: %d, height: %d\n",header.width,header.height);
	tInfo->numMipmaps = header.numMipmaps;
	tInfo->generateMipmaps = 0;
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
*/

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

int loadPvrFile3(gzFile* gzf, textureInfo *tInfo) {
	PVRTextureHeader3 header;
	int bytes_to_read = sizeof(PVRTextureHeader3);

	if (gzread(gzf, &header, bytes_to_read) < bytes_to_read) {
		ERROR("can't read pvr header");
		return 1;
	};

	if (header.u32Version != PVRTEX3_IDENT) {
		ERROR("bad pvr3 version");
		return 1;
	};

	tInfo->width = tInfo->realWidth = header.u32Width;
	tInfo->height = tInfo->realHeight = header.u32Height;
	tInfo->numMipmaps = header.u32MIPMapCount - 1;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = header.u32Flags & PVRTEX3_PREMULTIPLIED;
	PRINT_DEBUG("width: %d, height: %d, pma: %d",tInfo->width,tInfo->height,tInfo->premultipliedAlpha);
	union PVR3PixelType pt = (union PVR3PixelType)(header.u64PixelFormat);
	int bpp = 0;
	if (pt.Part.High == 0) {
		switch (pt.PixelTypeID)
		{
			case ePVRTPF_PVRTCI_2bpp_RGB:
				PRINT_DEBUG("PVRTCI 2bpp RGB");
				tInfo->format = LTextureFormatPvrtcRGB2;
				bpp = 2;
				break;
			case ePVRTPF_PVRTCI_2bpp_RGBA:
				PRINT_DEBUG("PVRTCI 2bpp RGBA");
				tInfo->format = LTextureFormatPvrtcRGBA2;
				bpp = 2;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGB:
				PRINT_DEBUG("PVRTCI 4bpp RGB");
				tInfo->format = LTextureFormatPvrtcRGB4;
				bpp = 4;
				break;
			case ePVRTPF_PVRTCI_4bpp_RGBA:
				PRINT_DEBUG("PVRTCI 4bpp RGBA");
				tInfo->format = LTextureFormatPvrtcRGBA4;
				bpp = 4;
				break;
			case ePVRTPF_DXT1:
				PRINT_DEBUG("DXT1");
				tInfo->format = LTextureFormatDXT1;
				bpp = 4;
				break;				
			case ePVRTPF_DXT5:
				PRINT_DEBUG("DXT5");
				tInfo->format = LTextureFormatDXT5;
				bpp = 8;
				break;
			case ePVRTPF_ETC1:
				PRINT_DEBUG("ETC1");
				tInfo->format = LTextureFormatETC1;
				bpp = 4;
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
		if (!memcmp("rgba",pt.PixelTypeChar,4)) {
			uint32_t *bpc = (uint32_t*)(pt.PixelTypeChar + 4);
			switch (*bpc) {
				case 67372036:
					PRINT_DEBUG("RGBA:4444");
					tInfo->format = LTextureFormat4444;
					bpp = 16;
					break;

				default:
					ERROR("unsupported: SPEC rgba format [%hhu,%hhu,%hhu,%hhu]",pt.PixelTypeChar[4],pt.PixelTypeChar[5],pt.PixelTypeChar[6],pt.PixelTypeChar[7]);
					return 1;
			}
		} else {
			ERROR("unsupported: SPEC PVR format {%c,%c,%c,%c}",pt.PixelTypeChar[0],pt.PixelTypeChar[1],pt.PixelTypeChar[2],pt.PixelTypeChar[3]);
			return 1;
		}
	};
	// skip meta

	PRINT_DEBUG("before skiping meta...");

	if (header.u32MetaDataSize > 0) {
		PRINT_DEBUG("move on metaSize");
		gzseek(gzf, header.u32MetaDataSize, SEEK_CUR);
	}

	PRINT_DEBUG("after skiping meta");

	tInfo->dataLen = header.u32Width * header.u32Height * bpp / 8;
	tInfo->imgData = (unsigned char*)malloc(tInfo->dataLen);

	PRINT_DEBUG("malloc success");

	if (gzread(gzf, tInfo->imgData, tInfo->dataLen) < tInfo->dataLen) {
		free(tInfo->imgData);
		return 1;
	}

	PRINT_DEBUG("read success");

	tInfo->scale = 1;
	return 0;
}
typedef unsigned char uint8;
typedef signed char int8;
typedef unsigned short uint16;
typedef signed short int16;

#if !defined(MAKEFOURCC)
#define MAKEFOURCC(ch0, ch1, ch2, ch3) \
    ((uint)((int8)(ch0)) | ((uint)((int8)(ch1)) << 8) | \
    ((uint)((int8)(ch2)) << 16) | ((uint)((int8)(ch3)) << 24 ))
#endif

enum DDPF
{
    DDPF_ALPHAPIXELS = 0x00000001U,
    DDPF_ALPHA = 0x00000002U,
    DDPF_FOURCC = 0x00000004U,
    DDPF_RGB = 0x00000040U,
    DDPF_PALETTEINDEXED1 = 0x00000800U,
    DDPF_PALETTEINDEXED2 = 0x00001000U,
    DDPF_PALETTEINDEXED4 = 0x00000008U,
    DDPF_PALETTEINDEXED8 = 0x00000020U,
    DDPF_LUMINANCE = 0x00020000U,
    DDPF_ALPHAPREMULT = 0x00008000U,

    // Custom NVTT flags.
    DDPF_NORMAL = 0x80000000U,
    DDPF_SRGB = 0x40000000U,
};

enum FOURCC
{
    FOURCC_NVTT = MAKEFOURCC('N', 'V', 'T', 'T'),
    FOURCC_DDS = MAKEFOURCC('D', 'D', 'S', ' '),
    FOURCC_DXT1 = MAKEFOURCC('D', 'X', 'T', '1'),
    FOURCC_DXT2 = MAKEFOURCC('D', 'X', 'T', '2'),
    FOURCC_DXT3 = MAKEFOURCC('D', 'X', 'T', '3'),
    FOURCC_DXT4 = MAKEFOURCC('D', 'X', 'T', '4'),
    FOURCC_DXT5 = MAKEFOURCC('D', 'X', 'T', '5'),
    FOURCC_RXGB = MAKEFOURCC('R', 'X', 'G', 'B'),
    FOURCC_ATI1 = MAKEFOURCC('A', 'T', 'I', '1'),
    FOURCC_ATI2 = MAKEFOURCC('A', 'T', 'I', '2'),
    FOURCC_A2XY = MAKEFOURCC('A', '2', 'X', 'Y'),
    FOURCC_DX10 = MAKEFOURCC('D', 'X', '1', '0'),
    FOURCC_UVER = MAKEFOURCC('U', 'V', 'E', 'R'),
    FOURCC_ATC_RGB = MAKEFOURCC('A', 'T', 'C', ' '),
    FOURCC_ATC_RGBAE = MAKEFOURCC('A', 'T', 'C', 'A'),
    FOURCC_ATC_RGBAI = MAKEFOURCC('A', 'T', 'C', 'I'),
    FOURCC_RGBA_4444 = MAKEFOURCC('4', '4', '4', '4')
};

typedef struct
{
    uint size;
    uint flags;
    uint fourcc;
    uint bitcount;
    uint rmask;
    uint gmask;
    uint bmask;
    uint amask;
} DDSPixelFormat;

typedef struct
{
    uint caps1;
    uint caps2;
    uint caps3;
    uint caps4;
} DDSCaps;

typedef struct
{
    uint fourcc;
    uint size;
    uint flags;
    uint height;
    uint width;
    uint pitch;
    uint depth;
    uint mipmapcount;
    uint reserved[11];
    DDSPixelFormat pf;
    DDSCaps caps;
    uint notused;
} DDSHeader;

int loadDdsFile(gzFile* gzf, textureInfo *tInfo) {
	DDSHeader header;

	int bytes_to_read = sizeof(DDSHeader);

	if (gzread(gzf, &header, bytes_to_read) < bytes_to_read) {
		ERROR("can't read dds header");
		return 1;
	}

	if (header.fourcc != FOURCC_DDS) {
		ERROR("bad dds identifier");
		return 1;
	};

	int bpp = 0;

	if (header.pf.fourcc == FOURCC_DXT1) {
		PRINT_DEBUG("DXT1");
	 	tInfo->format = LTextureFormatDXT1;
	 	bpp = 4;
	} else if (header.pf.fourcc == FOURCC_DXT5) {
		PRINT_DEBUG("DXT5");
		tInfo->format = LTextureFormatDXT5;
		bpp = 8;
	} else if (header.pf.fourcc == FOURCC_ATC_RGB) {
		PRINT_DEBUG("ATC RGB");
		tInfo->format = LTextureFormatATCRGB;
		bpp = 4;
	} else if (header.pf.fourcc == FOURCC_ATC_RGBAE) {
		PRINT_DEBUG("ATC RGBA explicit");
		tInfo->format = LTextureFormatATCRGBAE;
		bpp = 8;
	} else if (header.pf.fourcc == FOURCC_ATC_RGBAI) {
		PRINT_DEBUG("ATC RGBA interpolated");
		tInfo->format = LTextureFormatATCRGBAI;
		bpp = 8;
	} else if (header.pf.fourcc == FOURCC_RGBA_4444) {
		PRINT_DEBUG("RGBA 4444");
		tInfo->format = LTextureFormat4444;
		bpp = 16;
	} else {
		ERROR("bad or unsupported dds pixel format");
		return 1;
	}

	PRINT_DEBUG("width %d", header.width);
	PRINT_DEBUG("height %d", header.height);
	PRINT_DEBUG("mipmaps %d", header.mipmapcount);
	PRINT_DEBUG("alpha premultiply %d", header.pf.flags & DDPF_ALPHAPREMULT);

	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	tInfo->numMipmaps = header.mipmapcount - 1;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = header.pf.flags & DDPF_ALPHAPREMULT;
	tInfo->scale = 1;
	tInfo->dataLen = header.width * header.height * bpp / 8;
	tInfo->imgData = (unsigned char*)malloc(tInfo->dataLen);

	PRINT_DEBUG("tInfo->dataLen: %d", tInfo->dataLen);

	if (gzread(gzf, tInfo->imgData, tInfo->dataLen) < tInfo->dataLen) {
		ERROR("cannot read image data");
		free(tInfo->imgData);
		return 1;
	};

	return 0;
}