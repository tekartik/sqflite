//
//  Operation.h
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//
#import "SqflitePlugin.h"

#ifndef SqfliteOperation_h
#define SqfliteOperation_h

@interface SqfliteOperation : NSObject

- (NSString*)getMethod;
- (NSString*)getSql;
- (NSArray*)getSqlArguments;
- (NSNumber*)getInTransactionArgument;
- (void)success:(NSObject*)results;
- (void)error:(FlutterError*)error;
- (bool)getNoResult;
- (bool)getContinueOnError;

@end

@interface SqfliteBatchOperation : SqfliteOperation

@property (atomic, retain) NSDictionary* dictionary;
@property (atomic, retain) NSObject* results;
@property (atomic, retain) FlutterError* error;
@property (atomic, assign) bool noResult;
@property (atomic, assign) bool continueOnError;

- (void)handleSuccess:(NSMutableArray*)results;
- (void)handleErrorContinue:(NSMutableArray*)results;
- (void)handleError:(FlutterResult)result;

@end

@interface SqfliteMethodCallOperation : SqfliteOperation

@property (atomic, retain) FlutterMethodCall* flutterMethodCall;
@property (atomic, assign) FlutterResult flutterResult;

+ (SqfliteMethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult;

@end

#endif /* SqfliteOperation_h */
