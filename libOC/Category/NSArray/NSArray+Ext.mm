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
    const NSUInteger len = self.count;
    const NSUInteger limitLen = range.location + range.length;
    if (len < limitLen) {
        throwExecption;
    }
    id objs[len - limitLen];
    for (NSUInteger i = 0; i < range.location; ++i) {
        objs[i] = self[i];
    }
    for (NSUInteger i = limitLen; i < len; i++) {
        objs[range.location++] = self[i];
    }
    return [[self class] arrayWithObjects:objs count:len - limitLen];
}

- (NSArray *)removeObjectAtIndex:(NSUInteger)idx
{
    return [self removeObjectInRange:(NSRange){idx, 1}];
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

- (NSArray *)cleanDuplicated
{
    NSUInteger len = self.count;
    id objs[len];
    for (NSUInteger i = 0; i < len; i++) {
        objs[i] = self[i];
    }
    for (NSUInteger i = 0; i < len - 1; i++)
    {
        for (NSUInteger j = i + 1; j < len; j++)
        {
            if (objs[i] == objs[j] || [objs[i] isEqual:objs[j]])
            {
                for (NSUInteger k = j; k < len - 1; k++) {
                    objs[k] = objs[k + 1];
                }
                j -= 1;
                len -= 1;
            }
        }
    }
    return [[[self class] alloc] initWithObjects:objs count:len];
}

- (NSArray *)mergedArrayWithArray:(NSArray *)array distincted:(BOOL)distinct
{
    NSUInteger len0 = self.count, len1 = array.count;
    NSUInteger len = len0 + len1;
    id objs[len];
    for (NSUInteger i = 0; i < len0; i++) {
        objs[i] = self[i];
    }
    for (NSUInteger i = 0; i < len1; i++) {
        objs[len0 + i] = array[i];
    }
    NSArray *ret = [[[self class] alloc] initWithObjects:objs count:len];
    if (distinct) {
        ret = [ret cleanDuplicated];
    }
    return ret;
}

- (NSArray *)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    NSInteger len = self.count;
    id objs[len];
    for (NSUInteger i = 0; i < len; i++) {
        objs[i] = self[i];
    }
    id tmp = objs[idx1];
    objs[idx1] = objs[idx2];
    objs[idx2] = tmp;
    return [NSArray arrayWithObjects:objs count:len];
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
    return [NSArray arrayWithObjects:resObjs count:len + 1];
}
- (NSArray *)insertObjects:(NSArray *)array atIndex:(NSUInteger)idx;

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
