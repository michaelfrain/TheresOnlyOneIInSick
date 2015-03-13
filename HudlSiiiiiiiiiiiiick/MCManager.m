//
//  MCManager.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCManager.h"

NSString *const kMPCAppName = @"HudlSidelineReplay";

@interface MCManager ()

@property (nonatomic, strong) VideoQueue *videoQueue;

@property (nonatomic) long startTime;
@property (nonatomic) NSMutableDictionary *alreadyConnectedTo;

@property (nonatomic) NSArray *reviewers;

@end

@implementation MCManager

+ (id)initWithVideoQueue:(VideoQueue *)queue
{
    MCManager *man = [[MCManager alloc] init];
    man.videoQueue = queue;
    return man;
}

-(id)init{
    self = [super init];

    if (self) {
        _peerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
        _reviewers = nil;
        NSNumber *now = [NSNumber numberWithLong:(long)([[NSDate date] timeIntervalSince1970] * 1000)];
        _startTime = [now longValue];

        NSLog(@"local startTime = %ld", _startTime);

        _peerPingStatus = [[NSMutableDictionary alloc] init];
        _alreadyConnectedTo = [[NSMutableDictionary alloc] init];
    }

    return self;
}

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];

    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;

    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:@"hudl-sick"];
    _browser.delegate = self;

    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:nil serviceType:@"hudl-sick"];
    _advertiser.delegate = self;

    _videoShipper = [VideoShipper initWithSession:_session andQueue:_videoQueue];
}

-(void)advertiseSelf:(BOOL)shouldAdvertise{
    if (shouldAdvertise) {
        [_advertiser startAdvertisingPeer];
    }
    else {
        [_advertiser stopAdvertisingPeer];
    }
}

- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler{
    NSLog(@"%@ GOT INVITE FROM %@", _peerID.displayName, peerID.displayName);

    NSDictionary *info = nil;
    long peerStartTime = -1;
    if (context != nil) {
        info = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:context];
        peerStartTime = [(NSNumber *)info[@"startTime"] longValue];

        if([_reviewers isEqual:nil] || _reviewers.count == 0) {
            _reviewers = (NSArray *)info[@"reviewers"];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"reviewersListUpdated"
                                                                object:_reviewers
                                                              userInfo:nil];
        }

        NSLog(@"%@ PEER STARTTIME: %ld, LOCAL STARTTIME: %ld", _peerID.displayName, peerStartTime, _startTime);
    }

    if(_startTime < peerStartTime) {
        // No, I should invite you...
        NSLog(@"%@ DECLINING INVITE FROM: %@", _peerID.displayName, peerID.displayName);
        NSDictionary *dict;
        if (_reviewers.count > 0) {
            dict = @{ @"startTime": [NSNumber numberWithLong:_startTime], @"reviewers": _reviewers };
        } else {
            dict = @{ @"startTime": [NSNumber numberWithLong:_startTime] };
        }
        [self browser:_browser foundPeer:peerID withDiscoveryInfo:dict];
    } else {
        NSLog(@"%@ ACCEPTING INVITE FROM: %@", _peerID.displayName, peerID.displayName);
        invitationHandler(YES, _session);
        NSLog(@"session, %@", _session);
    }
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler
{
    NSLog(@"%@ GOT CERT FROM %@", _peerID.displayName, peerID.displayName);
    certificateHandler(YES);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSError *error;
        [_session sendData:[@"keep-alive" dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
    });
}

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"%@ INVITES PEER %@", _peerID.displayName, peerID.displayName);
    [browser invitePeer:peerID toSession:_session withContext:[NSKeyedArchiver archivedDataWithRootObject:info] timeout:10];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"%@ LOST PEER: %@", _peerID.displayName, peerID.displayName);
}


#pragma mark - Data Methods

-(void)keepAlive {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSError *error;
        [_session sendData:[@"keep-alive" dataUsingEncoding:NSUTF8StringEncoding] toPeers:_session.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
        [self keepAlive];
    });
}

-(void)changeRole:(NSString *)newRole {
    NSError *error;
    if (_session.connectedPeers.count > 0) {
        [_session sendData:[[NSString stringWithFormat:@"role-change:%@", newRole] dataUsingEncoding:NSUTF8StringEncoding] toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    }
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSDictionary *dict = @{@"peerID": peerID,
                           @"state" : [NSNumber numberWithInt:state]
                           };

    NSLog(@"%@ GOT STATE CHANGE FROM %@: %d", _peerID.displayName, peerID.displayName, state);
    if (state == 0)
    {
        [self browser:_browser foundPeer:peerID withDiscoveryInfo:@{ @"startTime": [NSNumber numberWithLong:_startTime] }];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCDidChangeStateNotification"
                                                        object:nil
                                                      userInfo:dict];
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSError *error;
    NSString *dataText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dict = @{ @"data": data, @"peerID": peerID, @"dataText": dataText };
    if([dataText isEqualToString:@"keep-alive"]) {
        NSLog(@"%@ Received keep-alive from %@", _peerID.displayName, peerID);
        NSNumber *pingTime = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970] * 1000];
        [_peerPingStatus setObject:pingTime forKey:peerID.displayName];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"KeepAliveReceived" object:nil userInfo:_peerPingStatus];
        });
    } else if ([dataText containsString:@"role-change"]) {
        NSArray *split = [dataText componentsSeparatedByString:@":"];
        NSString *newRole = split[1];

        NSMutableArray *reviewers = [_reviewers mutableCopy];
        if ([newRole isEqualToString:@"Recorder"])
        {
            // remove this peerid from the _reviewers array
            [reviewers removeObject:peerID];
        }
        else
        {
            // add this peerid to the reviewers array
            [reviewers addObject:peerID];
        }
        _reviewers = [reviewers copy];

        // notify listeners of change to reviewers
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reviewersListUpdated"
                                                            object:_reviewers
                                                          userInfo:nil];

    } else if ([dataText containsString:@"got-file"]) {
        NSArray *split = [dataText componentsSeparatedByString:@":"];
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        [newDict setObject:split[1] forKey:@"fileName"];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"clientACKFileReceived" object:nil userInfo:newDict];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"didFinishReceivingDataNotification" object:nil userInfo:dict];
        });
    }
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{

    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"progress"      :   progress
                           };

    NSLog(@"[%@] started receiving file: %@", _peerID.displayName, resourceName);

    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartReceivingResourceNotification"
                                                        object:nil
                                                      userInfo:dict];


    dispatch_async(dispatch_get_main_queue(), ^{
        [progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:(__bridge void *)(resourceName)];
    });
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSString *resourceName = (__bridge NSString *)context; // yeah i know this is awful... need to GSD and worry about this later
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCReceivingProgressNotification"
                                                        object:nil
                                                      userInfo:@{@"progress": (NSProgress *)object, @"resourceName": resourceName}];
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{

    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"localURL"      :   localURL
                           };

    NSLog(@"[%@] finished receiving file: %@", _peerID.displayName, resourceName);

    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishReceivingResourceNotification"
                                                        object:nil
                                                      userInfo:dict];

}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{

}

@end