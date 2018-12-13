//
//  ImageCell.m
//  ImageManager
//
//  Created by LiPeng on 14-4-23.
//  Copyright (c) 2014年 li peng. All rights reserved.
//

#import "ImageCell.h"

#define kImageTag 13

@interface ImageCell()
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *selectStatusImageView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, assign) BOOL isChecked;
@end

@implementation ImageCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)prepareForReuse
{
    self.selected = NO;
    self.isChecked = NO;
}

- (void)setEditing:(BOOL)editing
{
    _selectStatusImageView.hidden = !editing;
    [self setChecked:editing ? self.isChecked : NO];
    
}

- (BOOL)isChecked
{
    return _isChecked;
}

- (void)setChecked:(BOOL)checked
{
    self.isChecked = checked;
//    [super setSelected:selected];
    _selectStatusImageView.image = [UIImage imageNamed:_isChecked ? @"selectOn" : @"selectOff"];
}

- (void)setImageView:(UIImageView *)imageView title:(NSString *)title
{
    _containerView.layer.shadowOffset = CGSizeMake(2, 2);
    _containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:_containerView.bounds].CGPath;
    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOpacity = 0.8;

    [[self.containerView viewWithTag:kImageTag] removeFromSuperview];
    _titleLabel.text = title;
    if (imageView == nil) {
        return;
    }
    imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    imageView.tag = kImageTag;
    imageView.userInteractionEnabled = NO;
    [self.containerView addSubview:imageView];
}

@end
