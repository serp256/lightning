#ifndef RECTSBIN_H
#define RECTSBIN_H 

#include <stdint.h>

typedef struct {
	uint16_t x;
	uint16_t y;
} pnt_t;

typedef struct {
	pnt_t left_bottom;
	pnt_t right_top;
	uint16_t width;
	uint16_t height;
} rect_t;

typedef struct rlist_t {
	rect_t* data;
	struct rlist_t* prev;
	struct rlist_t* next;
} rlist_t;

typedef struct {
	uint8_t id;
	uint16_t width;
	uint16_t height;
	rlist_t* holes;
	rlist_t* rects;
	rlist_t* reuse_rects;
	int reuse_rects_num;
} bin_t;

bin_t*	bin_create(uint16_t width, uint16_t height);
void	bin_free(bin_t* bin);
void	bin_add_rect(bin_t* bin, uint16_t width, uint16_t height, uint8_t* added, pnt_t* pnt);
void 	bin_rm_rect(bin_t* bin, pnt_t* pnt);
void 	bin_repair(bin_t* bin);
void 	bin_clear(bin_t* bin);
uint8_t	bin_need_repair(bin_t* bin);

#endif