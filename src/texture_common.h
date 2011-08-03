

int nextPowerOfTwo(int number);

typedef enum 
{
    SPTextureFormatRGBA,
    SPTextureFormatRGB,
    SPTextureFormatAlpha,
    SPTextureFormatPvrtcRGB2,
    SPTextureFormatPvrtcRGBA2,
    SPTextureFormatPvrtcRGB4,
    SPTextureFormatPvrtcRGBA4,
    SPTextureFormat565,
    SPTextureFormat5551,
    SPTextureFormat4444
} SPTextureFormat;

typedef struct {
	int format;
	float width;
	float realWidth;
	float height;
	float realHeight;
	int numMipmaps;
	int generateMipmaps;
	int premultipliedAlpha;
	float scale;
	unsigned int dataLen;
	unsigned char* imgData;
} textureInfo;


unsigned int createGLTexture(unsigned int mTextureID, textureInfo *tInfo);
