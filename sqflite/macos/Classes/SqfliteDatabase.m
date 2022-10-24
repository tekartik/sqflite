#import "SqfliteDatabase.h"
#import "SqflitePlugin.h"

#import <sqlite3.h>

// iOS workaround bug #214
static NSString *const SqfliteSqlPragmaSqliteDefensiveOff = @"PRAGMA sqflite -- db_config_defensive_off";

static NSString *const _paramCursorPageSize = @"cursorPageSize";
static NSString *const _paramCursorId = @"cursorId";
static NSString *const _paramCancel = @"cancel";
// For batch
static NSString *const _paramOperations = @"operations";

// Import hidden method
@interface FMDatabase ()
- (void)resultSetDidClose:(FMResultSet *)resultSet;
@end

@implementation SqfliteDatabase

@synthesize databaseId;
@synthesize fmDatabaseQueue;
@synthesize cursorMap;
@synthesize logLevel;
@synthesize currentTransactionId;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cursorMap = [NSMutableDictionary new];
        self.lastCursorId = 0;
        self.lastTransactionId = 0;
        self.noTransactionOperationQueue = [NSMutableArray new];
    }
    return self;
}


- (void)inDatabase:(__attribute__((noescape)) void (^)(FMDatabase *db))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.fmDatabaseQueue inDatabase:block];
    });
}

- (void)dbHandleError:(FMDatabase*)db result:(FlutterResult)result {
    // handle error
    result([FlutterError errorWithCode:SqliteErrorCode
                               message:[NSString stringWithFormat:@"%@", [db lastError]]
                               details:nil]);
}

- (void)dbHandleError:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSMutableDictionary* details = nil;
    NSString* sql = [operation getSql];
    if (sql != nil) {
        details = [NSMutableDictionary new];
        [details setObject:sql forKey:SqfliteParamSql];
        NSArray* sqlArguments = [operation getSqlArguments];
        if (sqlArguments != nil) {
            [details setObject:sqlArguments forKey:SqfliteParamSqlArguments];
        }
    }
    
    [operation error:([FlutterError errorWithCode:SqliteErrorCode
                                          message:[NSString stringWithFormat:@"%@", [db lastError]]
                                          details:details])];
    
}

- (bool)dbExecute:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    if (![self dbExecuteOrError:db operation:operation]) {
        return false;
    }
    [operation success:[NSNull null]];
    return true;
}

- (bool)dbExecuteOrError:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSString* sql = [operation getSql];
    NSArray* sqlArguments = [operation getSqlArguments];
    NSNumber* inTransaction = [operation getInTransactionArgument];
    
    // Handle Hardcoded workarounds
    // Handle issue #525
    if ([SqfliteSqlPragmaSqliteDefensiveOff isEqualToString:sql]) {
        sqlite3_db_config(db.sqliteHandle, SQLITE_DBCONFIG_DEFENSIVE, 0, 0);
    }
    
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:sqlArguments];
    if (sqfliteHasSqlLogLevel(logLevel)) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    BOOL success;
    if (!argumentsEmpty) {
        success = [db executeUpdate: sql withArgumentsInArray: sqlArguments];
    } else {
        success = [db executeUpdate: sql];
    }
    
    // If wanted, we leave the transaction even if it fails
    if (inTransaction != nil) {
        if (![inTransaction boolValue]) {
            self.inTransaction = false;
        }
    }
    
    // handle error
    if (!success) {
        [self dbHandleError:db operation:operation];
        return false;
    }
    
    // We enter the transaction on success
    if (inTransaction != nil) {
        if ([inTransaction boolValue]) {
            self.inTransaction = true;
        }
    }
    
    return true;
}


//
// insert
//
- (bool)dbInsert:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    if (![self dbExecuteOrError:db operation:operation]) {
        return false;
    }
    if ([operation getNoResult]) {
        [operation success:[NSNull null]];
        return true;
    }
    // handle ON CONFLICT IGNORE (issue #164) by checking the number of changes
    // before
    int changes = [db changes];
    if (changes == 0) {
        if (sqfliteHasSqlLogLevel(self.logLevel)) {
            NSLog(@"no changes");
        }
        [operation success:[NSNull null]];
        return true;
    }
    sqlite_int64 insertedId = [db lastInsertRowId];
    if (sqfliteHasSqlLogLevel(self.logLevel)) {
        NSLog(@"inserted %@", @(insertedId));
    }
    [operation success:(@(insertedId))];
    return true;
}

- (bool)dbUpdate:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    if (![self dbExecuteOrError:db operation:operation]) {
        return false;
    }
    if ([operation getNoResult]) {
        [operation success:[NSNull null]];
        return true;
    }
    int changes = [db changes];
    if (sqfliteHasSqlLogLevel(self.logLevel)) {
        NSLog(@"changed %@", @(changes));
    }
    [operation success:(@(changes))];
    return true;
}

//
// query
//
- (bool)dbQuery:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSString* sql = [operation getSql];
    NSArray* sqlArguments = [operation getSqlArguments];
    bool argumentsEmpty = [SqflitePlugin arrayIsEmpy:sqlArguments];
    // Non null means use a cursor
    NSNumber* cursorPageSize = [operation getArgument:_paramCursorPageSize];
    
    if (sqfliteHasSqlLogLevel(self.logLevel)) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    FMResultSet *resultSet;
    if (!argumentsEmpty) {
        resultSet = [db executeQuery:sql withArgumentsInArray:sqlArguments];
    } else {
        // rs = [db executeQuery:sql];
        // This crashes on MacOS if there is any ? in the query
        // Workaround using an empty array
        resultSet = [db executeQuery:sql withArgumentsInArray:@[]];
    }
    
    // handle error
    if ([db hadError]) {
        [self dbHandleError:db operation:operation];
        return false;
    }
    
    NSMutableDictionary* results = [SqflitePlugin resultSetToResults:resultSet cursorPageSize:cursorPageSize];
    
    if (cursorPageSize != nil) {
        bool cursorHasMoreData = [resultSet hasAnotherRow];
        if (cursorHasMoreData) {
            NSNumber* cursorId = [NSNumber numberWithInt:++self.lastCursorId];
            SqfliteCursor* cursor = [SqfliteCursor new];
            cursor.cursorId = cursorId;
            cursor.pageSize = cursorPageSize;
            cursor.resultSet = resultSet;
            self.cursorMap[cursorId] = cursor;
            // Notify cursor support in the result
            results[_paramCursorId] = cursorId;
            // Prevent FMDB warning, we keep a result set open on purpose
            [db resultSetDidClose:resultSet];
        }
    }
    [operation success:results];
    
    return true;
}

//
// query
//
- (void)dbQueryCursorNext:(FMDatabase*)db operation:(SqfliteOperation*)operation {
    NSNumber* cursorId = [operation getArgument:_paramCursorId];
    NSNumber* cancelValue = [operation getArgument:_paramCancel];
    bool cancel = [cancelValue boolValue] == true;
    if (sqfliteHasVerboseLogLevel(self.logLevel))
    {            NSLog(@"queryCursorNext %@%s", cursorId, cancel ? " (cancel)" : "");
    }
    
    if (cancel) {
        [self closeCursorById:cursorId];
        [operation success:nil];
        return;
    } else {
        SqfliteCursor* cursor = self.cursorMap[cursorId];
        if (cursor == nil) {
            NSLog(@"cursor %@ not found.", cursorId);
            [operation success:[FlutterError errorWithCode:SqliteErrorCode
                                                   message: @"Cursor not found"
                                                   details:nil]];
            return;
        }
        FMResultSet* resultSet = cursor.resultSet;
        NSMutableDictionary* results = [SqflitePlugin resultSetToResults:resultSet cursorPageSize:cursor.pageSize];
        
        bool cursorHasMoreData = [resultSet hasAnotherRow];
        if (cursorHasMoreData) {
            // Keep the cursorId to specify that we have more data.
            results[_paramCursorId] = cursorId;
            // Prevent FMDB warning, we keep a result set open on purpose
            [db resultSetDidClose:resultSet];
        } else {
            [self closeCursor:cursor];
        }
        [operation success:results];
        
        
    }
}


- (void)dbBatch:(FMDatabase*)db operation:(SqfliteMethodCallOperation*)mainOperation {
    
    bool noResult = [mainOperation getNoResult];
    bool continueOnError = [mainOperation getContinueOnError];
    
    NSArray* operations = [mainOperation getArgument:_paramOperations];
    NSMutableArray* operationResults = [NSMutableArray new];
    for (NSDictionary* dictionary in operations) {
        // do something with object
        
        SqfliteBatchOperation* operation = [SqfliteBatchOperation new];
        operation.dictionary = dictionary;
        operation.noResult = noResult;
        
        NSString* method = [operation getMethod];
        if ([SqfliteMethodInsert isEqualToString:method]) {
            if ([self dbInsert:db operation:operation]) {
                [operation handleSuccess:operationResults];
            } else if (continueOnError) {
                [operation handleErrorContinue:operationResults];
            } else {
                [operation handleError:mainOperation.flutterResult];
                return;
            }
        } else if ([SqfliteMethodUpdate isEqualToString:method]) {
            if ([self dbUpdate:db operation:operation]) {
                [operation handleSuccess:operationResults];
            } else if (continueOnError) {
                [operation handleErrorContinue:operationResults];
            } else {
                [operation handleError:mainOperation.flutterResult];
                return;
            }
        } else if ([SqfliteMethodExecute isEqualToString:method]) {
            if ([self dbExecute:db operation:operation]) {
                [operation handleSuccess:operationResults];
            } else if (continueOnError) {
                [operation handleErrorContinue:operationResults];
            } else {
                [operation handleError:mainOperation.flutterResult];
                return;
            }
        } else if ([SqfliteMethodQuery isEqualToString:method]) {
            if ([self dbQuery:db operation:operation]) {
                [operation handleSuccess:operationResults];
            } else if (continueOnError) {
                [operation handleErrorContinue:operationResults];
            } else {
                [operation handleError:mainOperation.flutterResult];
                return;
            }
        } else {
            [mainOperation success:[FlutterError errorWithCode:SqfliteErrorBadParam
                                                       message:[NSString stringWithFormat:@"Batch method '%@' not supported", method]
                                                       details:nil]];
            return;
        }
    }
    
    if (noResult) {
        [mainOperation success:nil];
    } else {
        [mainOperation success:operationResults];
    }
    
}
- (void)closeCursorById:(NSNumber*)cursorId {
    SqfliteCursor* cursor = cursorMap[cursorId];
    if (cursor != nil) {
        [self closeCursor:cursor];
    }
}

- (void)closeCursor:(SqfliteCursor*)cursor {
    NSNumber* cursorId = cursor.cursorId;
    if (sqfliteHasVerboseLogLevel(logLevel)) {
        NSLog(@"closing cursor %@", cursorId);
    }
    [cursorMap removeObjectForKey:cursorId];
    [cursor.resultSet close];
}

@end
