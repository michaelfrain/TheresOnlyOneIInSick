//
//  VIdeoCaptureController.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/25/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@import AVFoundation;

#define CAPTURE_FRAMES_PER_SECOND		24

@interface VideoCaptureController : UIViewController
<AVCaptureFileOutputRecordingDelegate>
{
    BOOL WeAreRecording;

    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
}

@property (nonatomic, weak) IBOutlet UIButton* btnODK;
@property (nonatomic, weak) IBOutlet UIButton* btnStartStopRecording;
@property (nonatomic, weak) IBOutlet UIImageView* imgvwPreviewContainer;
@property (nonatomic, weak) IBOutlet UILabel* lblRecordingTime;

@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;

- (void) CameraSetOutputProperties;
- (IBAction)StartStopButtonPressed:(id)sender;
- (IBAction)ExitButtonPressed:(id)sender;
- (IBAction)ODKPressed:(id)sender;

@end
