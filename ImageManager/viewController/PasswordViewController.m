//
//  PasswordViewController.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "PasswordViewController.h"
#import "UIImage+Ext.h"
#import <LocalAuthentication/LocalAuthentication.h>

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define IPHONE5 (SCREEN_HEIGHT == 568)

#define kPassworkKey @"PasswordKey"

@interface PasswordViewController ()
@property (nonatomic, copy) NSString *password;
@end

@implementation PasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{kPassworkKey:@"987"}];
        self.password = [[NSUserDefaults standardUserDefaults] valueForKey:kPassworkKey];
        NSLog(@"%s Password: %@", __func__, _password);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *imageName = IPHONE5 ? @"Default-568h.png" : @"Default.png";
    UIImage *image = [UIImage imageNamed:imageName];
    [image resizeToSize:[UIScreen mainScreen].bounds.size keepAspectRatio:YES];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:image];
    backgroundImageView.frame = [UIScreen mainScreen].bounds;
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view insertSubview:backgroundImageView atIndex:0];

    SPLockScreen *lockView = [[SPLockScreen alloc] init];
    lockView.backgroundColor = [UIColor clearColor];
    lockView.delegate = self;
    [self.view addSubview:lockView];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSError *error = nil;
    LAContext *la = [[LAContext alloc] init];
    if ([la canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {

        [la evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"请输入8位密码" reply:^(BOOL succes, NSError *error) {
             if (succes) {
                 NSLog(@"%s TouchID evaluate success, login", __FUNCTION__);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"login" object:nil];
                 });
             } else {
                 NSLog(@"%s TouchID evaluate failed with %@", __FUNCTION__, error.localizedDescription);
             }
        }];
    } else {
        NSLog(@"%s Device not support TouchID.", __FUNCTION__);
    }
}

- (void)lockScreen:(SPLockScreen *)lockScreen didEndWithPattern:(NSString *)patternString
{
    if (_isSetPasswordMode) {
        if ([patternString length] < 3) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Password too short." delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
            [alert show];
        } else {
            self.password = patternString;
            [[NSUserDefaults standardUserDefaults] setValue:patternString forKey:kPassworkKey];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Password update succeed." delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
            [alert show];
            [self dismissViewControllerAnimated:YES completion:^{ }];
        }
        return;
    }

    if ([patternString isEqualToString:_password] == NO) {
//        exit(0);
//        self.view.hidden = YES;
        self.view.userInteractionEnabled = NO;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"login" object:nil];
//        [self dismissViewControllerAnimated:YES completion:^{ }];
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
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
