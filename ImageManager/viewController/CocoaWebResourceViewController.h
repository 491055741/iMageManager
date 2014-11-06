//
//  CocoaWebResourceViewController.h
//  CocoaWebResource
//
//  Created by Robin Lu on 12/1/08.
//  Copyright robinlu.com 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPServer.h"

@interface CocoaWebResourceViewController : UIViewController <WebFileResourceDelegate> {
	IBOutlet UILabel *urlLabel;
	HTTPServer *httpServer;
	NSMutableArray *fileList;
}

- (void)loadFileList;
- (void)loadFileListOfPath:(NSString *)path;
- (IBAction)toggleService:(id)sender;
@end