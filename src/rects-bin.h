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
} rbin_t;

bin_t*	rbin_create(uint16_t width, uint16_t height);// fill nah
void	rbin_free(bin_t* bin);

uint8_t rbin_reuse_rect(bin_t* bin, uint16_t width, uint16_t height, pnt_t* pnt);
uint8_t	rbin_add_rect(bin_t* bin, uint16_t width, uint16_t height, pnt_t* pnt);
void 	rbin_rm_rect(bin_t* bin, pnt_t* pnt);
void 	rbin_repair(bin_t* bin);
void 	rbin_clear(bin_t* bin);
uint8_t	rbin_need_repair(bin_t* bin);

#endif
