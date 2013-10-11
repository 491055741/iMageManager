//
//  CustomNavigationBar.m
//  CustomNavigationBar
//
//  Created by Li peng on 11/27/10.
//  Copyright 2011 ikamobile. All rights reserved.
//

#import "UINavigationBar+Ext.h"


@implementation UINavigationBar (UINavigationBarCategory)

- (void)setBackButtonTitle:(NSString *)title target:(UIViewController *)target action:(SEL)action {

    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 10, 65, 30)];
    [backBtn setBackgroundImage:[UIImage imageNamed:@"navBarBackBtn.png"] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize: 13];

    [backBtn setTitle:[NSString stringWithFormat:@" %@", title] forState:UIControlStateNormal];

    [backBtn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBtnItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    target.navigationItem.leftBarButtonItem = backBtnItem;
}

@end
