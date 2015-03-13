//
//  VideoShipper.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/12/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoShipper.h"
#import "VideoQueue.h"
#import "FileHelper.h"

@interface VideoShipper()

@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) VideoQueue *queue;

@property (nonatomic) int totalTransfers;
@property (nonatomic) int failedTransfers;

@property (nonatomic) long totalBytesSent;
@property (nonatomic) int totalSecondsSpentSending;

@property (nonatomic) float reliability;
@property (nonatomic) float bandwidth;

@property (nonatomic) BOOL transferInProgress;

@property (nonatomic) NSArray *reviewerPeers;

@end

@implementation VideoShipper

+ (id)initWithSession:(MCSession *)session andQueue:(VideoQueue *)queue
{
    VideoShipper *shipper = [[VideoShipper alloc] init];
    shipper.session = session;
    shipper.queue = queue;
    shipper.reviewerPeers = session.connectedPeers;
    return shipper;
}

- (id)init{
    self = [super init];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newClipReady:) name:NotifVideoAddedToQueue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reviewersUpdated:) name:@"reviewersListUpdated" object:nil];
    }

    return self;
}

- (void)reviewersUpdated:(NSNotification *)notification
{
    NSArray *newReviewers = (NSArray *)notification.object;
    if (newReviewers != nil || newReviewers.count != 0) {
        _reviewerPeers = newReviewers;
    }

    NSLog(@"[VideoShipper] got new reviewers list: %lu", (unsigned long)newReviewers.count);

    if (_reviewerPeers.count > 0 && !_transferInProgress) {
        [self sendNextClipToReviewers];
    }
}

- (void)newClipReady:(NSNotification *)notification
{
    NSLog(@"[VideoShipper] newClipReady: %ld", [_queue len]);
    if ([_queue len] == 1 && !_transferInProgress)
    {
        // this is the only clip in the queue, send it!
        NSLog(@"[VideoShipper] new clip ready! Sending!");
        [self sendNextClipToReviewers];
    }
}

- (void)scheduleNextShipment
{
    _transferInProgress = NO;
    if ([_queue len] > 0)
    {
        // maybe run on a delay?
        NSLog(@"[VideoShipper] Sending next clip!");
        [self sendNextClipToReviewers];
    }
    else
    {
        // if there are no more clips, then we just wait for the video queue
        // to fill up again.
        NSLog(@"[VideoShipper] No clips in the queue. Waiting...");
    }
}

- (void)videoShipFailed:(MCPeerID *)peer error:(NSError *)error path:(NSString *)path
{
    NSLog(@"[VideoShipper] Error: %@", [error localizedDescription]);
    // update the failed count
    // push the video back into the queue
    [_queue push:path]; // ok for now, should go to top of queue...? (not without retry limit...)
    // also, this will resend the file to ALL peers, what if only one peer is having connection issues?
    // we shouldn't clog the tubes to get one peer it's video
}

- (void)videoShipSucceeded:(MCPeerID *)peer path:(NSString *)path start:(long)start
{
    // compute the file size and adjust the bandwidth metrics
    long now = [self getNow];
    long delta = now - start; //milliseconds
    _totalSecondsSpentSending += (delta / 1000);
    _totalBytesSent += [[FileHelper getFileSizenInBytes:path] longValue];

    NSLog(@"[VideoShipper] send successful! %ldbytes over %dseconds", _totalBytesSent, _totalSecondsSpentSending);
}

- (long)getNow
{
    NSNumber *now = [NSNumber numberWithLong:(long)([[NSDate date] timeIntervalSince1970] * 1000)];
    return [now longValue];
}

// reviewers right now is everyone... eventually clients will connect and identify
// to limit the amount of clients we have to transmit data to
- (void)sendNextClipToReviewers
{
    NSLog(@"[VideoShipper] connectedPeers: %lu", (unsigned long)_reviewerPeers.count);
    if (_reviewerPeers.count == 0) return;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    _transferInProgress = YES;

    NSString *nextClip = [_queue pop];
    NSURL *nextClipURL = [NSURL fileURLWithPath:nextClip];

    for (MCPeerID *peer in _session.connectedPeers) {
        _totalTransfers++;
        NSLog(@"[VideoShipper] outgoing shipment to %@. Sending %@", peer.displayName, nextClip);

        long start = [self getNow];
        [_session
         sendResourceAtURL:nextClipURL
         withName:nextClip
         toPeer:peer
         withCompletionHandler:^(NSError *error) {
             if (error) {
                 [self videoShipFailed:peer error:error path:nextClip];
             } else {
                 [self videoShipSucceeded:peer path:nextClip start:start];
             }
             [self scheduleNextShipment];
         }];
    }
}

@end
