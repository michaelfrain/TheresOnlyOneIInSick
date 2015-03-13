//
//  VideoCaptureController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/25/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoCaptureController.h"
#import "AppDelegate.h"
#import "FileHelper.h"

@interface VideoCaptureController()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic) NSString *selectedPlayType;
@property (nonatomic, strong) FileHelper *fileHelper;

@property (nonatomic) int recordDurationSeconds;


@end

@implementation VideoCaptureController

@synthesize PreviewLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _fileHelper = [[FileHelper alloc] initWithDirectory:@"capture"];

    _selectedPlayType = @"Offense";

    NSLog(@"Setting up capture session");
    CaptureSession = [[AVCaptureSession alloc] init];

    _recordDurationSeconds = 0;

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateRecordingTime)
                                   userInfo:nil
                                    repeats:YES];

    NSLog(@"Adding video input");

    //ADD VIDEO INPUT
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice)
    {
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([CaptureSession canAddInput:VideoInputDevice])
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device. BRO DO YOU EVEN VIDEO?!?");
    }

    //ADD AUDIO INPUT
    NSLog(@"Adding audio input");
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (_appDelegate.captureAudio && audioInput)
    {
        [CaptureSession addInput:audioInput];
    }

    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];

    [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    NSLog(@"Adding movie file output");
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    Float64 TotalSeconds = 30;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    MovieFileOutput.maxRecordedDuration = maxDuration;
    MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME

    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];

    [self CameraSetOutputProperties];

    [self CaptureQuality];

    NSLog(@"Display the preview layer");
    [[_imgvwPreviewContainer layer] addSublayer:PreviewLayer];

    [self.view sendSubviewToBack:_imgvwPreviewContainer];
    [self.view bringSubviewToFront:_btnStartStopRecording];


    //----- START THE CAPTURE SESSION RUNNING -----
    [CaptureSession startRunning];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self fixupPreviewLayerBounds];
}

- (void) orientationChanged:(NSNotification *)notification
{
    [self fixupPreviewLayerBounds];
}

- (void)updateRecordingTime
{
    if(WeAreRecording) {
        _recordDurationSeconds++;

        NSDate* date = [NSDate dateWithTimeIntervalSince1970:_recordDurationSeconds];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"ss"];  //you can vary the date string. Ex: "mm:ss"
        NSString *timeFormat = [NSString stringWithFormat:@"%@s", [dateFormatter stringFromDate:date]];

        [_lblRecordingTime setText:timeFormat];
    }
}

- (void)CaptureQuality
{
    //----- SET THE IMAGE QUALITY / RESOLUTION -----
    //Options:
    //	AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
    //	AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
    //	AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
    //	AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
    //	AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
    NSLog(@"Setting capture quality");

    NSString *quality;
    if (_appDelegate.videoQuality == [NSNumber numberWithInt:0])
    {
        quality = AVCaptureSessionPresetLow;
    } else if(_appDelegate.videoQuality == [NSNumber numberWithInt:1]) {
        quality = AVCaptureSessionPresetMedium;
    } else {
        if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            quality = AVCaptureSessionPreset1280x720;
        } else {
            quality = AVCaptureSessionPresetHigh;
        }
    }

    [CaptureSession setSessionPreset:quality];
}

- (void)fixupPreviewLayerBounds
{
    CGRect bounds = [_imgvwPreviewContainer bounds];
    [[self PreviewLayer] setFrame:bounds];

    AVCaptureVideoOrientation orientation = [self interfaceOrientationToVideoOrientation:[UIApplication sharedApplication].statusBarOrientation];

    if (PreviewLayer.connection.supportsVideoOrientation) {
        PreviewLayer.connection.videoOrientation = orientation;
    }

    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [CaptureConnection setVideoOrientation:orientation];
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
    NSLog(@"Warning - Didn't recognise interface orientation (%d)",orientation);
    return AVCaptureVideoOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    WeAreRecording = NO;
    _lblRecordingTime.hidden = YES;
}

- (void) CameraSetOutputProperties
{
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];

    // set encoding and stuffs here
}

- (IBAction)ODKPressed:(id)sender
{
    NSString *newTitle = @"";
    NSString *currentTitle = _btnODK.titleLabel.text;
    if ([currentTitle isEqualToString:@"O"])
    {
        newTitle = @"D";
        _selectedPlayType = @"Defense";
    }

    if ([currentTitle isEqualToString:@"D"])
    {
        newTitle = @"K";
        _selectedPlayType = @"Kicking";
    }

    if ([currentTitle isEqualToString:@"K"])
    {
        newTitle = @"O";
        _selectedPlayType = @"Offense";
    }

    [_btnODK setTitle:newTitle forState:UIControlStateNormal];
}

- (IBAction)ExitButtonPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)StartStopButtonPressed:(id)sender
{

    if (!WeAreRecording)
    {
        //----- START RECORDING -----
        NSLog(@"START RECORDING");
        WeAreRecording = YES;
        _lblRecordingTime.text = @"0s";
        _lblRecordingTime.hidden = NO;

        //Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                //Error - handle if requried
                NSLog(@"%@", [error localizedDescription]);
            }
        }
        //Start recording
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];

        [_btnStartStopRecording setTitle:@"🔘" forState:UIControlStateNormal];
    }
    else
    {
        //----- STOP RECORDING -----
        NSLog(@"STOP RECORDING");
        WeAreRecording = NO;
        _lblRecordingTime.hidden = YES;
        _recordDurationSeconds = 0;

        [_btnStartStopRecording setTitle:@"⭕" forState:UIControlStateNormal];
        [MovieFileOutput stopRecording];
    }
}


//********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{

    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");

    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        // file is stored at //outputFileURL, we should move it to the correct folder...
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");

        // encode?
        AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:outputFileURL options:nil];
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
        AVAssetExportSession *exportSession;

        if ([compatiblePresets containsObject:_appDelegate.videoCompression]) {
            exportSession = [[AVAssetExportSession alloc]initWithAsset:anAsset presetName:_appDelegate.videoCompression];
        } else {
            if ([_appDelegate.videoCompression isEqualToString:@"540p"] || [_appDelegate.videoCompression isEqualToString:@"720p"]) {
                exportSession = [[AVAssetExportSession alloc]initWithAsset:anAsset presetName:AVAssetExportPresetMediumQuality];
            } else {
                exportSession = [[AVAssetExportSession alloc]initWithAsset:anAsset presetName:AVAssetExportPresetHighestQuality];
            }
        }

        NSString *fileName = [_fileHelper getNewFileName:_selectedPlayType];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", [_fileHelper getStorageLocation], fileName];
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;

        // export the video!
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                default:
                    // success?? I guess?
                    NSLog(@"SUCCESS!!!!");
                    NSDictionary *dict = @{ @"resourceName": fileName };
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"videoisready"
                                                                        object:nil
                                                                      userInfo:dict];
                    break;
            }
        }];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    CaptureSession = nil;
    MovieFileOutput = nil;
    VideoInputDevice = nil;
}

@end