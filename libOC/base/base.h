#ifndef _base_h_
#define _base_h_

#import <stdlib.h>
#import <malloc/malloc.h>
#include <stdio.h>

#define list_ok 0

typedef int list_status;

struct _list_t {
    void *value;
    struct _list_t *prev;
    struct _list_t *next;
};

typedef struct _list_t list_t;
typedef enum {
    list_type_doubly_list,
    list_type_queue,
    list_type_stack
} list_type;

typedef enum {
    list_sequence_normal,
    list_sequence_reverse
} list_sequence;

extern list_t *list_t_create(list_type);
extern list_status list_t_set(list_t *, list_t *, long);
extern list_t *list_t_get(list_t *, long);
extern list_status list_t_drop(list_t *, long);
extern list_status list_t_destory(list_t *);


#endif /* _base_h_ */
