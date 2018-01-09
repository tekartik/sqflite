//
//  Operation.h
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//
#import <Flutter/Flutter.h>

#ifndef Operation_h
#define Operation_h

@interface Operation : NSObject

- (NSString*)getMethod;
- (NSString*)getSql;
- (NSArray*)getSqlArguments;
- (void)success:(NSObject*)results;
- (void)error:(NSObject*)error;
- (bool)getNoResult;

@end

@interface BatchOperation : Operation

@property (atomic, retain) NSDictionary* dictionary;
@property (atomic, retain) NSObject* results;
@property (atomic, retain) NSObject* error;
@property (atomic, assign) bool noResult;

- (void)handleSuccess:(NSMutableArray*)results;
- (void)handleError:(FlutterResult)result;

@end

@interface MethodCallOperation : Operation

@property (atomic, retain) FlutterMethodCall* flutterMethodCall;
@property (atomic, assign) FlutterResult flutterResult;

+ (MethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult;

@end

#endif /* Operation_h */
