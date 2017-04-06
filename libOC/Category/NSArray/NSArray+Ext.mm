#import "NSArray+Ext.h"
#import <UIKit/UITableView.h>
#import <Foundation/NSIndexPath.h>
#import <stdlib.h>
#import <malloc/malloc.h>
#import "List.hpp"

@implementation NSArray (Ext)

- (NSArray *)reversedArray
{
    const signed long int len = self.count;
    if (2 > len) {
        return self;
    }
    id obj = [self firstObject];
    List<void *> *list = new List<void *>();
    list->queue_push((__bridge void *)obj);
    for (signed long int i = 1; i < len; i++)
    {
        obj = [self objectAtIndex:i];
        list->queue_push((__bridge void *)obj);
    }
    id objs[len];
    for (signed long int i = 0; i < len; i++) {
        objs[i] = (__bridge id)list->queue_pop();
    }
    delete list;
    return [NSArray arrayWithObjects:objs count:len];
}

- (NSArray *)randomedArray
{
    const signed long int len = self.count;
    if (2l > len) {
        return self;
    }
    id objs[len];
    for (long i = 0; i < len; i++) {
        objs[i] = [self objectAtIndex:i];
    }
    id resObjs[len];
    for (signed long int i = 0; i < len; i++)
    {
        long limit = len - i;
        long idx = arc4random_uniform((u_int32_t)limit);
        resObjs[i] = objs[idx];
        for (long j = idx; j < limit - 1; j++) {
            objs[j] = objs[j + 1];
        }
    }
    return [NSArray arrayWithObjects:resObjs count:len];
}

- (NSArray *)removeFirstObject
{
    const NSUInteger len = self.count;
    if (0l == len) {
        return self;
    }
    if (1l == len) {
        return @[];
    }
    return [self subArrayFromIndex:1];
}

- (NSArray *)removeLastObject
{
    const NSUInteger len = self.count;
    if (2l > len) {
        return [self removeFirstObject];
    }
    return [self subArrayToIndex:len - 1];
}

- (NSArray *)removeObject:(id)obj
{
    if (nil == obj) {
        return self;
    }
    const NSUInteger len = self.count;
    id objs[len];
    for (long i = 0; i < len; i++) {
        objs[i] = [self objectAtIndex:i];
    }
    for (NSUInteger i = 0; i < len; i++)
    {
        id objTmp = objs[i];
        if (objTmp == obj || [objTmp isEqual:obj])
        {
            for (NSUInteger j = i; j < len - 1; j++) {
                objs[j] = objs[j + 1];
            }
            return [[self class] arrayWithObjects:objs count:len - 1];
        }
    }
    return self;
}

- (NSArray *)removeObject:(id)obj allOccurred:(BOOL)all
{
    if (nil == obj) {
        return self;
    }
    if (!all) {
        return [self removeObject:obj];
    }
    const NSUInteger len = self.count;
    id objs[len];
    for (NSUInteger i = 0; i < len; ++i) {
        objs[i] = self[i];
    }
    NSUInteger limitLen = len;
    for (NSUInteger i = 0; i < limitLen; i++)
    {
        id objTmp = objs[i];
        if (objTmp == obj || [objTmp isEqual:obj])
        {
            for (NSUInteger j = i; j < limitLen - 1; j++) {
                objs[j] = objs[j + 1];
            }
            limitLen--;
        }
    }
    if (len == limitLen) {
        return self;
    }
    return [[self class] arrayWithObjects:objs count:limitLen];
}

- (NSArray *)removeObjectInRange:(NSRange)range
{
    if (0l == range.length) {
        return self;
    }
    const NSUInteger len = self.count;
    NSUInteger limitLen = range.location + range.length;
    void **objs = [self objects];
    id resObjs[len];
    for (NSUInteger i = 0; i < len; ++i)
    {
        resObjs[i] = (__bridge id)objs[i];
    }
    free(objs);
    
    for (NSUInteger i = range.location; i < limitLen; i++)
    {
        for (NSUInteger j = i; j < len + range.location - i - 1; j++)
        {
            resObjs[j] = resObjs[j + 1];
        }
    }
    return [[self class] arrayWithObjects:resObjs count:len - limitLen];
}

- (NSArray *)removeObjectAtIndex:(NSUInteger)idx
{
    const NSUInteger len = self.count;
    void **objs = [self objects];
    id resObjs[len];
    for (NSUInteger i = 0; i < len; i++)
    {
        resObjs[i] = (__bridge id)objs[i];
    }
    free(objs);
    for (NSUInteger i = idx; i < len - 1; i++)
    {
        resObjs[i] = resObjs[i + 1];
    }
    return [NSArray arrayWithObjects:resObjs count:len - 1];
}

- (NSArray *)removeObjectAtIndexes:(NSIndexSet *)idxSet
{
    __block NSArray * ret = self;
    [idxSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        ret = [ret removeObjectAtIndex:idx];
    }];
    return ret;
}

- (NSArray *)removeObjectsInArray:(NSArray *)array
{
    const NSUInteger len = array.count;
    NSArray *ret = self;
    for (NSUInteger i = 0; i < len; i++)
    {
        id tmp = [array objectAtIndex:i];
        ret = [ret removeObject:tmp];
    }
    return ret;
}

- (NSArray *)removeObjectsInArray:(NSArray *)array allOccurred:(BOOL)all
{
    const NSUInteger len = array.count;
    NSArray *ret = self;
    for (NSUInteger i = 0; i < len; i++)
    {
        id tmp = [array objectAtIndex:i];
        ret = [ret removeObject:tmp allOccurred:all];
    }
    return ret;
}

- (NSArray *)removeObject:(id)obj inRange:(NSRange)range
{
    NSArray *first = [self subArrayToIndex:range.location];
    NSArray *last = [self subArrayFromIndex:range.location + range.length];
    NSArray *operation = [self subarrayWithRange:range];
    NSArray *ret = [operation removeObject:obj];
    ret = [first addObjectsFromArray:ret];
    return [ret addObjectsFromArray:last];
}

- (NSArray *)removeObject:(id)obj inRange:(NSRange)range allOccurred:(BOOL)all
{
    NSArray *first = [self subArrayToIndex:range.location];
    NSArray *last = [self subArrayFromIndex:range.location + range.length];
    NSArray *operation = [self subarrayWithRange:range];
    NSArray *ret = [operation removeObject:obj allOccurred:all];
    ret = [first addObjectsFromArray:ret];
    return [ret addObjectsFromArray:last];
}

- (NSArray *)subArrayFromIndex:(NSUInteger)idx
{
    const NSUInteger len = self.count;
    id resObjs[len - idx];
    for (NSUInteger i = idx; i < len; i++)
    {
        resObjs[i - idx] = [self objectAtIndex:i];
    }
    return [NSArray arrayWithObjects:resObjs count:len - idx];
}

- (NSArray *)subArrayToIndex:(NSUInteger)idx
{
    id resObjs[idx];
    for (NSUInteger i = 0; i < idx; i++)
    {
        resObjs[i] = [self objectAtIndex:i];
    }
    return [NSArray arrayWithObjects:resObjs count:idx];
}

- (NSArray *)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    const signed long int len = self.count;
    void **objs = [self objects];
    id resObjs[len];
    for (signed long int i = 0; i < len; i++)
    {
        resObjs[i] = (__bridge id)(objs[i]);
    }
    free(objs);
    id tmp = resObjs[idx1];
    resObjs[idx1] = resObjs[idx2];
    resObjs[idx2] = tmp;
    return [NSArray arrayWithObjects:resObjs count:len];
}

- (NSArray *)addObject:(id)obj
{
    const NSUInteger len = self.count;
    void **objs = [self objects];
    id resObjs[len + 1];
    for (NSUInteger i = 0; i < len; i++)
    {
        resObjs[i] = (__bridge id)objs[i];
    }
    resObjs[len] = obj;
    free(objs);
    return [NSArray arrayWithObjects:resObjs count:len + 1];
}

- (NSArray *)addObjectsFromArray:(NSArray *)array
{
    const NSUInteger len = array.count;
    NSArray *ret = self;
    for (NSUInteger i = 0; i < len; i++)
    {
        id tmp = [array objectAtIndex:i];
        ret = [ret addObject:tmp];
    };
    return ret;
}

- (NSArray *)insertObject:(id)obj atIndex:(NSUInteger)idx
{
    const NSUInteger len = self.count;
    void **objs = [self objects];
    id resObjs[len + 1];
    for (NSUInteger i = 0; i < idx; i++)
    {
        resObjs[i] = (__bridge id)objs[i];
    }
    resObjs[idx] = obj;
    for (NSUInteger i = idx; i < len; i++)
    {
        resObjs[i + 1] = (__bridge id)objs[i];
    }
    free(objs);
    return [NSArray arrayWithObjects:resObjs count:len + 1];;
}

- (NSArray *)insertObjects:(nonnull NSArray *)array atIndexes:(nonnull NSIndexSet *)idxSet
{
    __block NSArray *ret = self;
    __block NSArray *tmpArr = array;
    [idxSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id tmp = [tmpArr lastObject];
        tmpArr = [tmpArr removeLaseObject];
        ret = [ret insertObject:tmp atIndex:idx];
    }];
    return ret;
}

- (id)objectForIndexPath:(NSIndexPath *)ip
{
    return [[self objectAtIndex:ip.section] objectAtIndex:ip.row];
}

- (id)objectForIndexPath:(NSIndexPath *)ip midSg:(NSString *)mdsg
{
    return [[[self objectAtIndex:ip.section] objectForKey:mdsg] objectAtIndex:ip.row];
}

@end
