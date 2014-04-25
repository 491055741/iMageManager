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

@end

@implementation ImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

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
}

- (void)setEditing:(BOOL)editing
{
    _selectStatusImageView.hidden = !editing;
    [self setSelected:editing ? self.selected : NO];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    _selectStatusImageView.image = [UIImage imageNamed:selected ? @"selectOn" : @"selectOff"];
}

- (void)setImageView:(UIImageView *)imageView title:(NSString *)title
{
    [[self viewWithTag:kImageTag] removeFromSuperview];
    _titleLabel.text = title;
    if (imageView == nil) {
        return;
    }
    imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    imageView.layer.shadowOffset = CGSizeMake(2, 2);
    imageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageView.bounds].CGPath;
    imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    imageView.layer.shadowOpacity = 0.8;
    imageView.tag = kImageTag;
    [self insertSubview:imageView atIndex:0];
}

@end
