//
//  AppDelegate.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoThumbImageView.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface AppDelegate ()
@property (nonatomic, strong) UIViewController *browseViewController;
@property (nonatomic, strong) UIViewController *loginViewController;
@property (nonatomic, strong) UINavigationController *navController;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(login) name:@"login" object:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    _navController = [[UINavigationController alloc] init];
    _navController.navigationBar.barStyle = UIBarStyleBlack;
    _navController.navigationBar.translucent = YES;
    _browseViewController = [[NSClassFromString(@"BrowseViewController") alloc] initWithNibName:@"BrowseViewController" bundle:nil];
    _loginViewController = [[NSClassFromString(@"PasswordViewController") alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    [_navController pushViewController:_browseViewController animated:NO];
    _window.rootViewController = _navController;
    [self.window makeKeyAndVisible];
    [self showLoginView];
    return YES;
}

- (void)showLoginView
{
    NSLog(@"%s", __FUNCTION__);
#if TARGET_IPHONE_SIMULATOR
    [self login];
    return;
#endif
//    _window.rootViewController = _loginViewController;
//    _window.rootViewController = _navController;
    [_window addSubview:_loginViewController.view];
}

- (void)login
{
    NSLog(@"%s", __FUNCTION__);
//    _window.rootViewController = _navController;
//    [_navController.topViewController.presentedViewController dismissViewControllerAnimated:YES completion:^{
//    }];
    [_loginViewController.view removeFromSuperview];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self showLoginView];
    self.window.hidden = YES; // forbidden auto snapshot
    [VideoThumbImageView flush];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.window.hidden = NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
