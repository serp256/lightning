#define DLLIST_DEF(type) typedef struct dllist_##type { \
    type data; \
    struct dllist_##type *prev; \
    struct dllist_##type *next; \
} dllist_##type##_t; \
\
dllist_##type##_t* dllist_##type##_add(dllist_##type##_t **list, type data); \
void dllist_##type##_remove(dllist_##type##_t **list, dllist_##type##_t *el);

#define DLLIST_IMPL(type) dllist_##type##_t* dllist_##type##_add(dllist_##type##_t **list, type data) { \
    dllist_##type##_t *el = (dllist_##type##_t*)malloc(sizeof(dllist_##type##_t)); \
    el->data = data; \
\
    if (!(*list)) { \
        el->next = el; \
        el->prev = el; \
\
        *list = el; \
    } else { \
        el->prev = (*list)->prev; \
        el->next = *list; \
\
        (*list)->prev->next = el; \
        (*list)->prev = el; \
    } \
\
		return el; \
} \
\
void dllist_##type##_remove(dllist_##type##_t **list, dllist_##type##_t *el) { \
	if (*list == el && (*list)->next == el) { \
		free(el); \
		*list = NULL; \
    } else { \
		el->prev->next = el->next; \
		el->next->prev = el->prev; \
\
		if (*list == el) { \
				*list = el->next; \
		} \
\
		free(el); \
	} \
}
