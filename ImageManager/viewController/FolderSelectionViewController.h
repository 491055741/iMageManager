//
//  pathSelectionViewController.h
//  ImageManager
//
//  Created by li peng on 13-5-3.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FolderSelectionDelegate <NSObject>

- (void)pathSelected:(NSString *)path;

@end

@interface FolderSelectionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) id<FolderSelectionDelegate> delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil basePath:(NSString *)path;
@end
