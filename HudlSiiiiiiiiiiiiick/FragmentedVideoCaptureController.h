//
//  FragmentedVideoCaptureController.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/5/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@interface FragmentedVideoCaptureController : UIViewController

@property (nonatomic) BOOL isRecording;

@property (nonatomic, weak) IBOutlet UIButton* btnStartStopRecording;
@property (nonatomic, weak) IBOutlet UIImageView* imgvwPreviewContainer;
@property (nonatomic, weak) IBOutlet UILabel* lblRecordingTime;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;

- (IBAction)StartStopButtonPressed:(id)sender;
- (IBAction)ExitButtonPressed:(id)sender;

@end
