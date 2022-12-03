#import "SqfliteCursor.h"

#if __has_include(<fmdb/FMDB.h>)
#import <fmdb/FMDB.h>
#else
@import FMDB;
#endif

@implementation SqfliteCursor

@synthesize cursorId;
@synthesize pageSize;
@synthesize resultSet;

@end
