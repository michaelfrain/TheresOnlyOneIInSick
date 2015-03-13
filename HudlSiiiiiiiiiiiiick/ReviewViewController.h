//
//  SecondViewController.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReviewViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tblFiles;

@property (nonatomic, weak) IBOutlet UILabel *lblLowAvgTime;
@property (nonatomic, weak) IBOutlet UILabel *lblMedAvgTime;
@property (nonatomic, weak) IBOutlet UILabel *lblHighAvgTime;
@property (nonatomic, weak) IBOutlet UILabel *lblPendingXfers;

@end

