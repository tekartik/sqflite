//
//  SqfliteImportPublic.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqfliteImportPublic_h
#define SqfliteImportPublic_h

#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else // elif TARGET_OS_IOS
#import <Flutter/Flutter.h>
#endif

#endif // SqfliteImportPublic_h
