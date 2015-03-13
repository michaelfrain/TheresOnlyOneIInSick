//
//  SharedStats.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/23/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharedStats.h"

@interface SharedStats ()

@property (nonatomic) NSInteger lowQualityCount;
@property (nonatomic) NSInteger medQualityCount;
@property (nonatomic) NSInteger hiQualityCount;


@property (nonatomic) NSInteger lowQualityTotalSize;
@property (nonatomic) NSInteger medQualityTotalSize;
@property (nonatomic) NSInteger hiQualityTotalSize;

@property (nonatomic) NSInteger lowQualityTotalDuration;
@property (nonatomic) NSInteger medQualityTotalDuration;
@property (nonatomic) NSInteger hiQualityTotalDuration;

@end

@implementation SharedStats

@synthesize avgHighQualityVideoSize, avgHighQualityVideoTransferTime, avgLowQualityVideoSize, avgLowQualityVideoTransferTime, avgMedQualityVideoSize, avgMedQualityVideoTransferTime;

#pragma mark Singleton Methods

+ (id)instance {
    static SharedStats *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)reset {
    avgHighQualityVideoSize = avgHighQualityVideoTransferTime = avgLowQualityVideoSize = avgLowQualityVideoTransferTime =  avgMedQualityVideoSize = avgMedQualityVideoTransferTime = 0;
}

- (void)logVideoTransfer:(NSNumber *)quality withSize:(NSNumber *)size withDuration:(NSNumber *)duration {
    if(quality == [NSNumber numberWithInt:0]) {
        // low
        _lowQualityCount++;
        _lowQualityTotalDuration += [duration integerValue];
        _lowQualityTotalSize += [size integerValue];
        avgLowQualityVideoTransferTime = [NSNumber numberWithFloat:_lowQualityTotalDuration / _lowQualityCount];
        avgLowQualityVideoSize = [NSNumber numberWithFloat:_lowQualityTotalSize / _lowQualityCount];
    } else if(quality == [NSNumber numberWithInt:1]) {
        // medium
        _medQualityCount++;
        _medQualityTotalDuration += [duration integerValue];
        _medQualityTotalSize += [size integerValue];
        avgMedQualityVideoTransferTime = [NSNumber numberWithFloat:_medQualityTotalDuration / _medQualityCount];
        avgMedQualityVideoSize = [NSNumber numberWithFloat:_medQualityTotalSize / _medQualityCount];
    } else {
        _hiQualityCount++;
        _hiQualityTotalDuration += [duration integerValue];
        _hiQualityTotalSize += [size integerValue];
        avgHighQualityVideoTransferTime = [NSNumber numberWithFloat:_hiQualityTotalDuration / _hiQualityCount];
        avgHighQualityVideoSize = [NSNumber numberWithFloat:_hiQualityTotalSize / _hiQualityCount];
    }

    NSLog(@"=-=-=-=-=-=-=-=-=-=-=- XFER TOTALS =-=-=-=-=-=-=-=-=-=-=-");
    NSLog(@"LOW: count: %ld    time: %ld    size: %ld", (long)_lowQualityCount, (long)_lowQualityTotalDuration, (long)_lowQualityTotalSize);
    NSLog(@"MED: count: %ld    time: %ld    size: %ld", (long)_medQualityCount, (long)_medQualityTotalDuration, (long)_medQualityTotalSize);
    NSLog(@"HI: count: %ld    time: %ld    size: %ld", (long)_hiQualityCount, (long)_hiQualityTotalDuration, (long)_hiQualityTotalSize);

}

@end