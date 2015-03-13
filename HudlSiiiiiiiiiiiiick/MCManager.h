//
//  MCManager.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "VideoShipper.h"
#import "VideoQueue.h"


extern NSString *const kMPCAppName;

@interface MCManager : NSObject<MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) VideoShipper *videoShipper;
@property (nonatomic, copy) NSMutableDictionary *peerPingStatus;

+(id)initWithVideoQueue:(VideoQueue *)queue;

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
-(void)advertiseSelf:(BOOL)shouldAdvertise;
-(void)keepAlive;
@end
