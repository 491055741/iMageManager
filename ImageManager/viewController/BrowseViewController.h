//
//  BrowseViewController.h
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AssetsGroupsTableViewCell.h"
#import "InputView.h"

@interface BrowseViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,  AssetsGroupsTableViewCellSelectionDelegate, InputViewDelegate>

@end
