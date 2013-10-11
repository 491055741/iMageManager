//
//  VideoThumbImageView.h
//  ImageManager
//
//  Created by Li Peng on 13-8-23.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kVideoThumbFileName @"videoThumb.db"

@interface VideoThumbImageView : UIImageView

+ (void)clearCache;
+ (void)flush; // flush memory cache to file
- (void)setImageWithVideoPath:(NSString *)path placeholderImage:(UIImage *)placeholder;

@end
