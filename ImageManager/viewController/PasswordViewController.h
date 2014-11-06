//
//  PasswordViewController.h
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPLockScreen.h"

@interface PasswordViewController : UIViewController <LockScreenDelegate>
@property (nonatomic, assign) BOOL isSetPasswordMode;
@end
