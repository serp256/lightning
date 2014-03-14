
#ifndef RECTSBIN_H
#define RECTSBIN_H 

#include <stdint.h>

typedef struct {
	uint16_t x;
	uint16_t y;
} pnt_t;

typedef struct {
	uint16_t lb_x;
	uint16_t lb_y;
	uint16_t rt_x;
	uint16_t rt_y;
	uint16_t width;
	uint16_t height;
} rect_t;

typedef struct {
	int len;
	int size;
	rect_t** elems;
} rlist_t;

typedef struct {
	uint8_t id;
	uint16_t width;
	uint16_t height;
	rlist_t holes;
	rlist_t rects;
	rlist_t reuse_rects;
} bin_t;

pnt_t* bin_add_rect(bin_t* bin, uint16_t width, uint16_t height);
void bin_free_rect(bin_t* bin, pnt_t* pnt);

#endif
