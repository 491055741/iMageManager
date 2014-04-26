//
//  FileManager.m
//  ImageManager
//
//  Created by li peng on 13-5-3.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "FileManager.h"

@implementation FileManager

#define kRootPath @"temp"

+ (BOOL)isDirPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    return isExist && isDir;
}

+ (BOOL)isGIFFile:(NSString *)fileName
{
    NSString *ext = fileName.pathExtension.lowercaseString;
    return [ext isEqualToString:@"gif"];
}

+ (BOOL)isZIPFile:(NSString *)fileName
{
    NSString *ext = fileName.pathExtension.lowercaseString;
    return [ext isEqualToString:@"zip"];
}

+ (BOOL)isVideoFile:(NSString *)fileName
{
    NSString *ext = fileName.pathExtension.lowercaseString;
    return (
            [ext isEqualToString:@"m4a"] ||
            [ext isEqualToString:@"m4v"] ||
            [ext isEqualToString:@"wmv"] ||
            [ext isEqualToString:@"3gp"] ||
            [ext isEqualToString:@"mp4"] ||
            [ext isEqualToString:@"mov"] ||
            [ext isEqualToString:@"avi"] ||
            [ext isEqualToString:@"mkv"] ||
            [ext isEqualToString:@"mpeg"]||
            [ext isEqualToString:@"mpg"] ||
            [ext isEqualToString:@"flv"] ||
            [ext isEqualToString:@"vob"]
            );
}

+ (BOOL)isPICFile:(NSString *)fileName
{
    NSString *ext = fileName.pathExtension.lowercaseString;
    return ([ext isEqualToString:@"jpg"] ||
            [ext isEqualToString:@"png"] ||
            [ext isEqualToString:@"bmp"]
            );
}

+ (NSString *)docPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
}

// 获取document目录的全路径
+ (NSString *)rootPath
{
    return [[FileManager docPath] stringByAppendingPathComponent:kRootPath];
}

+ (NSArray *)trashList
{
    return @[@".DS_Store", @"__MACOSX", @"videoThumb.db", kFileListCacheFileName];
}

// 获取指定路径下的文件和子目录列表（只取一层）,过滤掉 .DS_Store和__MACOSX目录
+ (NSArray *)contentsOfPath:(NSString *)path
{
    NSMutableArray *contentList = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]];
    [contentList removeObjectsInArray:[FileManager trashList]];
    return contentList;
}

// 获取指定路径下的子目录列表（只取一层）
+ (NSArray *)subPathOfPath:(NSString *)path
{
    NSMutableArray *subPathList = [NSMutableArray arrayWithCapacity:10];
    NSArray *contentList = [self contentsOfPath:path];
    for (NSString *filePath in contentList) {
        NSString *fullPath = [path stringByAppendingPathComponent:filePath];
        if ([self isDirPath:fullPath]) {
            [subPathList addObject:filePath];
        }
    }
    return subPathList;
}

+ (void)clearCache
{
    NSMutableArray *fileArray = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[FileManager rootPath] error:nil] ];

    for (NSString *fileName in fileArray) {
        if ([[fileName lastPathComponent] isEqualToString:kFileListCacheFileName]) {
            [[NSFileManager defaultManager] removeItemAtPath:[[FileManager rootPath] stringByAppendingPathComponent: fileName] error:nil];
        }
    }
}

// 指定路径下所有层次子目录所包含的所有文件列表
+ (NSMutableArray *)filesOfPath:(NSString *)path
{
    NSString *cacheFileName = [path stringByAppendingPathComponent:kFileListCacheFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFileName])
        return [NSMutableArray arrayWithContentsOfFile:cacheFileName];

    NSMutableArray *fileArray = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil] ];

    NSMutableArray *filterArray = [NSMutableArray arrayWithCapacity:10];
    [filterArray addObjectsFromArray:[FileManager trashList]];

    for (NSString *fileName in fileArray) {
        if ([[fileName pathExtension] isEqualToString:@""]
            || [[fileName lastPathComponent] isEqualToString:kFileListCacheFileName]) {
            [filterArray addObject:fileName];
        }
    }
    [fileArray removeObjectsInArray:filterArray];
//    NSLog(@"%s, %@", __func__, fileArray);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [fileArray writeToFile:cacheFileName atomically:YES];
    });

    return fileArray;
}

+ (void)moveAllToRootFolder
{
    NSString *rootPath = [FileManager rootPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSMutableArray *contentArray = [NSMutableArray arrayWithArray:[FileManager contentsOfPath:documentPath]];
    [contentArray removeObject:kRootPath];
    
    for (NSString *file in contentArray) {
        NSString *srcPath = [documentPath stringByAppendingPathComponent:file];
        NSString *dstPath = [rootPath stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:dstPath error:nil];
    }
}

@end
