//
//  FragmentedVideoCaptureController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 3/5/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "FragmentedVideoCaptureController.h"
#import "KFRecorder.h"
#import "AppDelegate.h"
#import "FileHelper.h"
#import "Utilities.h"
#import "AssetGroup.h"

@interface FragmentedVideoCaptureController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) FileHelper *fileHelper;
@property (nonatomic, strong) KFRecorder *recorder;

@property (nonatomic) int16_t recordDurationSeconds;

@end

@implementation FragmentedVideoCaptureController

@synthesize previewLayer;

- (void)viewDidLoad {
    [super viewDidLoad];

    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _fileHelper = [[FileHelper alloc] initWithDirectory:@"capture"];

    [self setupRecorder];

    // respond to orientation changes
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];

    // respond to fragments getting recorded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAssetGroupCreated:) name:NotifNewAssetGroupCreated object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self fixupPreviewLayerBoundsAndOrientation];
}

- (void) orientationChanged:(NSNotification *)notification
{
    [self fixupPreviewLayerBoundsAndOrientation];
}

- (void)newAssetGroupCreated:(NSNotification *)notification
{
    AssetGroup *asset = (AssetGroup *)notification.object;

    NSLog(@"new fragment captured: %@", [asset description]);

    NSString *fullPath = [[Utilities applicationSupportDirectory] stringByAppendingPathComponent:asset.fileName];

    NSLog(@"fragment lives at: %@", fullPath);

    [_appDelegate.videoQ push:fullPath];
}

- (IBAction)ExitButtonPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)StartStopButtonPressed:(id)sender
{
    if (!_isRecording)
    {
        _lblRecordingTime.text = @"0s";
        _lblRecordingTime.hidden = NO;

        [_btnStartStopRecording setTitle:@"🔘" forState:UIControlStateNormal];
        [_recorder startRecording];
    }
    else
    {
        _lblRecordingTime.hidden = YES;
        _recordDurationSeconds = -1;

        [_btnStartStopRecording setTitle:@"⭕" forState:UIControlStateNormal];
        [_recorder stopRecording];
        [_recorder.session stopRunning];

        [self setupRecorder];
    }
    _isRecording = !_isRecording;
}

- (void)setupRecorder
{
    NSString *uuid = [[[[NSUUID UUID] UUIDString] substringToIndex:8] stringByReplacingOccurrencesOfString:@"-" withString:@""];

    _recorder = [KFRecorder recorderWithName:uuid];
    [self setupCaptureQuality];
    [self setupPreviewLayer];

    [_recorder.session startRunning];
}

- (void)setupCaptureQuality
{
    NSString *quality;
    if (_appDelegate.videoQuality == [NSNumber numberWithInt:0])
    {
        quality = AVCaptureSessionPresetLow;
    } else if(_appDelegate.videoQuality == [NSNumber numberWithInt:1]) {
        quality = AVCaptureSessionPresetMedium;
    } else {
        if ([_recorder.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            quality = AVCaptureSessionPreset1280x720;
        } else {
            quality = AVCaptureSessionPresetHigh;
        }
    }

    NSLog(@"Setting capture quality: %@", quality);

    [_recorder.session setSessionPreset:quality];
}

- (void)setupPreviewLayer
{
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:_recorder.session]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    [[_imgvwPreviewContainer layer] addSublayer:previewLayer];

    [self.view sendSubviewToBack:_imgvwPreviewContainer];
}

- (void)fixupPreviewLayerBoundsAndOrientation
{
    CGRect bounds = [_imgvwPreviewContainer bounds];
    [previewLayer setFrame:bounds];

    AVCaptureVideoOrientation orientation = [self interfaceOrientationToVideoOrientation:[UIApplication sharedApplication].statusBarOrientation];

    if (previewLayer.connection.supportsVideoOrientation) {
        previewLayer.connection.videoOrientation = orientation;
    }
}

- (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    NSLog(@"Warning - Didn't recognise interface orientation (%ld)",(long) orientation);
    return AVCaptureVideoOrientationPortrait;
}
@end
