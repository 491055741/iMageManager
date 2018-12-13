//
//  UIDevice+Ext.m
//  ImageManager
//
//  Created by LiPeng on 20/06/2017.
//  Copyright © 2017 li peng. All rights reserved.
//

#import "UIDevice+Ext.h"

@implementation UIDevice (Ext)

+ (void)setOrientation:(UIInterfaceOrientation)orientation {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[self currentDevice]];
    int val = orientation;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
}
@end
