#include "mobile_res.h"
#import "ios/mlwrapper_ios.h"

#ifdef ANDROID
#include "android/mlwrapper_android.h"	
#elif IOS
#import "ios/mlwrapper_ios.h"
#else
#endif

KHASH_MAP_INIT_STR(res_index, offset_size_pair_t*);
static kh_res_index_t* res_indx;

#define READ_RES_FAIL(...) {			\
	char* err_mes = (char*)malloc(255);	\
	sprintf(err_mes, __VA_ARGS__);		\
	return err_mes;						\
}										\

char* get_local_path(char* locale, char* path) {
	int locale_len = strlen(locale);
	int path_len = strlen(path);
	char* retval = (char*)malloc(9 + locale_len + path_len); // 8 = 6('locale') + 1 ('/') + 1('/' after locale identifier) + 1 ('\0')

	memcpy(retval, "locale/", 7);
	memcpy(retval + 7, locale, locale_len);
	*(retval + 7 + locale_len) = '/';
	strcpy(retval + locale_len + 8, path);

	return retval;
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

	PRINT_DEBUG("ok");
	return NULL;
}

static char* locale = NULL;

int get_offset_size_pair(const char* path, offset_size_pair_t** pair) {
	if (!res_indx) {
		return 1;
	}

	if (!locale)
#ifdef PC
		locale = "en";
#else
		locale = get_locale();
#endif

	khiter_t k;
	char* local_path = get_local_path(locale, path);

	do {
		PRINT_DEBUG("trying localized path %s", local_path);
		k = kh_get(res_index, res_indx, local_path);		
		if (k != kh_end(res_indx)) break;

		PRINT_DEBUG("trying original path %s", path);
		k = kh_get(res_index, res_indx, path);
		if (k != kh_end(res_indx)) break;

		PRINT_DEBUG("%s entry not found in expansions index", path);
		return 1;
	} while(0);

	offset_size_pair_t* val = kh_val(res_indx, k);	
	*pair = val;
	PRINT_DEBUG("%s entry found in index, offset %d, size %d, location %d", path, val->offset, val->size, val->location);
	free(local_path);

	return 0;
}