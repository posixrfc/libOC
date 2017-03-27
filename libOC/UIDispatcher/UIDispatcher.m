#import "UIDispatcher.h"

static UIWindow *window;
static UIScreen *screen;
static CADisplayLink *lock_link;
static NSRunLoop *loop;

static BOOL locked = NO;
static unsigned long int lock_cnt = 0;
static unsigned long int loop_cnt = 0;

void (^cache_block)(void) = nil;
void (*cache_exector)(void) = NULL;

@implementation UIDispatcher
+ (BOOL)lockScreen
{
    if (locked) {
        return NO;
    }
    locked = YES;
    loop_cnt = 0;
    window.hidden = NO;
    [lock_link addToRunLoop:loop forMode:NSDefaultRunLoopMode];
    return YES;
}
+ (BOOL)unlockScreen
{
    if (!locked) {
        return NO;
    }
    locked = NO;
    [lock_link removeFromRunLoop:loop forMode:NSDefaultRunLoopMode];
    window.hidden = YES;
    if (NULL != cache_exector)
    {
        cache_exector();
        cache_exector = NULL;
    }
    if (nil != cache_block)
    {
        cache_block();
        cache_block = nil;
    }
    return YES;
}

+ (BOOL)lockScreenSeconds:(unsigned int)seconds
{
    return [self lockScreenFrames:60UL * seconds];
}
+ (BOOL)lockScreenSeconds:(unsigned int)seconds completed:(void (^)(void))block
{
    return [self lockScreenFrames:60UL * seconds completed:block];
}
+ (BOOL)lockScreenSeconds:(unsigned int)seconds executing:(void (*)(void))executor
{
    return [self lockScreenFrames:60UL * seconds executing:executor];
}

+ (BOOL)lockScreenFrames:(unsigned long int)frames
{
    if (0U == frames) {
        return YES;
    }
    lock_cnt = frames;
    return [self lockScreen];
}
+ (BOOL)lockScreenFrames:(unsigned long int)frames completed:(void (^)(void))block
{
    if (0U == frames) {
        return YES;
    }
    lock_cnt = frames;
    cache_block = block;
    return [self lockScreen];
}
+ (BOOL)lockScreenFrames:(unsigned long int)frames executing:(void (*)(void))executor
{
    if (0U == frames) {
        return YES;
    }
    lock_cnt = frames;
    cache_exector = executor;
    return [self lockScreen];
}

+ (BOOL)lockScreenInterval:(float)interval
{
    if (0.f < interval) {
        return [self lockScreenFrames:[self framesFromFloat:interval]];
    }
    return NO;
}
+ (BOOL)lockScreenInterval:(float)interval completed:(nullable void (^)(void))block
{
    if (0.f < interval) {
        return [self lockScreenFrames:[self framesFromFloat:interval] completed:block];
    }
    return NO;
}
+ (BOOL)lockScreenInterval:(float)interval executing:(nullable void (*)(void))executor
{
    if (0.f < interval) {
        return [self lockScreenFrames:[self framesFromFloat:interval] executing:executor];
    }
    return NO;
}
+ (unsigned long int)framesFromFloat:(float)interval
{
    NSAssert(0.f < interval, @(__func__));
    const long double frameInterval = 1.0 / 60.0;
    const long double roughFrames = interval / frameInterval;
    return (unsigned long int)roundl(roughFrames);
}

#pragma mark - initializer
+ (void)lockRunner:(CADisplayLink *)sender
{
    if (loop_cnt < lock_cnt)
    {
        loop_cnt++;
    }
    else
    {
        [self unlockScreen];
    }
}

+ (void)initialize
{
    screen = [UIScreen mainScreen];
    window = [[UIWindow alloc] initWithFrame:screen.bounds];
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = UIWindowLevelAlert;
    window.hidden = YES;
    window.userInteractionEnabled = YES;
    loop = [NSRunLoop mainRunLoop];
    lock_link = [screen displayLinkWithTarget:self selector:@selector(lockRunner:)];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return nil;
}

@end
