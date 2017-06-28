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

@property (atomic, retain) FMDatabase *fmDatabase;
@property (atomic, retain) NSNumber *databaseId;
@property (atomic, retain) NSString* path;

@end

@implementation Database

@synthesize fmDatabase, databaseId;

@end

@implementation SqflitePlugin

BOOL _log = false;
BOOL _extra_log = false;

BOOL __extra_log = false; // to set to true for type debugging

NSInteger _lastDatabaseId = 0;
NSMutableDictionary<NSNumber*, Database*>* _databaseMap; // = [NSMutableDictionary new];
NSObject* _mapLock;

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
        _databaseMap = [NSMutableDictionary new];
        _mapLock = [NSObject new];
    }
    return self;
}

- (Database *)getDatabaseOrError:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* databaseId = call.arguments[_paramId];
    Database* database = _databaseMap[databaseId];
    if (database == nil) {
        NSLog(@"db not found.");
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message: _errorDatabaseClosed
                                   details:nil]);
        
    }
    return database;
}

- (void)handleQueryCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    NSString* sql = call.arguments[_paramSql];
    NSArray* arguments = call.arguments[_paramSqlArguments];
    NSArray* sqlArguments = [SqflitePlugin toSqlArguments:arguments];
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:arguments];;
    if (_log) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    FMResultSet *rs;
    if (!argumentsEmpty) {
        rs = [database.fmDatabase executeQuery:sql withArgumentsInArray:sqlArguments];
    } else {
        rs = [database.fmDatabase executeQuery:sql];
    }
    
    // handle error
    if ([self handleError:database result:result]) {
        return;
    }
    
    NSMutableArray* results = [NSMutableArray new];
    while ([rs next]) {
        [results addObject:[SqflitePlugin fromSqlDictionary:[rs resultDictionary]]];
    }
    result(results);
}

- (BOOL)handleError:(Database *)database result:(FlutterResult)result {
    // handle error
    if ([database.fmDatabase hadError]) {
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message:[NSString stringWithFormat:@"%@", [database.fmDatabase lastError]]
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

- (Database *)executeOrError:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return nil;
    }
    
    NSString* sql = call.arguments[_paramSql];
    NSArray* arguments = call.arguments[_paramSqlArguments];
    NSArray* sqlArguments = [SqflitePlugin toSqlArguments:arguments];
    BOOL argumentsEmpty = [SqflitePlugin arrayIsEmpy:arguments];
    if (_log) {
        NSLog(@"%@ %@", sql, argumentsEmpty ? @"" : sqlArguments);
    }
    
    if (!argumentsEmpty) {
        [database.fmDatabase executeUpdate: sql withArgumentsInArray: sqlArguments];
    } else {
        [database.fmDatabase executeUpdate: sql];
    }
    
    // handle error
    if ([self handleError:database result:result]) {
        return nil;
    }
    
    return database;
}

- (void)handleInsertCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self executeOrError:call result:result];
    if (database == nil) {
        return;
    }
    sqlite_int64 insertedId = [database.fmDatabase lastInsertRowId];
    if (_log) {
        NSLog(@"inserted %@", @(insertedId));
    }
    result(@(insertedId));
}

- (void)handleUpdateCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self executeOrError:call result:result];
    if (database == nil) {
        return;
    }
    int changes = [database.fmDatabase changes];
    if (_log) {
        NSLog(@"changed %@", @(changes));
    }
    result(@(changes));
}

- (void)handleExecuteCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self executeOrError:call result:result];
    if (database == nil) {
        return;
    }
    result(nil);
}

- (void)handleOpenDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* path = call.arguments[_paramPath];
    if (_log) {
        NSLog(@"opening %@", path);
    }
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        NSLog(@"Could not open db.");
        result([FlutterError errorWithCode:_sqliteErrorCode
                                   message:[NSString stringWithFormat:@"%@ %@", _errorOpenFailed, path]
                                   details:nil]);
        return;
    }
    
    NSNumber* databaseId;
    @synchronized (_mapLock) {
        Database* database = [Database new];
        databaseId = [NSNumber numberWithInteger:++_lastDatabaseId];
        database.fmDatabase = db;
        database.databaseId = databaseId;
        database.path = path;
        _databaseMap[databaseId] = database;
        
    }
    
    result(databaseId);
}

- (void)handleCloseDatabaseCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    
    if (_log) {
        NSLog(@"closing %@", database.path);
    }
    [database.fmDatabase close];
    @synchronized (_mapLock) {
        [_databaseMap removeObjectForKey:database.databaseId];
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
