//
//  AppDelegate.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"
#import "VideoQueue.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MCManager *mcManager;
@property (nonatomic, strong) VideoQueue *videoQ;

@property (nonatomic) NSNumber *videoQuality;
@property (nonatomic) BOOL captureAudio;
@property (nonatomic) NSString *videoCompression;


-(BOOL)isPad;
@end

