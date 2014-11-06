//
//  NSObject+Alert.h
//  FinderMatrix
//
//  Created by li peng on 12-8-16.
//  Copyright (c) 2012年 ikamobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TEXT_FIELD_TAG    9999
#define kDismissAlertDelay 1.2

@interface NSObject (Alert)
- (void)showAlertMessage:(NSString *)msg;
- (void)showAlertMessage:(NSString *)msg title:(NSString *)title tag:(NSInteger)tag delegate:(id)delegate;
- (void)showAlertMessage:(NSString *)msg dismissAfterDelay:(NSTimeInterval)delay;

id getObjectFromNib(NSString *className, NSString *nibName);

@end
