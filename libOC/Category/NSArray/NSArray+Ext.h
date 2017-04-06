#import <Foundation/Foundation.h>
#import "OCUniversal.h"

@interface NSArray (Ext)


- (nonnull NSArray *)reversedArray;/**数组逆序*/
- (nonnull NSArray *)randomedArray;/**随机排序*/

- (nonnull NSArray *)removeFirstObject;/**删除首元素*/
- (nonnull NSArray *)removeLastObject;/**删除尾元素*/

- (nonnull NSArray *)removeObject:(nonnull id)obj;/**删除首次出现的元素*/
- (nonnull NSArray *)removeObject:(nonnull id)obj allOccurred:(BOOL)all;/**删除某元素，可以删除它的全部出现，如果第二个参数是yes*/

- (nonnull NSArray *)removeObjectInRange:(NSRange)range;/**删除置顶范围内的元素*/

/**
 *  删除指定位置的元素
 */
- (nonnull NSArray *)removeObjectAtIndex:(NSUInteger)idx;

/**
 *  删除指定位置的所有元素
 */
- (nonnull NSArray *)removeObjectAtIndexes:(nonnull NSIndexSet *)idxSet;

/**
 *  删除指定数组所包含的所有元素
 */
- (nonnull NSArray *)removeObjectsInArray:(nonnull NSArray *)array;

/**
 *  删除指定数组所包含的所有元素,all确定是否删除重复的
 */
- (nonnull NSArray *)removeObjectsInArray:(nonnull NSArray *)array allOccurred:(BOOL)all;

/**
 *  删除指定范围内的某元素
 */
- (nonnull NSArray *)removeObject:(nonnull id)obj inRange:(NSRange)range;

/**
 *  删除指定范围内的某元素,all确定是否删除重复的
 */
- (nonnull NSArray *)removeObject:(nonnull id)obj inRange:(NSRange)range allOccurred:(BOOL)all;

/**
 *  从指定位置开始截取子数组，直到最后
 */
- (nonnull NSArray *)subArrayFromIndex:(NSUInteger)idx;

/**
 *  从首元素开始截取子数组，到指定位置止
 */
- (nonnull NSArray *)subArrayToIndex:(NSUInteger)idx;

/**
 *  交换任意2元素顺序
 */
- (nonnull NSArray *)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;

/**
 *  添加指定元素到当前数组后面
 */
- (nonnull NSArray *)addObject:(nonnull id)obj;

/**
 *  添加参数数组的所有元素在当前数组的后面
 */
- (nonnull NSArray *)addObjectsFromArray:(nonnull NSArray *)array;

/**
 *  在指定的索引位置插入一个元素
 */
- (nonnull NSArray *)insertObject:(nonnull id)obj atIndex:(NSUInteger)idx;

/**
 *  在指定的索引位置依次添加数组中元素到当前数组
 */
- (nonnull NSArray *)insertObjects:(nonnull NSArray *)array atIndexes:(nonnull NSIndexSet *)idxSet;

/**
 *  专用于2维数组
 *
 *  @param ip ip.section/row分别作为数组1/2级索引
 *
 *  @return objc_object *
 */
- (nullable id)objectForIndexPath:(nonnull NSIndexPath *)ip;

/**
 *  专用于2维数组,1级数组里存NSDictionary
 *
 *  @param ip   ip ip.section/row分别作为数组1/2级索引
 *  @param mdsg 取NSDictionary的key
 *
 *  @return objc_object *
 */
- (nullable id)objectForIndexPath:(nonnull NSIndexPath *)ip midSg:(nonnull NSString *)mdsg;

@end
