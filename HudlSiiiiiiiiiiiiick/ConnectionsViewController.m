//
//  ConnectionsViewController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "ConnectionsViewController.h"
#import "AppDelegate.h"

@interface ConnectionsViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSArray *arrConnectedDevices;

@property (nonatomic, strong) NSArray *deviceRoles;

-(void)peerDidChangeStateWithNotification:(NSNotification *)notification;

@end

@implementation ConnectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _deviceRoles = @[ @"Reviewer", @"Recorder" ];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [_tblConnectedDevices setDelegate:self];
    [_tblConnectedDevices setDataSource:self];

    _arrConnectedDevices = [[NSArray alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidChangeStateWithNotification:)
                                                 name:@"MCDidChangeStateNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keepAliveReceived:)
                                                 name:@"KeepAliveReceived"
                                               object:nil];

    NSString *peerName = [self uniquePeerDisplayName];

    [_appDelegate.mcManager setupPeerAndSessionWithDisplayName:peerName];
    [_appDelegate.mcManager advertiseSelf:YES];

    // update the connection list every 5s
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:_tblConnectedDevices
                                   selector:@selector(reloadData)
                                   userInfo:nil
                                    repeats:YES];

    _lblDeviceName.text = peerName;

    [self configureSlider];
}

- (void)viewDidAppear:(BOOL)animated
{
    [_appDelegate.mcManager.browser startBrowsingForPeers];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [_appDelegate.mcManager.browser stopBrowsingForPeers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) dealloc
{
    [_appDelegate.mcManager.browser stopBrowsingForPeers];
}

- (NSString *)uniquePeerDisplayName
{
    NSString *devName = [[[UIDevice currentDevice] name] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return devName;
}

-(void)keepAliveReceived:(NSNotification *)notification{
    _arrConnectedDevices = [[notification userInfo] allKeys];
    [_tblConnectedDevices reloadData];
}

-(void)peerDidChangeStateWithNotification:(NSNotification *)notification{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];

    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [_appDelegate.mcManager keepAlive];
            });
        }
        else if (state == MCSessionStateNotConnected){
            // handle disconnect somehow
        }

        [_tblConnectedDevices reloadData];
    }
}

- (void)configureSlider
{
    NSInteger numberOfSteps = ((float)_deviceRoles.count - 1);
    _swDeviceRole.maximumValue = numberOfSteps;
    _swDeviceRole.minimumValue = 0;
    _swDeviceRole.continuous = YES;

    [_swDeviceRole addTarget:self action:@selector(deviceRoleChanged:) forControlEvents:UIControlEventValueChanged];

    [self deviceRoleChanged:_swDeviceRole];
}

-(void)deviceRoleChanged:(UISlider *)slider
{
    NSUInteger index = (NSUInteger)(_swDeviceRole.value + 0.5);
    [_swDeviceRole setValue:index animated:NO];
    _lblDeviceRole.text = _deviceRoles[index];

    // tell the MCManager which role we are now

    // change the UI FLIP THE SCRIPT SON
    if (index == 0) {
        [self reviewerRoleChosen];
    } else {
        [self recorderRoleChosen];
    }
}

-(void)reviewerRoleChosen
{
    [[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:TRUE];
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:FALSE];
    [[[[self.tabBarController tabBar]items]objectAtIndex:3]setEnabled:FALSE];
}

-(void)recorderRoleChosen
{
    [[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:FALSE];
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:TRUE];
    [[[[self.tabBarController tabBar]items]objectAtIndex:3]setEnabled:TRUE];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _arrConnectedDevices.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdPeer"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdPeer"];
    }

    NSString *peerName = [_arrConnectedDevices objectAtIndex:indexPath.row];
    NSNumber *now = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970] * 1000];
    NSNumber *lastPing = [_appDelegate.mcManager.peerPingStatus objectForKey:peerName];
    NSInteger delta = [now integerValue] - [lastPing integerValue];

    [(UILabel *)[cell viewWithTag:100] setText:peerName];
    if(delta > 30000) {
        [(UILabel *)[cell viewWithTag:200] setText:@"😴"];
    } else {
        // we're connected and happy
        [(UILabel *)[cell viewWithTag:200] setText:@"😃"];
    }

    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}

@end
