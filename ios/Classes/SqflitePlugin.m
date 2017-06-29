#import "SqflitePlugin.h"
#import "FMDB.h"
#import <sqlite3.h>

NSString *const _methodGetPlatformVersion = @"getPlatformVersion";
NSString *const _methodDebugMode = @"debugMode";
NSString *const _methodOpenDatabase = @"openDatabase";
NSString *const _methodCloseDatabase = @"closeDatabase";
NSString *const _methodExecute = @"execute";
NSString *const _methodInsert = @"insert";
NSString *const _methodUpdate = @"update";
NSString *const _methodQuery = @"query";

NSString *const _paramPath = @"path";
NSString *const _paramId = @"id";
NSString *const _paramSql = @"sql";
NSString *const _paramSqlArguments = @"arguments";
NSString *const _paramTable = @"table";
NSString *const _paramValues = @"values";

NSString *const _sqliteErrorCode = @"sqlite_error";
NSString *const _errorOpenFailed = @"open_failed";
NSString *const _errorDatabaseClosed = @"database_closed";

@interface Database : NSObject

@property (atomic, retain) FMDatabaseQueue *fmDatabaseQueue;
@property (atomic, retain) NSNumber *databaseId;
@property (atomic, retain) NSString* path;

@end

@interface SqflitePlugin ()

@property (atomic, retain) NSMutableDictionary<NSNumber*, Database*>* databaseMap; // = [NSMutableDictionary new];
@property (atomic, retain) NSObject* mapLock;
@property (atomic, retain) NSOperationQueue *operationQueue;

@end

@implementation Database

@synthesize databaseId;
@synthesize fmDatabaseQueue;

@end

@implementation SqflitePlugin

@synthesize databaseMap;
@synthesize mapLock;
@synthesize operationQueue;

BOOL _log = false;
BOOL _extra_log = false;

BOOL __extra_log = false; // to set to true for type debugging

NSInteger _lastDatabaseId = 0;
NSInteger _databaseOpenCount = 0;


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.tekartik.sqflite"
                                     binaryMessenger:[registrar messenger]];
    SqflitePlugin* instance = [[SqflitePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.databaseMap = [NSMutableDictionary new];
        self.mapLock = [NSObject new];
    }
    return self;
}

- (Database *)getDatabaseOrError:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* databaseId = call.arguments[_paramId];
    Database* database = self.databaseMap[databaseId];
    if (database == nil) {
        NSLog(@"db not found.");
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message: _errorDatabaseClosed
                                   details:nil]);
        
    }
    return database;
}

- (BOOL)handleError:(FMDatabase*)db result:(FlutterResult)result {
    // handle error
    if ([db hadError]) {
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message:[NSString stringWithFormat:@"%@", [db lastError]]
                                   details:nil]);
        return YES;
    }
    return NO;
}

+ (NSObject*)toSqlValue:(NSObject*)value {
    if (_extra_log) {
        NSLog(@"value type %@ %@", [value class], value);
    }
    if (value == nil) {
        return nil;
    } else if ([value isKindOfClass:[FlutterStandardTypedData class]]) {
        FlutterStandardTypedData* typedData = (FlutterStandardTypedData*)value;
        return [typedData data];
    } else if ([value isKindOfClass:[NSArray class]]) {
        // Assume array of number
        // slow...to optimize
        NSArray* array = (NSArray*)value;
        NSMutableData* data = [NSMutableData new];
        for (int i = 0; i < [array count]; i++) {
            uint8_t byte = [((NSNumber *)[array objectAtIndex:i]) intValue];
            [data appendBytes:&byte length:1];
        }
        return data;
    } else {
        return value;
    }
}

+ (NSObject*)fromSqlValue:(NSObject*)sqlValue {
    if (_extra_log) {
        NSLog(@"sql value type %@ %@", [sqlValue class], sqlValue);
    }
    if (sqlValue == nil) {
        return nil;
    } else if ([sqlValue isKindOfClass:[NSData class]]) {
        return [FlutterStandardTypedData typedDataWithBytes:(NSData*)sqlValue];
    } else {
        return sqlValue;
    }
}

+ (bool)arrayIsEmpy:(NSArray*)array {
    return (array == nil || array == (id)[NSNull null] || [array count] == 0);
}

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments {
    NSMutableArray* array = [NSMutableArray new];
    if (![SqflitePlugin arrayIsEmpy:rawArguments]) {
        for (int i = 0; i < [rawArguments count]; i++) {
            [array addObject:[SqflitePlugin toSqlValue:[rawArguments objectAtIndex:i]]];
        }
    }
    return array;
}

+ (NSDictionary*)fromSqlDictionary:(NSDictionary*)sqlDictionary {
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    for (NSString* key in sqlDictionary.keyEnumerator) {
        NSObject* sqlValue = [sqlDictionary objectForKey:key];
        [dictionary setObject:[SqflitePlugin fromSqlValue:sqlValue] forKey:key];
    }
    return dictionary;
}

- (bool)executeOrError:(FMDatabase*)db call:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* sql = call.arguments[_paramSql];
    NSArray* arguments = call.arguments[_paramSqlArguments];
    NSArray* sqlArguments = [SqflitePlugin toSqlArguments:arguments];
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:arguments];
    if (_log) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    if (!argumentsEmpty) {
        [db executeUpdate: sql withArgumentsInArray: sqlArguments];
    } else {
        [db executeUpdate: sql];
    }
    
    // handle error
    if ([self handleError:db result:result]) {
        return false;
    }
    
    return true;
}

//
// query
//
- (void)handleQueryCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        [database.fmDatabaseQueue inDatabase:^(FMDatabase *db) {
            NSString* sql = call.arguments[_paramSql];
            NSArray* arguments = call.arguments[_paramSqlArguments];
            NSArray* sqlArguments = [SqflitePlugin toSqlArguments:arguments];
            BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:arguments];;
            if (_log) {
                NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
            }
            FMResultSet *rs;
            if (!argumentsEmpty) {
                rs = [db executeQuery:sql withArgumentsInArray:sqlArguments];
            } else {
                rs = [db executeQuery:sql];
            }
            
            // handle error
            if ([self handleError:db result:result]) {
                return;
            }
            
            NSMutableArray* results = [NSMutableArray new];
            while ([rs next]) {
                [results addObject:[SqflitePlugin fromSqlDictionary:[rs resultDictionary]]];
            }
            result(results);
        }];
    }];
}

//
// insert
//
- (void)handleInsertCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        [database.fmDatabaseQueue inDatabase:^(FMDatabase *db) {
            if (![self executeOrError:db call:call result:result]) {
                return;
            }
            sqlite_int64 insertedId = [db lastInsertRowId];
            if (_log) {
                NSLog(@"inserted %@", @(insertedId));
            }
            result(@(insertedId));
        }];
    }];
}

//
// update
//
- (void)handleUpdateCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        [database.fmDatabaseQueue inDatabase:^(FMDatabase *db) {
            if (![self executeOrError:db call:call result:result]) {
                return;
            }
            
            int changes = [db changes];
            if (_log) {
                NSLog(@"changed %@", @(changes));
            }
            result(@(changes));
        }];
    }];
}

//
// execute
//
- (void)handleExecuteCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        [database.fmDatabaseQueue inDatabase:^(FMDatabase *db) {
            if (![self executeOrError:db call:call result:result]) {
                return;
            }
            
            result(nil);
        }];
    }];
    
}

//
// open
//
- (void)handleOpenDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* path = call.arguments[_paramPath];
    if (_log) {
        NSLog(@"opening %@", path);
    }
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:path];
    bool success = queue != nil;
    
    if (!success) {
        NSLog(@"Could not open db.");
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message:[NSString stringWithFormat:@"%@ %@", _errorOpenFailed, path]
                                   details:nil]);
        return;
    }
    
    NSNumber* databaseId;
    @synchronized (self.mapLock) {
        Database* database = [Database new];
        databaseId = [NSNumber numberWithInteger:++_lastDatabaseId];
        database.fmDatabaseQueue = queue;
        database.databaseId = databaseId;
        database.path = path;
        self.databaseMap[databaseId] = database;
        if (_databaseOpenCount++ == 0) {
            if (_log) {
                NSLog(@"Creating operation queue");
                self.operationQueue = [NSOperationQueue new];
            }
        }
        
    }
    
    result(databaseId);
}

//
// close
//
- (void)handleCloseDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    if (_log) {
        NSLog(@"closing %@", database.path);
    }
    [database.fmDatabaseQueue close];
    
    @synchronized (self.mapLock) {
        [self.databaseMap removeObjectForKey:database.databaseId];
        if (--_databaseOpenCount == 0) {
            if (_log) {
                NSLog(@"Deleting operation queue");
                self.operationQueue = nil;
            }
        }
    }
    result(nil);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([_methodGetPlatformVersion isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([_methodOpenDatabase isEqualToString:call.method]) {
        [self handleOpenDatabaseCall:call result:result];
    } else if ([_methodInsert isEqualToString:call.method]) {
        [self handleInsertCall:call result:result];
    } else if ([_methodQuery isEqualToString:call.method]) {
        [self handleQueryCall:call result:result];
    } else if ([_methodUpdate isEqualToString:call.method]) {
        [self handleUpdateCall:call result:result];
    } else if ([_methodExecute isEqualToString:call.method]) {
        [self handleExecuteCall:call result:result];
    } else if ([_methodCloseDatabase isEqualToString:call.method]) {
        [self handleCloseDatabaseCall:call result:result];
    } else if ([_methodDebugMode isEqualToString:call.method]) {
        NSNumber* on = (NSNumber*)call.arguments;
        _log = [on boolValue];
        NSLog(@"Debug mode %d", _log);
        _extra_log = __extra_log && _log;
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
