#import "NSCachePool.h"

static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *pool = nil;
static NSString *general_key = nil;

static NSFileManager *filemgr = nil;
static sqlite3 *dbHandler;
static NSString *dbPath;
static NSString *dataDir;
static pthread_mutex_t mutex;
static NSMutableArray<NSString *> *tables;

@implementation NSCachePool

+ (void)prepare{}
+ (nullable NSArray<id<NSCopying>> *)memoryGroups
{
    return [pool allKeys];
}
+ (nullable NSArray<id<NSCopying>> *)memoryKeysInGroup:(nullable id<NSCopying>)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return nil;
    }
    return [[pool objectForKey:group_id] allKeys];
}

+ (nullable NSArray<id> *)memoryValuesInGroup:(nullable id<NSCopying>)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return nil;
    }
    return [[pool objectForKey:group_id] allValues];
}

+ (void)memoryClearPool
{
    [pool removeAllObjects];
}

+ (void)memoryClearGroup:(nullable id<NSCopying>)ID;
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return;
    }
    [pool removeObjectForKey:group_id];
}

+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return;
    }
    if (nil == key) {
        return;
    }
    if (![(id)key conformsToProtocol:@protocol(NSCopying)]) {
        return;
    }
    if (nil == value) {
        return;
    }
    NSMutableDictionary<NSString *, id> *container = [pool objectForKey:group_id];
    if (nil == container)
    {
        container = [NSMutableDictionary dictionaryWithCapacity:8];
        [pool setObject:container forKey:group_id];
    }
    [container setObject:value forKey:key];
}
+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID duration:(signed long int)seconds
{
    NSString *group_id = (NSString *)ID;
    if (0 < seconds)
    {
        [self memorySetValue:value withKey:key inGroup:group_id];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self memoryRemoveValueWithKey:key inGroup:group_id];
        });
    }
}
+ (void)memorySetValue:(id)value withKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID expireDate:(nullable NSDate *)expire
{
    NSString *group_id = (NSString *)ID;
    if (nil == expire)
    {
        [self memorySetValue:value withKey:key inGroup:group_id];
    }
    else
    {
        signed long int currentTimeStamp = [[NSDate date] timeIntervalSince1970];
        signed long int expireTimeStamp = [expire timeIntervalSince1970];
        signed long duringTime = expireTimeStamp - currentTimeStamp;
        [self memorySetValue:value withKey:key inGroup:group_id duration:duringTime];
    }
}

+ (nullable id)memoryValueWithKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return nil;
    }
    if (nil == key) {
        return nil;
    }
    if (![(id)key conformsToProtocol:@protocol(NSCopying)]) {
        return nil;
    }
    return [[pool objectForKey:group_id] objectForKey:(NSString *)key];
}

+ (void)memoryRemoveValueWithKey:(id<NSCopying>)key inGroup:(nullable id<NSCopying>)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![(id)group_id conformsToProtocol:@protocol(NSCopying)]) {
        return;
    }
    if (nil == key) {
        return;
    }
    if (![(id)key conformsToProtocol:@protocol(NSCopying)]) {
        return;
    }
    NSMutableDictionary<NSString *, id> *container = [pool objectForKey:group_id];
    if (nil != container)
    {
        [container removeObjectForKey:(NSString *)key];
        if (0U == container.count) {
            [pool removeObjectForKey:group_id];
        }
    }
}

+ (nullable NSArray<NSString *> *)diskGroups
{
    return 0 == tables.count ? nil : [tables copy];
}
+ (nullable NSArray<NSString *> *)diskKeysInGroup:(nullable NSString *)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (0 == group_id.length) {
        return nil;
    }
    group_id = [self canonicalStringWithString:group_id];
    if (![tables containsObject:group_id]) {
        return nil;
    }
    NSString *SQL = [NSString stringWithFormat:@"select * from %@", group_id];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    NSMutableArray<NSString *> *keys = [NSMutableArray new];
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    while (SQLITE_ROW == sqlite3_step(stmt))
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        NSString *key = [NSString stringWithUTF8String:(const char *)text];
        sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        if (queryTimestamp > currentTimestamp)
        {
            [keys addObject:key];
             continue;
        }
        SQL = [NSString stringWithFormat:@"delete from %@ where path = '%s'", group_id, text];
        pthread_mutex_lock(&mutex);
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
        [filemgr removeItemAtPath:SQL error:NULL];
        pthread_mutex_unlock(&mutex);
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    return 0 == keys.count ? nil : keys;
}
+ (nullable NSArray<id<NSCoding>> *)diskValuesInGroup:(nullable NSString *)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (0 == group_id.length) {
        return nil;
    }
    group_id = [self canonicalStringWithString:group_id];
    if (![tables containsObject:group_id]) {
        return nil;
    }
    NSString *SQL = [NSString stringWithFormat:@"select * from %@", group_id];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    NSMutableArray<NSString *> *keys = [NSMutableArray new];
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    while (SQLITE_ROW == sqlite3_step(stmt))
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        NSString *key = [NSString stringWithUTF8String:(const char *)text];
        sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        if (queryTimestamp > currentTimestamp)
        {
            [keys addObject:key];
            continue;
        }
        SQL = [NSString stringWithFormat:@"delete from %@ where path = '%s'", group_id, text];
        pthread_mutex_lock(&mutex);
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
        [filemgr removeItemAtPath:SQL error:NULL];
        pthread_mutex_unlock(&mutex);
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    long key_count = keys.count;
    if (0 == key_count) {
        return nil;
    }
    NSMutableArray<id<NSCoding>> *values = [NSMutableArray arrayWithCapacity:key_count];
    for (long i = 0; i < key_count; i++)
    {
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:keys[i]];
        [values addObject:[NSKeyedUnarchiver unarchiveObjectWithFile:SQL]];
    }
    return values;
}
+ (void)diskClearPool
{
    pthread_mutex_lock(&mutex);
    if ([filemgr removeItemAtPath:dataDir error:NULL]) {
        throwExecption;
    }
    if ([filemgr createDirectoryAtPath:dataDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
        throwExecption;
    }
    if ([filemgr createFileAtPath:dbPath contents:nil attributes:nil]) {
        throwExecption;
    }
    [tables removeAllObjects];
    pthread_mutex_unlock(&mutex);
}
+ (void)diskClearGroup:(nullable NSString *)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return;
    }
    if (0 == group_id.length) {
        return;
    }
    group_id = [self canonicalStringWithString:group_id];
    long idx = [tables indexOfObject:group_id];
    if (NSNotFound == idx) {
        return;
    }
    NSString *tableFolder = [dataDir stringByAppendingPathComponent:group_id];
    if (![filemgr fileExistsAtPath:tableFolder]) {
        return;
    }
    NSString *SQL = [@"drop table " stringByAppendingString:group_id];
    pthread_mutex_lock(&mutex);
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    if ([filemgr removeItemAtPath:tableFolder error:NULL]) {
        throwExecption;
    }
    [tables removeObjectAtIndex:idx];
    pthread_mutex_unlock(&mutex);
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID
{
    [self diskSetValue:value withKey:key inGroup:ID duration:LONG_LONG_MAX];
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID duration:(signed long int)seconds
{
    if (seconds <= 0) {
        return;
    }
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return;
    }
    if (0u == group_id.length) {
        return;
    }
    group_id = [self canonicalStringWithString:group_id];
    if (![key isKindOfClass:[NSString class]]) {
        return;
    }
    if (0 == key.length) {
        return;
    }
    key = [self canonicalStringWithString:key];
    if (![(id)value conformsToProtocol:@protocol(NSCoding)]) {
        return;
    }
    NSString *SQL = nil;
    if (![tables containsObject:group_id])
    {
        SQL = [dataDir stringByAppendingPathComponent:group_id];
        if ([filemgr fileExistsAtPath:SQL])
        {
            if (![filemgr removeItemAtPath:SQL error:NULL]) {
                throwExecption;
            }
        }
        pthread_mutex_lock(&mutex);
        if (![filemgr createDirectoryAtPath:SQL withIntermediateDirectories:YES attributes:nil error:NULL]) {
            throwExecption;
        }
        SQL = [NSString stringWithFormat:@"create table if not exists %@(path text primary key unique not null, expire integer not null)", group_id];
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }
        [tables addObject:group_id];
        pthread_mutex_unlock(&mutex);
    }
    SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    const sqlite3_int64 maximalDuration = LONG_LONG_MAX - currentTimestamp;
    seconds = MIN(seconds, maximalDuration);
    const sqlite3_int64 queryTimestamp = currentTimestamp + seconds;
    pthread_mutex_lock(&mutex);
    if (![NSKeyedArchiver archiveRootObject:value toFile:SQL]) {
        throwExecption;
    }
    SQL = [NSString stringWithFormat:@"replace into %@(path, expire) values('%@', %lld)", group_id, key, queryTimestamp];
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    pthread_mutex_unlock(&mutex);
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID expireDate:(nullable NSDate *)expire
{
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    const sqlite3_int64 queryTimestamp = [expire timeIntervalSince1970];
    const sqlite3_int64 offsetTimestamp = currentTimestamp - queryTimestamp;
    if (offsetTimestamp > 0) {
        [self diskSetValue:value withKey:key inGroup:ID duration:offsetTimestamp];
    }
}
+ (nullable id<NSCoding>)diskValueWithKey:(NSString *)key inGroup:(nullable NSString *)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (0u == group_id.length) {
        return nil;
    }
    group_id = [self canonicalStringWithString:group_id];
    if (![tables containsObject:group_id]) {
        return nil;
    }
    if (![key isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (0u == key.length) {
        return nil;
    }
    key = [self canonicalStringWithString:key];
    NSString *SQL = [NSString stringWithFormat:@"select * from %@ where path = '%@'", group_id, key];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    if (SQLITE_ROW == sqlite3_step(stmt))
    {
        const sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        if (SQLITE_OK != sqlite3_finalize(stmt)) {
            throwExecption;
        }
        const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
        BOOL isDir;
        BOOL isExists = [filemgr fileExistsAtPath:SQL isDirectory:&isDir];
        if (isExists && isDir)
        {
            [filemgr removeItemAtPath:SQL error:NULL];
            isExists = NO;
        }
        if (isExists && queryTimestamp < currentTimestamp)
        {
            [filemgr removeItemAtPath:SQL error:NULL];
            isExists = NO;
        }
        if (!isExists)
        {
            SQL = [NSString stringWithFormat:@"delete from %@ where path = '%@'", group_id, key];
            if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
                throwExecption;
            }
            return nil;
        }
        return [NSKeyedUnarchiver unarchiveObjectWithFile:SQL];
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    return nil;
}
+ (void)diskRemoveValueWithKey:(NSString *)key inGroup:(nullable NSString *)ID
{
    NSString *group_id = (NSString *)ID;
    if (nil == group_id) {
        group_id = general_key;
    }
    if (![group_id isKindOfClass:[NSString class]]) {
        return;
    }
    if (0u == group_id.length) {
        return;
    }
    group_id = [self canonicalStringWithString:group_id];
    if (![tables containsObject:group_id]) {
        return;
    }
    if (![key isKindOfClass:[NSString class]]) {
        return;
    }
    if (0u == key.length) {
        return;
    }
    key = [self canonicalStringWithString:key];
    NSString *SQL = [NSString stringWithFormat:@"delete from %@ where path = '%@'", group_id, key];
    pthread_mutex_lock(&mutex);
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
    if (![filemgr fileExistsAtPath:SQL]) {
        [filemgr removeItemAtPath:SQL error:NULL];
    }
    pthread_mutex_unlock(&mutex);
}
+ (NSString *)canonicalStringWithString:(NSString *)src
{
    const signed long int len = src.length;
    NSMutableString *mstring = [[NSMutableString alloc] initWithCapacity:len + len];
    for (long i = 0; i < len; i++) {
        [mstring appendFormat:@"_%hX", [src characterAtIndex:i]];
    }
    return mstring;
}

+ (void)initialize
{
    pool = [NSMutableDictionary dictionaryWithCapacity:0xF];
    general_key = NSStringFromClass(self);
    
    dataDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    dataDir = [dataDir stringByAppendingPathComponent:general_key];
    dbPath = [[dataDir stringByAppendingPathComponent:general_key] stringByAppendingPathExtension:@"idx"];
    
    pthread_mutex_init(&mutex, NULL);
    tables = [NSMutableArray new];
    filemgr = [NSFileManager new];
    BOOL isDir;
    if ([filemgr fileExistsAtPath:dataDir isDirectory:&isDir])
    {
        if (!isDir) //存在此文件
        {
            if (![filemgr removeItemAtPath:dataDir error:NULL]) {
                throwExecption;
            }
            if (![filemgr createDirectoryAtPath:dataDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
                throwExecption;
            }
        }
    }
    else
    {
        if (![filemgr createDirectoryAtPath:dataDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
            throwExecption;
        }
    }
    if ([filemgr fileExistsAtPath:dbPath isDirectory:&isDir])
    {
        if (isDir) {
            throwExecption;
        }
    }
    else
    {
        if (![filemgr createFileAtPath:dbPath contents:nil attributes:nil]) {
            throwExecption;
        }
    }
    if (SQLITE_OK != sqlite3_open([dbPath UTF8String], &dbHandler)) {
        throwExecption;
    }
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, "select tbl_name from sqlite_master where type = 'table'", -1, &stmt, NULL)) {
        throwExecption;
    }
    while (SQLITE_ROW == sqlite3_step(stmt))
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        [tables addObject:[NSString stringWithUTF8String:(const char *)text]];
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }// 获取了所有表名
    const sqlite3_int64 timeStamp = [[NSDate date] timeIntervalSince1970];
    for (signed long int i = 0, cnt = tables.count; i < cnt; i++)
    {
        NSString *SQL = [NSString stringWithFormat:@"select path from %@ where expire < %lld", tables[i], timeStamp];
        NSMutableArray<NSString *> *pathes = [NSMutableArray new];
        if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
            throwExecption;
        }
        while (SQLITE_ROW == sqlite3_step(stmt))
        {
            const unsigned char *text = sqlite3_column_text(stmt, 0);
            [pathes addObject:[NSString stringWithUTF8String:(const char *)text]];
        }
        if (SQLITE_OK != sqlite3_finalize(stmt)) {
            throwExecption;
        }//获取了一个表所有过期文件path
        
        SQL = [NSString stringWithFormat:@"delete from %@ where expire < %lld", tables[i], timeStamp];
        pthread_mutex_lock(&mutex);
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }//删除了一个表所有过期文件记录
        NSString *tableDir = [dataDir stringByAppendingPathComponent:tables[i]];
        for (signed long int j = 0, len = pathes.count; j < len; j++)
        {
            NSString *filePath = [tableDir stringByAppendingPathComponent:pathes[j]];
            [filemgr removeItemAtPath:filePath error:NULL];
        }//删除了一个文件夹所有过期文件
        SQL = [NSString stringWithFormat:@"select count(*) from %@", tables[i]];
        if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
            throwExecption;
        }
        if (SQLITE_ROW != sqlite3_step(stmt)) {
            throwExecption;
        }
        int recordCount = sqlite3_column_int(stmt, 0);
        if (SQLITE_OK != sqlite3_finalize(stmt)) {
            throwExecption;
        }
        if (0 == recordCount)
        {
            SQL = [NSString stringWithFormat:@"drop table %@", tables[i]];
            if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
                throwExecption;
            }//删除了一个空表
            [filemgr removeItemAtPath:tableDir error:NULL];//删除了一个空文件夹
            [tables removeObjectAtIndex:i--];
            cnt--;
        }
        pthread_mutex_unlock(&mutex);
    }
}

+ (void)appWillResignActive
{
    if (SQLITE_OK != sqlite3_close(dbHandler)) {
        throwExecption;
    }
}
+ (void)appBecomeActive
{
    if (SQLITE_OK != sqlite3_open([dbPath UTF8String], &dbHandler)) {
        throwExecption;
    }
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return nil;
}

@end
