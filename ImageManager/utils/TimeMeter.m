//
//  IKATimer.m
//  FinderMatrix
//
//  Created by jiajunchen on 12-12-18.
//  Copyright (c) 2012年 ikamobile. All rights reserved.
//

#include <mach/mach_time.h>

#import "TimeMeter.h"
#import "time.h"


@implementation TimeMeter

+ (TimeMeter *)getInstance
{
    static TimeMeter *timer = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timer = [[TimeMeter alloc] init];
    });
    
    return timer;
}

+ (double)currentAbsoluteMSec
{
    return mach_absolute_time() / NSEC_PER_MSEC;
}

- (void)start
{
//    dispatch_async(dispatch_get_main_queue(), ^(void){
        _startTime = mach_absolute_time();
//    });
}

- (void)endAndOutputWithHint:(NSString *)hint
{
//    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (_startTime == 0) {
            return;
        }

        mach_timebase_info_data_t info;
        if (mach_timebase_info(&info) != KERN_SUCCESS) return;

        uint64_t nanos = (mach_absolute_time () - _startTime) * info.numer / info.denom;
        NSLog(@"TimeMeter-%@: %.2fms", hint, (CGFloat)nanos / NSEC_PER_MSEC); // nsec -> msec
        _startTime = 0;

//    });
}

@end
