//
//  Operation.m
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//

#import <Foundation/Foundation.h>
#import "SqfliteOperation.h"
#import "SqflitePlugin.h"

// Abstract
@implementation SqfliteOperation

- (NSString*)getMethod {
    return  nil;
}
- (NSString*)getSql {
    return nil;
}
- (NSArray*)getSqlArguments {
    return nil;
}
- (bool)getNoResult {
    return false;
}
- (void)success:(NSObject*)results {}

- (void)error:(NSObject*)error {}

@end

@implementation SqfliteBatchOperation

@synthesize dictionary, results, error, noResult;

- (NSString*)getMethod {
    return [dictionary objectForKey:SqfliteParamMethod];
}

- (NSString*)getSql {
    return [dictionary objectForKey:SqfliteParamSql];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = [dictionary objectForKey:SqfliteParamSqlArguments];
    return [SqflitePlugin toSqlArguments:arguments];
}

- (bool)getNoResult {
    return noResult;
}

- (void)success:(NSObject*)results {
    self.results = results;
}
- (void)error:(NSObject*)error {
    self.error = error;
}

- (void)handleSuccess:(NSMutableArray*)results {
    if (![self getNoResult]) {
        [results addObject:((self.results == nil) ? [NSNull null] : self.results)];
    }
}
- (void)handleError:(FlutterResult)result {
    result(error);
}

@end

@implementation SqfliteMethodCallOperation

@synthesize flutterMethodCall;
@synthesize flutterResult;

+ (SqfliteMethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult {
    SqfliteMethodCallOperation* operation = [SqfliteMethodCallOperation new];
    operation.flutterMethodCall = flutterMethodCall;
    operation.flutterResult = flutterResult;
    return operation;
}

- (NSString*)getMethod {
    return flutterMethodCall.method;
}

- (NSString*)getSql {
    return flutterMethodCall.arguments[SqfliteParamSql];
}

- (bool)getNoResult {
    NSNumber* noResult = flutterMethodCall.arguments[SqfliteParamNoResult];
    return [noResult boolValue];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = flutterMethodCall.arguments[SqfliteParamSqlArguments];
    return [SqflitePlugin toSqlArguments:arguments];
}

- (void)success:(NSObject*)results {
    flutterResult(results);
}
- (void)error:(NSObject*)error {
    flutterResult(error);
}
@end
