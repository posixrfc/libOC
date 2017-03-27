#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sqlite3.h>
#import <pthread/pthread.h>
#import <string.h>
#import "OCUniversal.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
__attribute__((objc_subclassing_restricted))
@interface NSCachePool : NSObject

+ (void)prepare;//请务必在application:didFinishLaunchingWithOptions:中调用此方法准备缓存环境。否则可能闪退

#pragma mark - 所有存取操作，组ID可以为nil，代表默认组
+ (nullable NSArray<id<NSCopying>> *)memoryGroups;
+ (nullable NSArray<id<NSCopying>> *)memoryKeysInGroup:(nullable id<NSCopying>)ID;
+ (nullable NSArray<id> *)memoryValuesInGroup:(nullable id<NSCopying>)ID;
+ (void)memoryClearPool;
+ (void)memoryClearGroup:(nullable id<NSCopying>)ID;
+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID;
+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID duration:(signed long int)seconds;
+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID expireDate:(nullable NSDate *)expire;
+ (nullable id)memoryValueWithKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID;
+ (void)memoryRemoveValueWithKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID;

#pragma mark - disk系列方法，支持大数据量，大文件处理，需要SQLite(sqlite3.0)库支持。这里的ID不能包含任何 空白字符和控制字符
+ (nullable NSArray<NSString *> *)diskGroups;
+ (nullable NSArray<NSString *> *)diskKeysInGroup:(nullable NSString *)ID;
+ (nullable NSArray<id<NSCoding>> *)diskValuesInGroup:(nullable NSString *)ID;
+ (void)diskClearPool;
+ (void)diskClearGroup:(nullable NSString *)ID;
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID;
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID duration:(signed long int)seconds;
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID expireDate:(nullable NSDate *)expire;
+ (nullable id<NSCoding>)diskValueWithKey:(NSString *)key inGroup:(nullable NSString *)ID;
+ (void)diskRemoveValueWithKey:(NSString *)key inGroup:(nullable NSString *)ID;

@end
NS_ASSUME_NONNULL_END
