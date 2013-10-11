//
//  InputViewController.h
//  ImageManager
//
//  Created by li peng on 13-6-13.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InputViewDelegate <NSObject>

- (void)textInputDone:(NSString *)text;

@end

@interface InputView : UIView <UITextFieldDelegate>

@property (nonatomic, assign) id<InputViewDelegate> delegate;

- (void)setTitle:(NSString *)title defaultValue:(NSString *)defaultValue placeholder:(NSString *)placeholder;
- (void)teardown;
@end
