#import "NSCachePool.h"

typedef NS_ENUM(unsigned char, StorageType) {
    StorageTypeNone = 0,         // slow at beginning and end
    StorageTypeObject,            // slow at beginning
    StorageTypeString,           // slow at end
    StorageTypeData
};

static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *pool = nil;
static NSString *general_key = nil;

static NSFileManager *filemgr = nil;
static sqlite3 *dbHandler;
static NSString *dbPath;
static NSString *dataDir;
static pthread_mutex_t mutex;
static NSMutableArray<NSString *> *tables;

@implementation NSCachePool

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
    NSString *SQL = [NSString stringWithFormat:@"select `path`, `expire` from `%@`", group_id];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    NSMutableArray<NSString *> *validKeys = [NSMutableArray new];
    NSMutableArray<NSString *> *expireKeys = [NSMutableArray new];
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    while (SQLITE_ROW == sqlite3_step(stmt))
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        NSString *key = [NSString stringWithUTF8String:(const char *)text];
        sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        if (queryTimestamp > currentTimestamp)
        {
            [validKeys addObject:key];
        }
        else
        {
            [expireKeys addObject:key];
        }
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from `%@` where path in (", group_id];
    pthread_mutex_lock(&mutex);
    for (long i = 0, len = expireKeys.count; i < len; i++)
    {
        [sql appendFormat:@", '%@'", expireKeys[i]];
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:expireKeys[i]];
        if ([filemgr fileExistsAtPath:SQL]) {
            [filemgr removeItemAtPath:SQL error:NULL];
        }
    }
    if (![sql hasSuffix:@"("])
    {
        [sql appendString:@")"];
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }
    }
    pthread_mutex_unlock(&mutex);
    return 0 == validKeys.count ? nil : validKeys;
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
    NSString *SQL = [NSString stringWithFormat:@"select * from `%@`", group_id];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    NSMutableArray<NSString *> *validKeys = [NSMutableArray new];
    NSMutableArray<NSString *> *expirekeys = [NSMutableArray new];
    NSMutableArray<NSNumber *> *validTypes = [NSMutableArray new];
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    while (SQLITE_ROW == sqlite3_step(stmt))
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        NSString *key = [NSString stringWithUTF8String:(const char *)text];
        sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        unsigned char type = sqlite3_column_int(stmt, 2);
        if (queryTimestamp > currentTimestamp)
        {
            [validKeys addObject:key];
            [validTypes addObject:@(type)];
        }
        else
        {
            [expirekeys addObject:key];
        }
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from `%@` where `path` in (", group_id];
    pthread_mutex_lock(&mutex);
    for (long i = 0, len = expirekeys.count; i < len; i++)
    {
        [sql appendFormat:@", '%@'", expirekeys[i]];
        SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:expirekeys[i]];
        if ([filemgr fileExistsAtPath:SQL]) {
            [filemgr removeItemAtPath:SQL error:NULL];
        }
    }
    if (![sql hasSuffix:@"("])
    {
        [sql appendString:@")"];
        if (SQLITE_OK != sqlite3_exec(dbHandler, [sql UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }
    }
    pthread_mutex_unlock(&mutex);
    long key_count = validKeys.count;
    if (0 == key_count) {
        return nil;
    }
    NSMutableArray<id<NSCoding>> *values = [NSMutableArray arrayWithCapacity:key_count];
    NSString *tmp = [dataDir stringByAppendingPathComponent:group_id];
    for (long i = 0; i < key_count; i++)
    {
        SQL = [tmp stringByAppendingPathComponent:validKeys[i]];
        switch ([validTypes[i] shortValue])
        {
            case StorageTypeData:
                [values addObject:[NSData dataWithContentsOfFile:SQL]];
                break;
                
            case StorageTypeString:
                [values addObject:[NSString stringWithContentsOfFile:SQL encoding:NSUTF8StringEncoding error:NULL]];
                break;
                
            case StorageTypeNone:
            case StorageTypeObject:
                [values addObject:[NSKeyedUnarchiver unarchiveObjectWithFile:SQL]];
                break;
                
            default:
                throwExecption;
        }
    }
    return values;
}
+ (void)diskClearPool
{
    pthread_mutex_lock(&mutex);
    if (SQLITE_OK != sqlite3_close(dbHandler)) {
        throwExecption;
    }
    if ([filemgr fileExistsAtPath:dataDir])
    {
        if (![filemgr removeItemAtPath:dataDir error:NULL]) {
            throwExecption;
        }
    }
    if ([filemgr createDirectoryAtPath:dataDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
        throwExecption;
    }
    if ([filemgr createFileAtPath:dbPath contents:nil attributes:nil]) {
        throwExecption;
    }
    [tables removeAllObjects];
    if (SQLITE_OK != sqlite3_open([dbPath UTF8String], &dbHandler)) {
        throwExecption;
    }
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
    pthread_mutex_lock(&mutex);
    if ([filemgr fileExistsAtPath:tableFolder]) {
        [filemgr removeItemAtPath:tableFolder error:NULL];
    }
    NSString *SQL = [NSString stringWithFormat:@"drop table `%@`", group_id];
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    [tables removeObjectAtIndex:idx];
    pthread_mutex_unlock(&mutex);
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID
{
    [self diskSetValue:value withKey:key inGroup:ID duration:LONG_LONG_MAX];
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID duration:(signed long long int)seconds
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
        if ([filemgr fileExistsAtPath:SQL]) {
            [filemgr removeItemAtPath:SQL error:NULL];
        }
        pthread_mutex_lock(&mutex);
        BOOL isDir;
        BOOL isExists = [filemgr fileExistsAtPath:SQL isDirectory:&isDir];
        if (isExists && !isDir) {
            throwExecption;
        }
        if (!isExists)
        {
            if (![filemgr createDirectoryAtPath:SQL withIntermediateDirectories:YES attributes:nil error:NULL]) {
                throwExecption;
            }
        }
        SQL = [NSString stringWithFormat:@"create table if not exists `%@`(`path` text primary key unique not null, `expire` integer not null, `type` integer not null)", group_id];
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
    StorageType type = StorageTypeNone;
    if ([(id)value isKindOfClass:[NSString class]])
    {
        type = StorageTypeString;
    }
    else if ([(id)value isKindOfClass:[NSData class]])
    {
        type = StorageTypeData;
    }
    else
    {
        type = StorageTypeObject;
    }
    pthread_mutex_lock(&mutex);
    switch (type)
    {
        case StorageTypeNone:
        case StorageTypeObject:
            if (![NSKeyedArchiver archiveRootObject:value toFile:SQL]) {
                throwExecption;
            }
            break;
            
        case StorageTypeData:
            [(NSData *)value writeToFile:SQL atomically:YES];
            break;
            
        case StorageTypeString:
            [(NSString *)value writeToFile:SQL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
            break;
            
        default:
            throwExecption;
    }
    SQL = [NSString stringWithFormat:@"replace into `%@`(`path`, `expire`, `type`) values('%@', %lld, %hhu)", group_id, key, queryTimestamp, type];
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    pthread_mutex_unlock(&mutex);
}
+ (void)diskSetValue:(id<NSCoding>)value withKey:(NSString *)key inGroup:(nullable NSString *)ID expireDate:(nullable NSDate *)expire
{
    const sqlite3_int64 currentTimestamp = [[NSDate date] timeIntervalSince1970];
    const sqlite3_int64 queryTimestamp = [expire timeIntervalSince1970];
    const sqlite3_int64 offsetTimestamp = queryTimestamp - currentTimestamp;
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
    NSString *SQL = [NSString stringWithFormat:@"select * from `%@` where `path` = '%@'", group_id, key];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
        throwExecption;
    }
    if (SQLITE_ROW == sqlite3_step(stmt))
    {
        const sqlite3_int64 queryTimestamp = sqlite3_column_int64(stmt, 1);
        StorageType type = sqlite3_column_int(stmt, 2);
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
            SQL = [NSString stringWithFormat:@"delete from `%@` where `path` = '%@'", group_id, key];
            if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
                throwExecption;
            }
            return nil;
        }
        switch (type)
        {
            case StorageTypeNone:
            case StorageTypeObject:
                return [NSKeyedUnarchiver unarchiveObjectWithFile:SQL];
                
            case StorageTypeString:
                return [NSString stringWithContentsOfFile:SQL encoding:NSUTF8StringEncoding error:NULL];
                
            case StorageTypeData:
                return [NSData dataWithContentsOfFile:SQL];
                
            default:
                throwExecption;
        }
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
    NSString *SQL = [NSString stringWithFormat:@"delete from `%@` where `path` = '%@'", group_id, key];
    pthread_mutex_lock(&mutex);
    if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
        throwExecption;
    }
    SQL = [[dataDir stringByAppendingPathComponent:group_id] stringByAppendingPathComponent:key];
    if ([filemgr fileExistsAtPath:SQL]) {
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

+ (void)prepare{}
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
        if (isDir)// 存在此目录
        {
            if (![filemgr removeItemAtPath:dbPath error:NULL]) {
                throwExecption;
            }
            if (![filemgr createFileAtPath:dbPath contents:nil attributes:nil]) {
                throwExecption;
            }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:@"UIApplicationWillTerminateNotification" object:nil];
    sqlite3_stmt *stmt = NULL;
    if (SQLITE_OK != sqlite3_prepare(dbHandler, "select tbl_name from sqlite_master where type = 'table'", -1, &stmt, NULL)) {
        throwExecption;
    }
    while (SQLITE_ROW == sqlite3_step(stmt))// 获取所有表名
    {
        const unsigned char *text = sqlite3_column_text(stmt, 0);
        [tables addObject:[NSString stringWithUTF8String:(const char *)text]];
    }
    if (SQLITE_OK != sqlite3_finalize(stmt)) {
        throwExecption;
    }
    const sqlite3_int64 currentTimeStamp = [[NSDate date] timeIntervalSince1970];
    for (signed long int i = 0, cnt = tables.count; i < cnt; i++)
    {
        NSString *SQL = [NSString stringWithFormat:@"select path from `%@` where expire < %lld", tables[i], currentTimeStamp];
        NSMutableArray<NSString *> *pathes = [NSMutableArray new];
        if (SQLITE_OK != sqlite3_prepare(dbHandler, [SQL UTF8String], -1, &stmt, NULL)) {
            throwExecption;
        }
        while (SQLITE_ROW == sqlite3_step(stmt))//获取了一个表所有过期文件path
        {
            const unsigned char *text = sqlite3_column_text(stmt, 0);
            [pathes addObject:[NSString stringWithUTF8String:(const char *)text]];
        }
        if (SQLITE_OK != sqlite3_finalize(stmt)) {
            throwExecption;
        }
        SQL = [NSString stringWithFormat:@"delete from `%@` where expire < %lld", tables[i], currentTimeStamp];
        pthread_mutex_lock(&mutex);
        if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
            throwExecption;
        }//删除了一个表所有过期文件记录
        NSString *tableDir = [dataDir stringByAppendingPathComponent:tables[i]];
        for (signed long int j = 0, len = pathes.count; j < len; j++)
        {
            NSString *filePath = [tableDir stringByAppendingPathComponent:pathes[j]];
            if ([filemgr fileExistsAtPath:filePath]) {
                [filemgr removeItemAtPath:filePath error:NULL];
            }
        }//删除了一个文件夹所有过期文件
        SQL = [NSString stringWithFormat:@"select count(*) from `%@`", tables[i]];
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
            SQL = [NSString stringWithFormat:@"drop table `%@`", tables[i]];
            if (SQLITE_OK != sqlite3_exec(dbHandler, [SQL UTF8String], NULL, NULL, NULL)) {
                throwExecption;
            }//删除了一个空表
            if ([filemgr fileExistsAtPath:tableDir]) {
                [filemgr removeItemAtPath:tableDir error:NULL];//删除了一个空文件夹
            }
            [tables removeObjectAtIndex:i--];
            cnt--;
        }
        pthread_mutex_unlock(&mutex);
    }
}

+ (void)appWillTerminate
{
    if (SQLITE_OK != sqlite3_close(dbHandler)) {
        throwExecption;
    }
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    throwExecption;
    return nil;
}

@end
