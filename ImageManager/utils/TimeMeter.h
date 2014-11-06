//
//  IKATimer.h
//  FinderMatrix
//
//  Created by jiajunchen on 12-12-18.
//  Copyright (c) 2012年 ikamobile. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifdef __OPTIMIZE__
#define TIME_METER_BEGIN
#define TIME_METER_END(msg)
#else
#define TIME_METER_BEGIN        TimeMeter *tm = [[TimeMeter alloc] init]; [tm start];
#define TIME_METER_END(msg)     [tm endAndOutputWithHint:[NSString stringWithFormat:@"%s %@", __func__, msg]];

#endif

@interface TimeMeter : NSObject
{
    double _startTime;
}

+ (TimeMeter *)getInstance;
+ (double)currentAbsoluteMSec;
- (void)start;
- (void)endAndOutputWithHint:(NSString *)hint; // 打印毫秒

@end
