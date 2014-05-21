//
//  NSObject+ScreenSize.m
//  ImageManager
//
//  Created by LiPeng on 14-5-21.
//  Copyright (c) 2014年 li peng. All rights reserved.
//

#import "NSObject+ScreenSize.h"

@implementation NSObject (ScreenSize)

- (CGSize)screenSize
{
    CGSize size = CGSizeZero;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeRight
        || orientation == UIInterfaceOrientationLandscapeLeft) {
        size.height = screenSize.width;
        size.width = screenSize.height;
    } else {
        size.height = screenSize.height;
        size.width = screenSize.width;
    }
    return size;
}
@end
