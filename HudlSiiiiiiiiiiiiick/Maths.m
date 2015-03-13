//
//  Maths.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/25/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Maths.h"

@implementation Maths

+(NSNumber *)calcMbps:(NSNumber *)fileSize duration:(NSNumber *)seconds
{
    NSLog(@"MATH CALC MBPS:");
    NSLog(@"%@    %@", fileSize, seconds);

    long bits = [fileSize longValue] * 8;
    float s = [seconds floatValue];
    if (s == 0.0f) {
        return [NSNumber numberWithInt:0];
    }
    float mbps = (bits / s) / 1000000.0f;

    NSLog(@"actually computed a bps: %f", mbps);

    return [NSNumber numberWithDouble:mbps];
}

@end