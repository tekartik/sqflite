//
//  SqflitePlugin.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqflitePluginPublic_h
#define SqflitePluginPublic_h

#import "SqfliteImportPublic.h"

@class SqfliteDarwinResultSet;

@interface SqflitePlugin : NSObject<FlutterPlugin>

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments;
+ (bool)arrayIsEmpty:(NSArray*)array;
+ (NSMutableDictionary*)resultSetToResults:(SqfliteDarwinResultSet*)resultSet cursorPageSize:(NSNumber*)cursorPageSize;

@end

#endif // SqflitePluginDef_h
