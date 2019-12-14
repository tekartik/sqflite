#if TARGET_OS_IPHONE
#import <Flutter/Flutter.h>
#else
#import <FlutterMacOS/FlutterMacOS.h>
#endif

@interface SqflitePlugin : NSObject<FlutterPlugin>

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments;

@end

extern NSString *const SqfliteParamMethod;
extern NSString *const SqfliteParamSql;
extern NSString *const SqfliteParamSqlArguments;
extern NSString *const SqfliteParamInTransaction;
extern NSString *const SqfliteParamNoResult;
extern NSString *const SqfliteParamContinueOnError;
extern NSString *const SqfliteParamResult;
extern NSString *const SqfliteParamError;
extern NSString *const SqfliteParamErrorCode;
extern NSString *const SqfliteParamErrorMessage;
extern NSString *const SqfliteParamErrorData;
