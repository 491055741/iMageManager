//
//  CustomUINavigationController.m
//  ImageManager
//
//  Created by LiPeng on 20/06/2017.
//  Copyright © 2017 li peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomUINavigationViewController.h"

@implementation CustomUINavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//支持旋转
- (BOOL)shouldAutorotate{
    return [self.topViewController shouldAutorotate];
//    return YES;
}

//支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
//    return UIInterfaceOrientationMaskPortrait;
}

@end
