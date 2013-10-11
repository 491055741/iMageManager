//
//  UIself+Ext.m
//  selfManager
//
//  Created by Li Peng on 13-8-23.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "UIImage+Ext.h"

@implementation UIImage (Ext)

- (UIImage *)resizeToSize:(CGSize)size
{
    return [self resizeToSize:size keepAspectRatio:NO];
}

- (UIImage *)resizeToSize:(CGSize)size keepAspectRatio:(BOOL)isKeepAspectRatio
{
    CGSize newSize = size;
    if (isKeepAspectRatio) {
        newSize.width = MIN(self.size.width, size.width);
        newSize.height = MIN(newSize.width * (self.size.height/self.size.width), size.height);
        newSize.width = newSize.height * (self.size.width/self.size.height);
    }
    
    if ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0f) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newSize.width, newSize.height), NO, 2.0f);
    }
    else {
        UIGraphicsBeginImageContext(CGSizeMake(newSize.width, newSize.height));
    }
    
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
}

@end
