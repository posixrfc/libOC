#ifndef List_hpp
#define List_hpp

template <typename node_type>
class ListNode
{
private:
//    friend class List;
    ListNode *prev;
    ListNode *next;
    node_type value;
public:
    ListNode(node_type);
};

template <class list_type>
class List
{
protected:
    unsigned long count;
    ListNode<list_type> *head;
    ListNode<list_type> *tail;
public:
    List();
    virtual ~List();
    
    void queue_push(list_type);
    list_type queue_pop();
    
    void stack_push(list_type);
    list_type stack_pop();
    
    void list_set(list_type, unsigned long);
	void list_add(list_type, unsigned long);
    list_type list_get(unsigned long);
    list_type list_pop(unsigned long);
    
    unsigned long getCount() const;
};

#endif /* List_hpp */
