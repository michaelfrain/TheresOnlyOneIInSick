//
//  ConnectionsViewController.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ConnectionsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tblConnectedDevices;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UISlider *swDeviceRole;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceRole;

@end
