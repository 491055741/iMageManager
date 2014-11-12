//
//  AppDelegate.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoThumbImageView.h"

@interface AppDelegate ()
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UINavigationController *navController;
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _viewController = [[NSClassFromString(@"BrowseViewController") alloc] initWithNibName:@"BrowseViewController" bundle:nil];
    
    _navController = [[UINavigationController alloc] init];
    _navController.navigationBar.barStyle = UIBarStyleBlack;
    _navController.navigationBar.translucent = YES;
    _window.rootViewController = _navController;
    [_navController pushViewController:_viewController animated:NO];
    [self.window makeKeyAndVisible];
    [self showLoginView];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    _navController.topViewController.view.hidden = YES;

//    _navController.topViewController.navigationController.navigationBar.hidden = YES;
    _navController.topViewController.view.hidden = YES;
    
    _navController.topViewController.presentedViewController.view.hidden = YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [VideoThumbImageView flush];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [self showLoginView];
//    _navController.topViewController.navigationController.navigationBar.hidden = NO;
    _navController.topViewController.view.hidden = NO;
//    if (![_navController.topViewController.presentedViewController isKindOfClass:NSClassFromString(@"PasswordViewController")]) {
        _navController.topViewController.presentedViewController.view.hidden = NO;
//    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)showLoginView
{
#if TARGET_IPHONE_SIMULATOR
    return;
#endif

#ifndef NO_PASSWORD
    UIViewController *viewController = [[NSClassFromString(@"PasswordViewController") alloc] initWithNibName:@"PasswordViewController" bundle:nil];

    if (_navController.topViewController.presentedViewController == nil) {
        [_navController.topViewController presentViewController:viewController animated:NO completion:NULL];
    } else if (![_navController.topViewController.presentedViewController isKindOfClass:NSClassFromString(@"PasswordViewController")]) {
        [_navController.topViewController.presentedViewController presentViewController:viewController animated:NO completion:NULL];
    }
#endif
}

@end
