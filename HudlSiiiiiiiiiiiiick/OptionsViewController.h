//
//  OptionsViewController.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/23/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface OptionsViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UISlider *videoQualitySlider;
@property (nonatomic, weak) IBOutlet UILabel *videoQualityLabel;
@property (nonatomic, weak) IBOutlet UISwitch *captureAudio;
@property (nonatomic, weak) IBOutlet UIPickerView *pckCompressionType;

@end
