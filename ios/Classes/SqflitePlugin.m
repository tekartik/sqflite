#import "SqflitePlugin.h"
#import "FMDB.h"
#import <sqlite3.h>

NSString *const _methodOpenDatabase = @"openDatabase";
NSString *const _methodCloseDatabase = @"closeDatabase";
NSString *const _methodExecute = @"execute";
NSString *const _methodInsert = @"insert";
NSString *const _methodUpdate = @"update";
NSString *const _methodQuery = @"query";

NSString *const _paramPath = @"path";
NSString *const _paramVersion = @"version"; // int
NSString *const _paramId = @"id";
NSString *const _paramSql = @"sql";
NSString *const _paramSqlArguments = @"arguments";
NSString *const _paramTable = @"table";
NSString *const _paramValues = @"values";

@interface Database : NSObject

@property (atomic, retain) FMDatabase *fmDatabase;

@end

@implementation Database

@synthesize fmDatabase;

@end

@implementation SqflitePlugin

BOOL _log = true;
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
        result([FlutterError errorWithCode:@"Error"
                                   message:@"db not found"
                                   details:nil]);
        
    }
    return database;
}

- (void)handleInsertSmart:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* databaseId = call.arguments[_paramId];
    NSString* table = call.arguments[_paramTable];
    NSDictionary* values = call.arguments[_paramValues];
    Database* database = _databaseMap[databaseId];
    if (database == nil) {
        NSLog(@"db not found.");
        result([FlutterError errorWithCode:@"Error"
                                   message:@"db not found"
                                   details:nil]);
        
    }
    NSMutableArray* arguments = [NSMutableArray new];
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO %@", table];
    if (values != nil && values.count > 0) {
        NSString* params = @"(";
        NSMutableArray *paramValues = [NSMutableArray new];
        sql = [sql stringByAppendingString: @" ("];
        
        for (NSString* key in values.keyEnumerator) {
            NSObject* value = values[key];
            if (paramValues.count > 0) {
                params = [params stringByAppendingString:@", "];
                sql = [sql stringByAppendingString:@", "];
            }
            params = [params stringByAppendingString:@"?"];
            [paramValues addObject:value];
            sql = [sql stringByAppendingString:key];
        }
        sql = [[[sql stringByAppendingString:@ ") VALUES "] stringByAppendingString:params] stringByAppendingString:@")"];
        [database.fmDatabase executeUpdate: sql withArgumentsInArray: paramValues];
    } else {
        [database.fmDatabase executeUpdate: sql];
    }
    sqlite_int64 insertedId = [database.fmDatabase lastInsertRowId];
    if (_log) {
        NSLog(@"Sqflite: inserted %@", [NSNumber numberWithLong:insertedId]);
    }
    result(@(insertedId));
}


- (void)handleQueryCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return;
    }
    NSString* sql = call.arguments[_paramSql];
    NSArray* arguments = call.arguments[_paramSqlArguments];
    FMResultSet *rs = [database.fmDatabase executeQuery:sql withArgumentsInArray:arguments];
    NSMutableArray* results = [NSMutableArray new];
    while ([rs next]) {
        [results addObject:[rs resultDictionary]];
    }
    result(results);
}

- (Database *)executeOrError:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self getDatabaseOrError:call result:result];
    if (database == nil) {
        return nil;
    }
    
    NSString* sql = call.arguments[_paramSql];
    NSArray* arguments = call.arguments[_paramSqlArguments];
    if (_log) {
        NSLog(@"Sqflite: %@ %@", sql, arguments);
    }
    if (arguments != nil) {
        [database.fmDatabase executeUpdate: sql withArgumentsInArray: arguments];
    } else {
        [database.fmDatabase executeUpdate: sql];
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
        NSLog(@"Sqflite: inserted %@", [NSNumber numberWithLongLong:insertedId]);
    }
    result([NSNumber numberWithLongLong:insertedId]);
}

- (void)handleUpdateCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Database* database = [self executeOrError:call result:result];
    if (database == nil) {
        return;
    }
    int changes = [database.fmDatabase changes];
    if (_log) {
        NSLog(@"Sqflite: changed %@", @(changes));
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

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([_methodOpenDatabase isEqualToString:call.method]) {
        
        NSString* path = call.arguments[_paramPath];
        NSNumber* version = call.arguments[_paramVersion];
        FMDatabase *db = [FMDatabase databaseWithPath:path];
        if (![db open]) {
            NSLog(@"Could not open db.");
            result([FlutterError errorWithCode:@"Error"
                                       message:@"Cannot open db"
                                       details:nil]);
            return;
        }
        
        NSInteger databaseId;
        @synchronized (_mapLock) {
            Database* database = [Database new];
            database.fmDatabase = db;
            databaseId = ++_lastDatabaseId;
            _databaseMap[[NSNumber numberWithInteger:databaseId]] = database;
            
        }
        
        result([NSNumber numberWithInteger:databaseId]);
        
      /*
    } else if ([_methodExecute isEqualToString:call.method]) {
        
        NSNumber* databaseId = call.arguments[_paramId];
        NSString* sql = call.arguments[_paramSql];
        //NSString* arguments = call.arguments[_paramSqlArguments];
        Database* database = _databaseMap[databaseId];
        if (database == nil) {
            NSLog(@"db not found.");
            result([FlutterError errorWithCode:@"Error"
                                       message:@"db not found"
                                       details:nil]);
            
        }
        [database.fmDatabase executeUpdate: sql];
        result(nil);
       */
    } else if ([_methodInsert isEqualToString:call.method]) {
        [self handleInsertCall:call result:result];
        
    } else if ([_methodQuery isEqualToString:call.method]) {
        
        [self handleQueryCall:call result:result];
        
    } else if ([_methodUpdate isEqualToString:call.method]) {
        [self handleUpdateCall:call result:result];
        
    } else if ([_methodExecute isEqualToString:call.method]) {
        [self handleExecuteCall:call result:result];
        
    } else if ([_methodCloseDatabase isEqualToString:call.method]) {
        
        NSNumber* databaseId = call.arguments[_paramId];
        //NSString* arguments = call.arguments[_paramSqlArguments];
        Database* database = _databaseMap[databaseId];
        if (database == nil) {
            NSLog(@"db not found.");
            result([FlutterError errorWithCode:@"Error"
                                       message:@"db not found"
                                       details:nil]);
            
        }
        [database.fmDatabase close];
        @synchronized (_mapLock) {
            [_databaseMap removeObjectForKey:databaseId];
        }
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
