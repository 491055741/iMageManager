//
//  NSObject+Alert.m
//  FinderMatrix
//
//  Created by li peng on 12-8-16.
//  Copyright (c) 2012年 ikamobile. All rights reserved.
//

#import "NSObject+Alert.h"

@implementation NSObject (Alert)

- (void)showAlertMessage:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:nil//NSLocalizedString(@"Notice", nil)
                              message:msg
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)showAlertMessage:(NSString *)msg title:(NSString *)title tag:(NSInteger)tag delegate:(id)delegate
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:title
                              message:msg
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                              otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.tag = tag;
    alertView.delegate = delegate;
    [alertView show];
}

// never show more than one auto dismiss alert at same time, it will cause crash
- (void)showAlertMessage:(NSString *)msg dismissAfterDelay:(NSTimeInterval)delay
{
    UIAlertView *alertView = [[UIAlertView alloc]
                               initWithTitle:nil//NSLocalizedString(@"Notice", nil)
                               message:nil
                               delegate:nil
                               cancelButtonTitle:nil
                               otherButtonTitles:nil];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 40.0f)];
    label.numberOfLines = 2; // if the text too long, the alert view should not be dismissed automatic.
    label.text = msg;
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    // Show alert and wait for it to finish displaying
    [alertView show];
    while (CGRectEqualToRect(alertView.bounds, CGRectZero));
    
    // Find the center for the text field and add it
    CGRect bounds = alertView.bounds;
    label.center = CGPointMake(bounds.size.width / 2.0f, bounds.size.height / 2.0f - 5.0);
    [alertView addSubview:label];
    [alertView show];
    [self performSelector:@selector(dimissAlert:) withObject:alertView afterDelay:delay];
}

- (void)dimissAlert:(UIAlertView *)alertView
{
    if (alertView) {
        [alertView dismissWithClickedButtonIndex:[alertView cancelButtonIndex] animated:YES];
    }
}

// C API
id getObjectFromNib(NSString *className, NSString *nibName)
{
    NSArray *objArray = [[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil];
    NSObject *resultObj = nil;
    
    for (NSObject *obj in objArray) {
        if ([obj isKindOfClass:NSClassFromString(className)]) {
            resultObj = obj;
            break;
        }
    }
    
    return resultObj;
}

@end
