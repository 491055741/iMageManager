//
//  ImageCell.h
//  ImageManager
//
//  Created by LiPeng on 14-4-23.
//  Copyright (c) 2014年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kImageCellId @"ImageCell"
#define kImageCellSize CGSizeMake(130, 130)

@interface ImageCell : UICollectionViewCell

@property (nonatomic, copy) NSString *desc;

- (void)setImageView:(UIImageView *)imageView title:(NSString *)title;
- (void)setEditing:(BOOL)editing;

@end
