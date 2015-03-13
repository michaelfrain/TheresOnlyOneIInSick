//
//  VideoShipper.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/12/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoQueue.h"

@interface VideoShipper : NSObject

+ (id)initWithSession:(MCSession *)session andQueue:(VideoQueue *)queue;

@end
