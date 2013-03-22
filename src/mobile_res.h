#include <stdio.h>
#include "khash.h"

typedef struct {
	int32_t offset;
	int32_t size;
	int8_t location;
} offset_size_pair_t;

char* read_res_index(FILE* index, int offset_inc);
int get_offset_size_pair(const char* path, offset_size_pair_t** pair);