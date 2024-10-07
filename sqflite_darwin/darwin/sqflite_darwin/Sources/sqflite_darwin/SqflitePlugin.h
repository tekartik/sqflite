//
//  SqflitePlugin.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqflitePlugin_h
#define SqflitePlugin_h

#import "include/sqflite_darwin/SqflitePluginPublic.h"

extern NSString *const SqfliteMethodExecute;;
extern NSString *const SqfliteMethodInsert;
extern NSString *const SqfliteMethodUpdate;
extern NSString *const SqfliteMethodQuery;

extern NSString *const SqfliteErrorBadParam;
extern NSString *const SqliteErrorCode;

extern NSString *const SqfliteParamMethod;
extern NSString *const SqfliteParamSql;
extern NSString *const SqfliteParamSqlArguments;
extern NSString *const SqfliteParamInTransactionChange;
extern NSString *const SqfliteParamNoResult;
extern NSString *const SqfliteParamContinueOnError;
extern NSString *const SqfliteParamResult;
extern NSString *const SqfliteParamError;
extern NSString *const SqfliteParamErrorCode;
extern NSString *const SqfliteParamErrorMessage;
extern NSString *const SqfliteParamErrorData;
extern NSString *const SqfliteParamTransactionId;

// Static helpers
static const int sqfliteLogLevelNone = 0;
static const int sqfliteLogLevelSql = 1;
static const int sqfliteLogLevelVerbose = 2;

extern bool sqfliteHasSqlLogLevel(int logLevel);
// True for verbose debugging
extern bool sqfliteHasVerboseLogLevel(int logLevel);

#endif // SqflitePlugin_h
