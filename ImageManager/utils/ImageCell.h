//
//  ImageCell.h
//  ImageManager
//
//  Created by LiPeng on 14-4-23.
//  Copyright (c) 2014年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kImageCellId @"ImageCell"

@interface ImageCell : UICollectionViewCell


@property (nonatomic, assign) BOOL selectStauts; // should not use 'selected', because it will change automaticly
@property (nonatomic, copy) NSString *desc;

- (void)setImageView:(UIImageView *)imageView title:(NSString *)title;
- (void)setEditing:(BOOL)editing;
//- (void)setSelectStauts:(BOOL)selectStauts;
@end
