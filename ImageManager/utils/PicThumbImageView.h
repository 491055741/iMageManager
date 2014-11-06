//
//  PicThumbImageView.h
//  ImageManager
//
//  Created by Li Peng on 13-9-5.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PicThumbImageView : UIImageView

- (void)setImageWithPicPath:(NSString *)path placeholderImage:(UIImage *)placeholder;
@end
