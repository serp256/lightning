#include "mobile_res.h"

KHASH_MAP_INIT_STR(res_index, offset_size_pair_t*);
static kh_res_index_t* res_indx;

#define READ_RES_FAIL(...) {			\
	char* err_mes = (char*)malloc(255);	\
	sprintf(err_mes, __VA_ARGS__);		\
	return err_mes;						\
}

char* read_res_index(FILE* index, int offset_inc) {
	res_indx = kh_init_res_index();

	if (!index) READ_RES_FAIL("cannot read index file");

	int32_t index_entries_num;		
	if (1 != fread(&index_entries_num, sizeof(int32_t), 1, index)) READ_RES_FAIL("cannot read resources index entries number");

	int i = 0;
	khiter_t k;
	offset_size_pair_t* pair;

	while (i++ < index_entries_num) {
		int8_t fname_len;
		if (1 != fread(&fname_len, sizeof(int8_t), 1, index)) READ_RES_FAIL("cannot read fname length for index entry %d", i - 1);

		char* fname = malloc(fname_len + 1);
		int32_t offset;
		int32_t size;
		int8_t location;

		if (fname_len != fread(fname, 1, fname_len, index)) READ_RES_FAIL("cannot read fname for entry %d", i - 1);
		*(fname + fname_len) = '\0';
		if (1 != fread(&offset, sizeof(int32_t), 1, index)) READ_RES_FAIL("cannot read offset for entry %d", i - 1);
		if (1 != fread(&size, sizeof(int32_t), 1, index)) READ_RES_FAIL("cannot read size for entry %d", i - 1);
		if (1 != fread(&location, sizeof(int8_t), 1, index)) READ_RES_FAIL("cannot read location for entry %d", i - 1);

		PRINT_DEBUG("fname: %s; original offset: %d; size: %d; location %d\n", fname, offset, size, location);

		int ret;
		pair = (offset_size_pair_t*)malloc(sizeof(offset_size_pair_t));
		pair->offset = offset + (location == 0 ? offset_inc : 0);
		pair->size = size;
		pair->location = location;

		k = kh_put(res_index, res_indx, fname, &ret);
		kh_val(res_indx, k) = pair;
	}
}

int get_offset_size_pair(const char* path, offset_size_pair_t** pair) {
	if (!res_indx) {
		return 1;
	}

	khiter_t k = kh_get(res_index, res_indx, path);

	if (k == kh_end(res_indx)) {
		PRINT_DEBUG("%s entry not found in expansions index", path);
		return 1;
	}

	offset_size_pair_t* val = kh_val(res_indx, k);	
	*pair = val;
	PRINT_DEBUG("%s entry found in index, offset %d, size %d, location %d", path, val->offset, val->size, val->location);

	return 0;
}
