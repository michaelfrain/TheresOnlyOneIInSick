//
//  FileHelper.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/25/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "FileHelper.h"
#import "Utilities.h"


@interface PathWithModDate : NSObject
@property (strong) NSString *path;
@property (strong) NSDate *modDate;
@end

@implementation PathWithModDate
@end

@interface FileHelper()

@property (nonatomic) NSString *rootDir;
@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation FileHelper

+(NSNumber *)getFileSizenInBytes:(NSString *)filePath
{
    NSError *attributesError;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
    return [NSNumber numberWithUnsignedLongLong:[fileAttributes fileSize]];
}

+(NSString *)getFileSizeInWords:(NSString *)filePath
{
    NSNumber *size = [FileHelper getFileSizenInBytes:filePath];
    return [NSByteCountFormatter stringFromByteCount:[size longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
}


-(id)initWithDirectory:(NSString *)dir
{
    self = [super init];
    if (self) {
        _rootDir = dir;
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

-(NSString *)getStorageLocation
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:_rootDir];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder

    return dataPath;
}

-(NSNumber *)getFileSizeRaw:(NSString *)fileName
{
    NSError *attributesError;
    NSString *dir = [self getStorageLocation];
    NSString *fileFullPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",fileName]];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileFullPath error:&attributesError];
    return [NSNumber numberWithUnsignedLongLong:[fileAttributes fileSize]];
}

-(NSString *)getFileSize:(NSString *)fileName
{
    NSNumber *size = [self getFileSizeRaw:fileName];
    return [NSByteCountFormatter stringFromByteCount:[size longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
}

-(NSString *)getFileDuration:(NSString *)fileName
{
    NSString *dir = [self getStorageLocation];
    NSString *fileFullPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",fileName]];
    NSURL *sourceMovieURL = [NSURL fileURLWithPath:fileFullPath];
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    CMTime duration = sourceAsset.duration;

    float videoDurationSeconds = CMTimeGetSeconds(duration);

    NSDate* date = [NSDate dateWithTimeIntervalSince1970:videoDurationSeconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"ss"];  //you can vary the date string. Ex: "mm:ss"
    return [NSString stringWithFormat:@"%@s", [dateFormatter stringFromDate:date]];
}

- (NSArray*)getFilesByModificationDate {
    NSString *folderPath = [Utilities applicationSupportDirectory];
    NSArray *allPaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:nil];

    NSMutableArray *sortedPaths = [NSMutableArray new];
    for (NSString *path in allPaths) {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:path];

        NSDictionary *attr = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath error:nil];
        NSDate *modDate = [attr objectForKey:NSFileModificationDate];

        PathWithModDate *pathWithDate = [[PathWithModDate alloc] init];
        pathWithDate.path = path;
        pathWithDate.modDate = modDate;
        [sortedPaths addObject:pathWithDate];
    }

    [sortedPaths sortUsingComparator:^(PathWithModDate *path1, PathWithModDate *path2) {
        // Descending (most recently modified first)
        return [path2.modDate compare:path1.modDate];
    }];

    return [sortedPaths valueForKeyPath:@"path"];
}

-(void)removeFiles
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *fileName in [self getFilesByModificationDate]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [self getStorageLocation], fileName];
        [fileManager removeItemAtPath:fullPath error:&error];
    }
    for (NSString *fileName in [self getFilesByModificationDate]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [Utilities applicationSupportDirectory], fileName];
        [fileManager removeItemAtPath:fullPath error:&error];
    }
}

-(NSString *)getNewFileName:(NSString *)playType
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd-MM-yyyy_HH:mm:SS"];
    NSDate *now = [[NSDate alloc] init];
    NSString *theDate = [dateFormat stringFromDate:now];

    NSString *quality = @"";
    if([_appDelegate.videoQuality intValue] == 0) {
        quality = @"poor";
    } else if([_appDelegate.videoQuality intValue] == 1) {
        quality = @"medium";
    } else {
        quality = @"high";
    }

    NSString* completeFileName = [NSString stringWithFormat:@"%@-%@-%@", quality, playType, theDate];

    return completeFileName;
}

@end