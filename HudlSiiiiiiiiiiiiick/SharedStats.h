//
//  SharedStats.h
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/23/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import <foundation/Foundation.h>

@interface SharedStats : NSObject

@property (nonatomic) NSNumber* avgLowQualityVideoTransferTime;
@property (nonatomic) NSNumber* avgMedQualityVideoTransferTime;
@property (nonatomic) NSNumber* avgHighQualityVideoTransferTime;

@property (nonatomic) NSNumber* avgLowQualityVideoSize;
@property (nonatomic) NSNumber* avgMedQualityVideoSize;
@property (nonatomic) NSNumber* avgHighQualityVideoSize;

+ (id)instance;

- (void)reset;
- (void)logVideoTransfer:(NSNumber *)quality withSize:(NSNumber *)size withDuration:(NSNumber *)duration;

@end
