//
//  FileManager.h
//  ImageManager
//
//  Created by li peng on 13-5-3.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFileListCacheFileName @"filelist.plist"

@interface FileManager : NSObject

+ (BOOL)isDirPath:(NSString *)path;
+ (BOOL)isGIFFile:(NSString *)fileName;
+ (BOOL)isZIPFile:(NSString *)fileName;
+ (BOOL)isVideoFile:(NSString *)fileName;
+ (BOOL)isPICFile:(NSString *)fileName;
+ (void)moveAllToRootFolder;
+ (NSString *)docPath;
+ (NSString *)rootPath;
+ (NSArray *)contentsOfPath:(NSString *)path;
+ (NSArray *)subPathOfPath:(NSString *)path;
+ (NSMutableArray *)filesOfPath:(NSString *)path;
+ (void)clearCache;
@end
