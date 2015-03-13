//
//  VideoQueue.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/11/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const NotifVideoAddedToQueue;

@interface VideoQueue : NSObject

- (long)len;
- (void)push:(NSString *)videoPath;
- (NSString *)pop;

@end
