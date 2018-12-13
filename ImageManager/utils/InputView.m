//
//  InputViewController.m
//  ImageManager
//
//  Created by li peng on 13-6-13.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "InputView.h"
#import "NSObject+ScreenSize.h"
@interface InputView ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
- (IBAction)done;
@end

@implementation InputView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview != nil) {
        [_textField becomeFirstResponder];
    }
}

- (void)setTitle:(NSString *)title defaultValue:(NSString *)defaultValue placeholder:(NSString *)placeholder
{
    _titleLabel.text = title;
    _textField.text = defaultValue;
    _textField.placeholder = placeholder;
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
}

@end
