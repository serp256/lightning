#ifndef __THQUEUE_H__

#define __THQUEUE_H__

#include <stdlib.h>
#include <pthread.h>

#define THQUEUE_INIT(name,content_t) \
	typedef struct {	\
		content_t content;	\
		void *next;	\
	} thqueue_##name##_cell;	\
	typedef struct { \
		unsigned int length;\
		pthread_mutex_t mutex;\
		thqueue_##name##_cell *tail;\
	} thqueue_##name##_t;\
	static inline thqueue_##name##_t *thqueue_##name##_create() {\
		thqueue_##name##_t *r = (thqueue_##name##_t*)malloc(sizeof(thqueue_##name##_t));\
		pthread_mutex_init(&r->mutex, NULL);\
		r->length = 0;\
		return r;\
	}\
	void thqueue_##name##_push(thqueue_##name##_t *q,content_t data) {\
		pthread_mutex_lock(&q->mutex);\
		if (q->length == 0) {\
			thqueue_##name##_cell *cell = malloc(sizeof(thqueue_##name##_cell));\
			cell->content = data;\
			cell->next = cell;\
			q->tail = cell;\
		} else {\
			thqueue_##name##_cell *tail = q->tail;\
			thqueue_##name##_cell *head = (thqueue_##name##_cell*)(tail->next);\
			thqueue_##name##_cell *cell = malloc(sizeof(thqueue_##name##_cell));\
			cell->content = data;\
			cell->next = head;\
			tail->next = cell;\
			q->tail = cell;\
		};\
		q->length++;\
		pthread_mutex_unlock(&q->mutex);\
	}\
	void* thqueue_##name##_pop(thqueue_##name##_t *q) {\
		pthread_mutex_lock(&q->mutex);\
		content_t res;\
		if (q->length == 0) res = NULL;\
		else {\
			thqueue_##name##_cell *tail = q->tail;\
			thqueue_##name##_cell *head = (thqueue_##name##_cell*)(tail->next);\
			if (head == tail) q->tail = NULL;\
			else tail->next = head->next;\
			res = head->content;\
			free(head);\
			q->length--;\
		};\
		pthread_mutex_unlock(&q->mutex);\
		return res;\
	}\
	void thqueue_##name##_delete(thqueue_##name##_t *q) {\
	}

#endif
