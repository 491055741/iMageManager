//
//  UINavigationController+Ext.m
//  ImageManager
//
//  Created by Li Peng on 13-8-11.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "UINavigationController+Ext.h"

@implementation UINavigationController (Ext)

-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

@end
