//
//  OptionsViewController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/23/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "OptionsViewController.h"
#import "AppDelegate.h"

@import AVFoundation;

@interface OptionsViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, copy) NSArray *videoQualityNumbers;
@property (nonatomic, copy) NSArray *videoQualityLabels;

@property (nonatomic) NSArray *videoCompressionTypes;

@end

@implementation OptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_pckCompressionType setDataSource:self];
    [_pckCompressionType setDelegate:self];

    _videoQualityNumbers = @[@(0), @(1), @(2)];
    _videoQualityLabels = @[@"🐕💨", @"Medium", @"High"];

    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [self configureSlider];
    [_captureAudio setOn:_appDelegate.captureAudio];

    _videoCompressionTypes = @[ @"Low", @"540p", @"720p", @"1080p" ];
 }

- (void)configureSlider
{
    NSInteger numberOfSteps = ((float)_videoQualityNumbers.count - 1);
    _videoQualitySlider.maximumValue = numberOfSteps;
    _videoQualitySlider.minimumValue = 0;
    _videoQualitySlider.continuous = YES;

    [_videoQualitySlider addTarget:self
               action:@selector(videoQualityChanged:)
     forControlEvents:UIControlEventValueChanged];

    [_captureAudio addTarget:self action:@selector(captureAudioChanged:) forControlEvents:UIControlEventValueChanged];

    [self videoQualityChanged:_videoQualitySlider];
}

- (void)captureAudioChanged:(UISwitch *)sender
{
    _appDelegate.captureAudio = [sender isOn];
}

#pragma mark - Video Quality Selection Changed
- (void)videoQualityChanged:(UISlider *)sender
{
    NSUInteger index = (NSUInteger)(_videoQualitySlider.value + 0.5);
    [_videoQualitySlider setValue:index animated:NO];

    NSNumber *number = _videoQualityNumbers[index];
    NSLog(@"sliderIndex: %i", (int)index);
    NSLog(@"number: %@", number);

    _appDelegate.videoQuality = number;
    _videoQualityLabel.text = _videoQualityLabels[index];
}

# pragma mark - Picker Stuffs
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _videoCompressionTypes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _videoCompressionTypes[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *comp = [_videoCompressionTypes objectAtIndex:row];
    if ([comp isEqualToString:@"Low"]) {
        _appDelegate.videoCompression = AVAssetExportPresetLowQuality;
    } else if ([comp isEqualToString:@"540p"]) {
        _appDelegate.videoCompression = AVAssetExportPreset960x540;
    } else if ([comp isEqualToString:@"720p"]) {
        _appDelegate.videoCompression = AVAssetExportPreset1280x720;
    } else {
        _appDelegate.videoCompression = AVAssetExportPreset1920x1080;
    }
}

@end