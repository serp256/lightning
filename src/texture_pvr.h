#ifndef __TEXTURE_PVR_H__
#define __TEXTURE_PVR_H__

#include <stdio.h>
#include "texture_common.h"

int loadPvrFile2(FILE *fildes,textureInfo *tInfo);
int loadPvrFile3(FILE* fildes,size_t len, textureInfo *tInfo);
int loadDdsFile(FILE* fildes,size_t len, textureInfo *tInfo);


#endif
