//
//  ImageViewerViewController.h
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderSelectionViewController.h"

@interface ImageViewerViewController : UIViewController <UIGestureRecognizerDelegate, UIAlertViewDelegate, FolderSelectionDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil path:(NSString *)path startIdx:(NSInteger)idx;

@end

