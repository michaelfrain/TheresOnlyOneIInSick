//
//  FileHelper.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/25/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <foundation/Foundation.h>

@import AVFoundation;

@interface FileHelper : NSObject

+(NSNumber *)getFileSizenInBytes:(NSString *)filePath;
+(NSString *)getFileSizeInWords:(NSString *)filePath;

-(id)initWithDirectory:(NSString *)dir;

-(NSString *)getStorageLocation;
-(NSNumber *)getFileSizeRaw:(NSString *)fileName;
-(NSString *)getFileSize:(NSString *)fileName;
-(NSString *)getNewFileName:(NSString *)playType;
-(NSString *)getFileDuration:(NSString *)fileName;
-(NSArray*)getFilesByModificationDate;
-(void)removeFiles;
@end