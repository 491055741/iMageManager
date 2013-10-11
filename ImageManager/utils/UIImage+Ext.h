//
//  UIImage+Ext.h
//  ImageManager
//
//  Created by Li Peng on 13-8-23.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Ext)
- (UIImage *)resizeToSize:(CGSize)size;
- (UIImage *)resizeToSize:(CGSize)size keepAspectRatio:(BOOL)isKeepAspectRatio;
@end
