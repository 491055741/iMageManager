//
//  PasswordViewController.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "PasswordViewController.h"

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define IPHONE5 (SCREEN_HEIGHT > 480)

@interface PasswordViewController ()
@end

@implementation PasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *imageName = IPHONE5 ? @"Default-568h.png" : @"Default.png";
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    backgroundImageView.frame = self.view.bounds;
    [self.view insertSubview:backgroundImageView atIndex:0];

    SPLockScreen *lockView = [[SPLockScreen alloc] init];
    lockView.backgroundColor = [UIColor clearColor];
    lockView.delegate = self;
    [self.view addSubview:lockView];
}

- (void)lockScreen:(SPLockScreen *)lockScreen didEndWithPattern:(NSNumber *)patternNumber
{
    if ([patternNumber compare:@(654)] != NSOrderedSame) {
        exit(0);
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
