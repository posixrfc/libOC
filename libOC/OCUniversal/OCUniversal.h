#ifdef DEBUG
#define throwExecption [NSException raise:@(__FUNCTION__) format:@"%s %i", __FILE__, __LINE__]
#define funcInfo NSLog(@"%s %s %i", __FUNCTION__, __FILE__, __LINE__)
#else
#define throwExecption
#define funcInfo
#endif
