#include "rects-bin.h"
#include <stdlib.h>
#include <string.h>

#define MIN(a, b) (a < b ? a : b)
#define MAX(a, b) (a < b ? b : a)

#define IN_RANGE(v, from, to) (from <= v && v <= to)
#define RECTS_INTERSECTS(rect_a, rect_b) !(rect_a->right_top.x < rect_b->left_bottom.x || rect_b->right_top.x < rect_a->left_bottom.x || rect_a->right_top.y < rect_b->left_bottom.y || rect_b->right_top.y < rect_a->left_bottom.y)
#define PNT_INSIDE_RECT(pnt, rect) (IN_RANGE(pnt.x, rect->left_bottom.x, rect->right_top.x) && IN_RANGE(pnt.y, rect->left_bottom.y, rect->right_top.y))
#define RECT_INSIDE_RECT(outer, inner) (PNT_INSIDE_RECT(inner->left_bottom, outer) && PNT_INSIDE_RECT(inner->right_top, outer))

rect_t* rect_from_coords(uint16_t lb_x, uint16_t lb_y, uint16_t rt_x, uint16_t rt_y) {
	rect_t* retval = (rect_t*)malloc(sizeof(rect_t));
	retval->left_bottom.x = lb_x;
	retval->left_bottom.y = lb_y;
	retval->right_top.x = rt_x;
	retval->right_top.y = rt_y;
	retval->width = rt_x - lb_x;
	retval->height = rt_y - lb_y;

	return retval;
}

rect_t* rect_from_coords_n_dims(uint16_t lb_x, uint16_t lb_y, uint16_t width, uint16_t height) {
	rect_t* retval = (rect_t*)malloc(sizeof(rect_t));
	retval->left_bottom.x = lb_x;
	retval->left_bottom.y = lb_y;
	retval->right_top.x = lb_x + width;
	retval->right_top.y = lb_y + height;
	retval->width = width;
	retval->height = height;

	return retval;
}

rlist_t* rlist_create(rect_t* rect) {
	rlist_t* retval = (rlist_t*)malloc(sizeof(rlist_t));
	retval->data = rect;
	retval->prev = NULL;
	retval->next = NULL;

	return retval;
}

rlist_t* rlist_remove(rlist_t** list, rlist_t* node, uint8_t free_data) {
	rlist_t* retval = node->next;

	if (node->prev) {
		node->prev->next = node->next;
	}

	if (node->next) {
		node->next->prev = node->prev;
	}

	if (list && *list == node) {
		*list = retval;
	}

	if (free_data) free(node->data);
	free(node);
	return retval;
}

void rlist_unshift(rlist_t** list, rect_t* rect) {
	rlist_t* new_node = rlist_create(rect);
	new_node->next = *list;

	if (*list) {
		(*list)->prev = new_node;
	}

	*list = new_node;
}

rlist_t* rlist_join(rlist_t* list_a, rlist_t* list_b) {
	if (!list_a) {
		return list_b;
	}

	rlist_t* last_a = list_a;

	while (last_a->next) {
		last_a = last_a->next;
	}

	last_a->next = list_b;

	if (list_b) {
		list_b->prev = last_a;	
	}
	
	return list_a;
}

void rlist_free(rlist_t* list) {
	while (list) {
		list = rlist_remove(NULL, list, 1);
	}
}

#define RECT_CUTTING(lb_x, lb_y, rt_x, rt_y, cutting) rect_t* cutting = NULL; if (lb_x != rt_x && lb_y != rt_y) cutting = rect_from_coords(lb_x, lb_y, rt_x, rt_y);
#define PUT_CUTTING(list, cutting) if (cutting) rlist_unshift(&list, cutting);

rlist_t* rect_minus(rect_t* from, rect_t* rect) {
	RECT_CUTTING(from->left_bottom.x, from->left_bottom.y, rect->left_bottom.x, from->right_top.y, cutting_a);
	RECT_CUTTING(rect->left_bottom.x, from->left_bottom.y, rect->right_top.x, rect->left_bottom.y, cutting_b);
	RECT_CUTTING(rect->left_bottom.x, rect->right_top.y, rect->right_top.x, from->right_top.y, cutting_c);
	RECT_CUTTING(rect->right_top.x, from->left_bottom.y, from->right_top.x, from->right_top.y, cutting_d);

	rlist_t* retval = NULL;
	PUT_CUTTING(retval, cutting_a);
	PUT_CUTTING(retval, cutting_b);
	PUT_CUTTING(retval, cutting_c);
	PUT_CUTTING(retval, cutting_d);

	return retval;
}

#define HOLE_CUTTING(lb_x, lb_y, rt_x, rt_y, cond, cutting) rect_t* cutting = NULL; if (cond) cutting = rect_from_coords(lb_x, lb_y, rt_x, rt_y);

rlist_t* hole_minus(rect_t* hole, rect_t* rect) {
	HOLE_CUTTING(rect->right_top.x, hole->left_bottom.y, hole->right_top.x, hole->right_top.y, rect->right_top.x < hole->right_top.x, cutting_a);
	HOLE_CUTTING(hole->left_bottom.x, rect->right_top.y, hole->right_top.x, hole->right_top.y, rect->right_top.y < hole->right_top.y, cutting_b);
	HOLE_CUTTING(hole->left_bottom.x, hole->left_bottom.y, rect->left_bottom.x, hole->right_top.y, hole->left_bottom.x < rect->left_bottom.x, cutting_c);
	HOLE_CUTTING(hole->left_bottom.x, hole->left_bottom.y, hole->right_top.x, rect->left_bottom.y, hole->left_bottom.y < rect->left_bottom.y, cutting_d);

	rlist_t* retval = NULL;
	PUT_CUTTING(retval, cutting_a);
	PUT_CUTTING(retval, cutting_b);
	PUT_CUTTING(retval, cutting_c);
	PUT_CUTTING(retval, cutting_d);

	return retval;
}

uint8_t bin_id = 0;

bin_t* bin_create(uint16_t width, uint16_t height) {
	bin_t* retval = (bin_t*)malloc(sizeof(bin_t));

	retval->id = bin_id++;
	retval->width = width;
	retval->height = height;
	retval->holes = rlist_create(rect_from_coords_n_dims(0, 0, width, height));
	retval->reuse_rects = NULL;
	retval->rects = NULL;
	retval->reuse_rects = 0;

	return retval;
}

void bin_free(bin_t* bin) {
	rlist_free(bin->holes);
	rlist_free(bin->rects);
	rlist_free(bin->reuse_rects);

	free(bin);
}

void bin_clear(bin_t* bin) {
	rlist_free(bin->holes);
	rlist_free(bin->rects);
	rlist_free(bin->reuse_rects);

	bin->holes = rlist_create(rect_from_coords_n_dims(0, 0, bin->width, bin->height));
	bin->reuse_rects = NULL;
	bin->rects = NULL;
	bin->reuse_rects = 0;
}

uint8_t bin_need_repair(bin_t* bin) {
	return(bin->reuse_rects_num > 15);
}

void bin_find_pos(bin_t* bin, uint16_t width, uint16_t height, uint8_t* found, pnt_t* pnt) {
	rlist_t* hole = bin->holes;

	while (hole) {
		rect_t* rect = hole->data;

		if (rect->width >= width && rect->height >= height) {
			if (!(*found)) {
				pnt->x = rect->left_bottom.x;
				pnt->y = rect->left_bottom.y;
				*found = 1;
			} else {
				if (rect->left_bottom.y < pnt->y || (rect->left_bottom.y == pnt->y && rect->left_bottom.x < pnt->x)) {
					pnt->x = rect->left_bottom.x;
					pnt->y = rect->left_bottom.y;
				}
			}
		}

		hole = hole->next;
	}
}

void bin_add_rect_at(bin_t* bin, uint16_t x, uint16_t y, uint16_t width, uint16_t height) {
	rect_t* rect = rect_from_coords_n_dims(x, y, width, height);
	rlist_t* hole = bin->holes;
	rlist_t* max_holes = NULL;

	while (hole) {
		if (RECTS_INTERSECTS(hole->data, rect)) {
			rlist_t* cutting = hole_minus(hole->data, rect);

			while (cutting) {
				rlist_t* max_hole = max_holes;
				uint8_t new_max_hole = 1;

				while (max_hole) {
					if (RECT_INSIDE_RECT(max_hole->data, cutting->data)) {
						new_max_hole = 0;
						break;
					}

					if (RECT_INSIDE_RECT(cutting->data, max_hole->data)) {
						max_hole = rlist_remove(&max_holes, max_hole, 1);
					} else {
						max_hole = max_hole->next;
					}
				}

				if (new_max_hole) {
					rlist_unshift(&max_holes, cutting->data);
				}

				// if cutting become new max hole -- no need to free its data, cause data just moved to max_holes list. if cutting we inside another max hole, it must be completely freed
				cutting = rlist_remove(NULL, cutting, !new_max_hole); 
			}

			hole = rlist_remove(&bin->holes, hole, 1);
		} else {
			hole = hole->next;
		}
	}

	bin->holes = rlist_join(bin->holes, max_holes);
	rlist_unshift(&bin->rects, rect);
}

void bin_reuse_rect(bin_t* bin, uint16_t width, uint16_t height, uint8_t* reused, pnt_t* pnt) {
	rlist_t* rect = bin->reuse_rects;

	while (rect) {
		uint16_t wdiff = rect->data->width - width;
		uint16_t hdiff = rect->data->height - height;

		if (0 <= wdiff && wdiff < 10 && 0 <= hdiff && hdiff < 10) {
			rlist_unshift(&bin->rects, rect->data);
			rlist_remove(&bin->reuse_rects, rect, 0);
			bin->reuse_rects_num--;

			*reused = 1;
			pnt->x = rect->data->left_bottom.x;
			pnt->y = rect->data->left_bottom.y;

			return;
		}

		rect = rect->next;
	}

	*reused = 0;
}

void bin_add_rect(bin_t* bin, uint16_t width, uint16_t height, uint8_t* added, pnt_t* pnt) {
	bin_reuse_rect(bin, width, height, added, pnt);

	if (*added) {
		return;
	}

	bin_find_pos(bin, width, height, added, pnt);

	if (*added) {
		bin_add_rect_at(bin, pnt->x, pnt->y, width, height);
	}
}

void bin_repair(bin_t* bin) {
	if (bin_need_repair(bin)) {
		if (!bin->rects) {
			bin_clear(bin);
		} else {
			rlist_t* rect = bin->rects;

			bin->rects = NULL;
			bin_clear(bin);
			
			while (rect) {
				bin_add_rect_at(bin, rect->data->left_bottom.x, rect->data->left_bottom.y, rect->data->width, rect->data->height);
				rect = rlist_remove(NULL, rect, 1);
			}
		}
	}
}

void bin_rm_rect(bin_t* bin, pnt_t* pnt) {
	rlist_t* rect = bin->rects;

	while (rect) {
		if (rect->data->left_bottom.x == pnt->x && rect->data->left_bottom.y == pnt->y) {
			rlist_unshift(&bin->reuse_rects, rect->data);
			rlist_remove(&bin->rects, rect, 0);
			bin->reuse_rects_num++;

			break;
		}

		rect = rect->next;
	}
}
