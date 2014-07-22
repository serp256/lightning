#ifndef MOBILERES_H

#define MOBILERES_H

#if IOS 
#import "ios/mlwrapper_ios.h"
#endif

#include <stdio.h>
#include "khash.h"
#include "light_common.h"

typedef struct {
	int32_t offset;
	int32_t size;
	int8_t location;
} offset_size_pair_t;

char* read_res_index(FILE* index, int offset_inc, int force_location);
int get_offset_size_pair(const char* path, offset_size_pair_t** pair);
int register_extra_res_fname(char* fname);
char* get_extra_res_fname(int id);

#endif
