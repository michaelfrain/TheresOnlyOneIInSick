//
//  VideoQueue.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/11/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoQueue.h"

NSString *const NotifVideoAddedToQueue = @"VideoAddedToQueue";

@interface VideoQueue ()

@property (nonatomic, copy) NSMutableArray *q;

@end

@implementation VideoQueue

- (id)init{
    self = [super init];

    if (self) {
        _q = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (long)len
{
    return _q.count;
}

- (void)push:(NSString *)videoPath
{
    [_q addObject:videoPath];

    NSLog(@"[VideoQueue] video: %@ pushed to queue, new len: %ld", videoPath, [self len]);

    NSDictionary *dict = @{ @"path": videoPath };
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifVideoAddedToQueue object:nil userInfo:dict];
}

- (NSString *)pop
{
    NSString *path = _q[0];

    NSLog(@"[VideoQueue] popping %@", path);

    [_q removeObjectAtIndex:0];

    return path;
}

@end
