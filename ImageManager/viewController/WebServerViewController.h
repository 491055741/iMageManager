//
//  WebServerViewController.h
//
//  Created by Robin Lu on 12/1/08.
//  Copyright robinlu.com 2008. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebServerViewController : UIViewController  {
	IBOutlet UILabel *urlLabel;
	NSMutableArray *fileList;
}

- (void)loadFileList;
- (void)loadFileListOfPath:(NSString *)path;
- (IBAction)toggleService:(id)sender;
@end
