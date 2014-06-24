#ifndef __TEXTURE_PVR_H__
#define __TEXTURE_PVR_H__

#include <stdio.h>
#include "texture_common.h"

// int loadPvrFile2(FILE *fildes,textureInfo *tInfo);
int loadPvrFile3(gzFile gzf, textureInfo *tInfo);
int loadDdsFile(gzFile gzf, textureInfo *tInfo);
int loadCompressedFile(gzFile gzf, textureInfo *tInfo);

#endif
