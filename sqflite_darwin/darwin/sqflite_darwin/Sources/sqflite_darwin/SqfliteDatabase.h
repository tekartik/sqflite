//
//  SqfliteDatabase.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqfliteDatabase_h
#define SqfliteDatabase_h

#import "SqfliteCursor.h"
#import "SqfliteOperation.h"

@class SqfliteDarwinDatabaseQueue,SqfliteDarwinDatabase;
@interface SqfliteDatabase : NSObject

@property (atomic, retain) SqfliteDarwinDatabaseQueue *fmDatabaseQueue;
@property (atomic, retain) NSNumber *databaseId;
@property (atomic, retain) NSString* path;
@property (nonatomic) bool singleInstance;
@property (nonatomic) bool inTransaction;
@property (nonatomic) int logLevel;
// Curosr support
@property (nonatomic) int lastCursorId;
@property (atomic, retain) NSMutableDictionary<NSNumber*, SqfliteCursor*>* cursorMap;
// Transaction v2
@property (nonatomic) int lastTransactionId;
@property (atomic, retain) NSNumber *currentTransactionId;
@property (atomic, retain) NSMutableArray<SqfliteQueuedOperation*>* noTransactionOperationQueue;

- (void)closeCursorById:(NSNumber*)cursorId;
- (void)closeCursor:(SqfliteCursor*)cursor;
- (void)inDatabase:(void (^)(SqfliteDarwinDatabase *db))block;
- (void)dbBatch:(SqfliteDarwinDatabase*)db operation:(SqfliteMethodCallOperation*)mainOperation;
- (void)dbExecute:(SqfliteDarwinDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbInsert:(SqfliteDarwinDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbUpdate:(SqfliteDarwinDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbQuery:(SqfliteDarwinDatabase*)db operation:(SqfliteOperation*)operation;
- (void)dbQueryCursorNext:(SqfliteDarwinDatabase*)db operation:(SqfliteOperation*)operation;
@end

#endif // SqfliteDatabase_h
