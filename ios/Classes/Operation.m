//
//  Operation.m
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//

#import <Foundation/Foundation.h>
#import "Operation.h"
#import "SqflitePlugin.h"

// Abstract
@implementation Operation

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

@implementation BatchOperation

@synthesize dictionary, results, error, noResult;

- (NSString*)getMethod {
    return [dictionary objectForKey:_paramMethod];
}

- (NSString*)getSql {
    return [dictionary objectForKey:_paramSql];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = [dictionary objectForKey:_paramSqlArguments];
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

@implementation MethodCallOperation

@synthesize flutterMethodCall;
@synthesize flutterResult;

+ (MethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult {
    MethodCallOperation* operation = [MethodCallOperation new];
    operation.flutterMethodCall = flutterMethodCall;
    operation.flutterResult = flutterResult;
    return operation;
}

- (NSString*)getMethod {
    return flutterMethodCall.method;
}

- (NSString*)getSql {
    return flutterMethodCall.arguments[_paramSql];
}

- (bool)getNoResult {
    NSNumber* noResult = flutterMethodCall.arguments[_paramNoResult];
    return [noResult boolValue];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = flutterMethodCall.arguments[_paramSqlArguments];
    return [SqflitePlugin toSqlArguments:arguments];
}

- (void)success:(NSObject*)results {
    flutterResult(results);
}
- (void)error:(NSObject*)error {
    flutterResult(error);
}
@end
