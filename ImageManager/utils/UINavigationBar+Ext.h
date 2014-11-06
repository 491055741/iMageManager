//
//  CustomUIBar.h
//  CustomNavigationBar
//
//  Created by Li peng on 11-03-15.
//  Copyright 2011 ikaMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UINavigationBar (UINavigationBarCategory) 

- (void)setBackButtonTitle:(NSString *)title target:(UIViewController *)target action:(SEL)action;
@end

