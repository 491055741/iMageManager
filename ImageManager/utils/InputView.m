//
//  InputViewController.m
//  ImageManager
//
//  Created by li peng on 13-6-13.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "InputView.h"

@interface InputView ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
- (IBAction)done;
@end

@implementation InputView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [_textField becomeFirstResponder];
    }
}

- (void)setTitle:(NSString *)title defaultValue:(NSString *)defaultValue placeholder:(NSString *)placeholder
{
    _titleLabel.text = title;
    _textField.text = defaultValue;
    _textField.placeholder = placeholder;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.frame.size.height);
    [UIView animateWithDuration:0.25 animations:^{
            self.frame = CGRectMake(0, keyboardRect.origin.y - self.frame.size.height - 20.0, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (IBAction)done
{
    if (_delegate && [_delegate respondsToSelector:@selector(textInputDone:)]) {
        [_delegate textInputDone:_textField.text];
    }
    [self teardown];
}

- (void)teardown
{
    [_textField resignFirstResponder];
    return;

}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

}

@end
