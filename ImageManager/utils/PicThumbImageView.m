//
//  PicThumbImageView.m
//  ImageManager
//
//  Created by Li Peng on 13-9-5.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "PicThumbImageView.h"
#import "UIImage+Ext.h"

@implementation PicThumbImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setImageWithPicPath:(NSString *)path placeholderImage:(UIImage *)placeholder
{
    self.image = placeholder;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [[UIImage imageWithContentsOfFile:path] resizeToSize:self.bounds.size];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image;
            [self setNeedsDisplay];
        });
    }) ;
}

@end
