#ifndef __lib_OC__
#define __lib_OC__

#import <Availability.h>
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>


#if !__has_feature(objc_arc)
#warning Automatic Reference Counting is required
#endif

#if !__has_include(<sqlite3.h>)
#error SQLite(sqlite3.0) is required
#endif

#import <libOC/OCUniversal.h>
#import <libOC/UIDispatcher.h>
#import <libOC/NSCachePool.h>

//! Project version number for libOC.
FOUNDATION_EXPORT double libOCVersionNumber;

//! Project version string for libOC.
FOUNDATION_EXPORT const unsigned char libOCVersionString[];

#endif
