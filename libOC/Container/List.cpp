#if defined(_WIN32) || defined(_WIN64)
#include "stdafx.h"
#endif
#include "List.hpp"

template <typename node_type>
ListNode<node_type>::ListNode(node_type value)
{
    this->value = value;
    this->prev = nullptr;
    this->next = nullptr;
}

template <class list_type>
List<list_type>::List()
{
    this->head = this->tail = nullptr;
    this->count = 0UL;
}

template <class list_type>
List<list_type>::~List()
{
    while (this->head)
    {
        ListNode<list_type> *node = this->head->next;
        delete this->head;
        this->head = node;
    }
}

template <class list_type>
void List<list_type>::queue_push(list_type value)
{
    ListNode<list_type> *node = new ListNode<list_type>(value);
    this->count += 1;
    if (1 == this->count)
    {
        this->head = this->tail = node;
        return;
    }
    ListNode<list_type> *tmp = this->tail;
    this->tail = node;
    node->prev = tmp;
    tmp->next = node;
}

template <class list_type>
list_type List<list_type>::queue_pop()
{
    return this->stack_pop();
}

template <class list_type>
void List<list_type>::stack_push(list_type value)
{
    ListNode<list_type> *node = new ListNode<list_type>(value);
    this->count += 1;
    if (1 == this->count)
    {
        this->head = this->tail = node;
        return;
    }
    ListNode<list_type> *tmp = this->head;
    this->head = node;
    node->next = tmp;
    tmp->prev = node;
}

template <class list_type>
list_type List<list_type>::stack_pop()
{
    if (0UL == this->count) {
        throw "no any element";
    }
    this->count -= 1;
    if (0UL == this->count)
    {
        list_type value = this->head->value;
        delete this->head;
        this->head = this->tail = nullptr;
        return value;
    }
    list_type value = this->head->value;
    ListNode<list_type> *node = this->head->next;
    delete this->head;
    node->prev = nullptr;
    this->head = node;
    return value;
}

template <class list_type>
void List<list_type>::list_set(list_type value, unsigned long idx)
{
    if (idx > this->count) {
        throw "index invalid";
    }
    if (idx == this->count)
    {
        this->queue_push(value);
        return;
    }
    unsigned long mid = this->count / 2;
    if (idx < mid)
    {
        ListNode<list_type> *node = this->head;
        for (unsigned long i = 0; i < mid; i++)
        {
            if (i == idx) {
                break;
            }
            node = node->next;
        }
        node->value = value;
        return;
    }
    ListNode<list_type> *node = this->tail;
    for (unsigned long i = this->count - 1; i >= mid; i--)
    {
        if (i == idx) {
            break;
        }
        node = node->prev;
    }
    node->value = value;
}

template <class list_type>
void List<list_type>::list_add(list_type value, unsigned long idx)
{
	if (idx > this->count) {
        throw "index invalid";
    }
    if (idx == this->count)
    {
        this->queue_push(value);
        return;
    }
    if (0LU == idx)
    {
        this->stack_push(value);
        return;
    }
    unsigned long mid = this->count / 2;
    this->count += 1;
    ListNode<list_type> *node = new ListNode<list_type>(value);
    if (idx < mid)
    {
        ListNode<list_type> *tmp = this->head->next;
        for (unsigned long i = 1; i < mid; i++)
        {
            if (i == idx) {
                break;
            }
            tmp = tmp->next;
        }
        tmp->prev->next = node;
        node->prev = tmp->prev;
        node->next = tmp;
        tmp->prev = node;
        return;
    }
    ListNode<list_type> *tmp = this->tail;
    for (unsigned long i = this->count - 2; i >= mid; i--)
    {
        if (i == idx) {
            break;
        }
        tmp = tmp->prev;
    }
    tmp->prev->next = node;
    node->prev = tmp->prev;
    node->next = tmp;
    tmp->prev = node;
}

template <class list_type>
list_type List<list_type>::list_get(unsigned long idx)
{
    if (idx >= this->count) {
        throw "index invalid";
    }
    unsigned long mid = this->count / 2;
    if (idx < mid)
    {
        ListNode<list_type> *node = this->head;
        for (unsigned long i = 0; i < mid; i++)
        {
            if (i == idx) {
                break;
            }
            node = node->next;
        }
        return node->value;
    }
    ListNode<list_type> *node = this->tail;
    for (unsigned long i = this->count - 1; i >= mid; i--)
    {
        if (i == idx) {
            break;
        }
        node = node->prev;
    }
    return node->value;
}

template <class list_type>
list_type List<list_type>::list_pop(unsigned long idx)
{
    if (idx >= this->count) {
        throw "index invalid";
    }
    unsigned long mid = this->count / 2;
    this->count -= 1;
    if (idx < mid)
    {
        ListNode<list_type> *node = this->head;
        for (unsigned long i = 0; i < mid; i++)
        {
            if (i == idx) {
                break;
            }
            node = node->next;
        }
        list_type value = node->value;
        ListNode<list_type> *prevNode = node->prev;
        ListNode<list_type> *nextNode = node->next;
        delete node;
        if (nullptr != prevNode) {
            prevNode->next = nextNode;
        }
        if (nullptr != nextNode) {
            nextNode->prev = prevNode;
        }
        return value;
    }
    ListNode<list_type> *node = this->tail;
    for (unsigned long i = this->count; i >= mid; i--)
    {
        if (i == idx) {
            break;
        }
        node = node->prev;
    }
    list_type value = node->value;
    ListNode<list_type> *prevNode = node->prev;
    ListNode<list_type> *nextNode = node->next;
    delete node;
    if (nullptr != prevNode) {
        prevNode->next = nextNode;
    }
    if (nullptr != nextNode) {
        nextNode->prev = prevNode;
    }
    return value;
}

template <class list_type>
unsigned long List<list_type>::getCount() const
{
    return this->count;
}
