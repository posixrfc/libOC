#import <Foundation/Foundation.h>
#import "OCUniversal.h"

NS_ASSUME_NONNULL_BEGIN
@interface NSArray (Ext)

- (NSArray *)randomedArray;/**随机排序*/

- (NSArray *)removeObject:(id)obj;/**删除首次出现的元素*/
- (NSArray *)removeObject:(id)obj allOccurred:(BOOL)all;/**删除某元素，可以删除它的全部出现，如果第二个参数是yes*/

- (NSArray *)removeObjectInRange:(NSRange)range;/**删除指定范围内的元素*/
- (NSArray *)removeObjectAtIndex:(NSUInteger)idx;/**删除指定位置的元素*/

- (NSArray *)removeObjectsInArray:(NSArray *)array;/**删除指定数组所包含的所有元素*/
/**删除指定数组所包含的所有元素,all确定是否删除重复的*/
- (NSArray *)removeObjectsInArray:(NSArray *)array allOccurred:(BOOL)all;

- (NSArray *)cleanDuplicated;
- (NSArray *)mergedArrayWithArray:(NSArray *)array distincted:(BOOL)distinct;

/**交换任意2元素顺序*/
- (NSArray *)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;


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
NS_ASSUME_NONNULL_END
