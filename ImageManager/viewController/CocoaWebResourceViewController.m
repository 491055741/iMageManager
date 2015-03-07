//
//  CocoaWebResourceViewController.m
//  CocoaWebResource
//
//  Created by Robin Lu on 12/1/08.
//  Copyright robinlu.com 2008. All rights reserved.
//

#import "CocoaWebResourceViewController.h"
#import "FileManager.h"
#import "UINavigationBar+Ext.h"
#import "ASProgressPopUpView.h"

#define HTTPUploadingStartNotification @"UploadingStarted"
#define HTTPUploadingProgressNotification @"UploadingProgress"

@interface CocoaWebResourceViewController ()
@property (weak, nonatomic) IBOutlet ASProgressPopUpView *uploadProgress;
@property (weak, nonatomic) IBOutlet UILabel *uploadStatus;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@end

@implementation CocoaWebResourceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadingStarted:) name:HTTPUploadingStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadingProgress:) name:HTTPUploadingProgressNotification object:nil];
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	fileList = [[NSMutableArray alloc] init];
	[self loadFileList];
    [self.navigationController.navigationBar setBackButtonTitle:@"返回" target:self action:@selector(back)];
	self.title = @"Wifi";
    self.fileNameLabel.hidden = YES;
	// set up the http server
	httpServer = [[HTTPServer alloc] init];
	[httpServer setType:@"_http._tcp."];	
	[httpServer setPort:8080];
	[httpServer setName:@"CocoaWebResource"];
	[httpServer setupBuiltInDocroot];
	httpServer.fileResourceDelegate = self;
    [self startService];
    [self initProgressView];

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc
{
	httpServer.fileResourceDelegate = nil;
    [self stopService];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initProgressView
{
    self.uploadProgress.popUpViewAnimatedColors = @[[UIColor greenColor], [UIColor orangeColor], [UIColor redColor]];
    self.uploadProgress.popUpViewCornerRadius = 12.0;
    self.uploadProgress.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:28];
    [self.uploadProgress showPopUpViewAnimated:YES];
}

- (void)uploadingStarted:(NSNotification *)notification
{
    NSString *fileName = [notification userInfo][@"fileName"];
    self.fileNameLabel.hidden = NO;
    self.fileNameLabel.text = fileName;
    self.uploadStatus.text = @"0%";
    self.uploadProgress.hidden = NO;
    self.uploadProgress.progress = 0;
    NSLog(@"%s", __func__);
}

- (void)uploadingProgress:(NSNotification *)notification
{
    float progress = [[[notification userInfo] objectForKey:@"progress"] floatValue];
    if (progress >= 1.0)
        self.uploadStatus.text = @"Done!";
    else
        self.uploadStatus.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
//    self.uploadProgress.progress = progress;
    [self.uploadProgress setProgress:progress animated:YES];

//    NSLog(@"%s progress status %@, value %f,  ", __func__, self.uploadStatus.text, progress);
}

- (void)uploadingFinished
{
    self.uploadStatus.text = @"Done!";
    self.uploadProgress.progress = 1.0;
    NSLog(@"%s", __func__);
}

// load file list
- (void)loadFileList
{
	[fileList removeAllObjects];
    [fileList addObjectsFromArray:[FileManager contentsOfPath:[FileManager docPath]]];
}

- (void)loadFileListOfPath:(NSString *)path
{
	[fileList removeAllObjects];
    [fileList addObjectsFromArray:[FileManager contentsOfPath:path]];
}

- (void)startService
{
    NSError *error;
    BOOL serverIsRunning = [httpServer start:&error];
    if(!serverIsRunning)
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
    [urlLabel setText:[NSString stringWithFormat:@"http://%@:%d", [httpServer hostName], [httpServer port]]];
    [self.uploadStatus setText:@""];
    [self.fileNameLabel setText:@""];
    self.uploadProgress.progress = 0;
}

- (void)stopService
{
    [httpServer stop];
    [urlLabel setText:@""];
    [self.uploadStatus setText:@""];
    [self.fileNameLabel setText:@""];
    self.uploadProgress.progress = 0;
}

#pragma mark actions
- (IBAction)toggleService:(id)sender
{

	if ([(UISwitch*)sender isOn])
	{
        [self startService];
	}
	else
	{
        [self stopService];
	}
}

#pragma mark WebFileResourceDelegate
// number of the files
- (NSInteger)numberOfFiles
{
	return [fileList count];
}

// the file name by the index
- (NSString*)fileNameAtIndex:(NSInteger)index
{
	return [fileList objectAtIndex:index];
}

// provide full file path by given file name
- (NSString*)filePathForFileName:(NSString*)filename
{
//	NSString* docDir = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
//	return [NSString stringWithFormat:@"%@/%@", docDir, filename];
    return [[FileManager docPath] stringByAppendingPathComponent:filename];
}

// handle newly uploaded file. After uploading, the file is stored in
// the temparory directory, you need to implement this method to move
// it to proper location and update the file list.
- (void)newFileDidUpload:(NSString*)name inTempPath:(NSString*)tmpPath
{
	if (name == nil || tmpPath == nil)
		return;
	NSString *path = [[FileManager docPath] stringByAppendingPathComponent:name];
	NSError *error;
	if (![[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:path error:&error])
	{
		NSLog(@"can not move %@ to %@ because: %@", tmpPath, path, error );
	}

	[self loadFileList];
}

// implement this method to delete requested file and update the file list
- (void)fileShouldDelete:(NSString*)fileName
{
	//NSString *path = [self filePathForFileName:fileName];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	if(![fm removeItemAtPath:fileName error:&error])
	{
		NSLog(@"%@ can not be removed because:%@", fileName, error);
	}
	[self loadFileList];
}

- (void)viewDidUnload {
    [self setUploadProgress:nil];
    [self setUploadStatus:nil];
    [super viewDidUnload];
}

- (IBAction)resetPassword
{
    UIViewController *viewController = [[NSClassFromString(@"PasswordViewController") alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    [viewController setValue:@(YES) forKey:@"isSetPasswordMode"];
    [self presentModalViewController:viewController animated:YES];
}


@end
