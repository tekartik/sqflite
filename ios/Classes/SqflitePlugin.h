#import <Flutter/Flutter.h>

@interface SqflitePlugin : NSObject<FlutterPlugin>

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments;

@end

extern NSString *const _paramMethod;
extern NSString *const _paramSql;
extern NSString *const _paramSqlArguments;
extern NSString *const _paramNoResult;
