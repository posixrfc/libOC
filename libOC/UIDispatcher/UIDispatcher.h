#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
__attribute__((objc_subclassing_restricted))
@interface UIDispatcher : NSObject

#pragma mark - 所有锁屏方法，成功返回YES，否则返回NO
+ (BOOL)lockScreen;
+ (BOOL)unlockScreen;

+ (BOOL)lockScreenSeconds:(unsigned int)seconds;
+ (BOOL)lockScreenSeconds:(unsigned int)seconds completed:(nullable void (^)(void))block;
+ (BOOL)lockScreenSeconds:(unsigned int)seconds executing:(nullable void (*)(void))executor;

/** 1 frame = 1/60 秒 */
+ (BOOL)lockScreenFrames:(unsigned long int)frames;
+ (BOOL)lockScreenFrames:(unsigned long int)frames completed:(nullable void (^)(void))block;
+ (BOOL)lockScreenFrames:(unsigned long int)frames executing:(nullable void (*)(void))executor;

/**@param interval 秒数 */
+ (BOOL)lockScreenInterval:(float)interval;
+ (BOOL)lockScreenInterval:(float)interval completed:(nullable void (^)(void))block;
+ (BOOL)lockScreenInterval:(float)interval executing:(nullable void (*)(void))executor;

@end
NS_ASSUME_NONNULL_END
