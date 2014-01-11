//
//  BrowseViewController.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "BrowseViewController.h"
#import "ImageViewerViewController.h"
#import "NSObject+Alert.h"
#import "ZipArchive.h"
#import "FileManager.h"
#import "SCGIFImageView.h"
#import "PosterImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "KxMovieViewController.h"
#import "KxMovieDecoder.h"
#import "VideoThumbImageView.h"
#import "PicThumbImageView.h"
#import "UINavigationBar+Ext.h"
#import "UIImage+Ext.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define kImageTableCellHeight 74
#define kThumbnailCellHeight 170

#define kInputViewTag 10
#define kMaskViewTag 88
#define kFileActionViewTag 999

@interface BrowseViewController ()
@property (nonatomic, strong) NSArray *contentArray;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, strong) NSMutableArray *selectedPathArray;
@property (strong, nonatomic) IBOutlet UIView *fileActionView;
@property (strong) UITapGestureRecognizer *tap;
@property (nonatomic) BOOL isListMode;
@property (nonatomic, assign) BOOL isEditingMode;
@property (nonatomic, strong) NSMutableDictionary *cacheDict;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *actionBarBtn;

// action buttons
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *deselectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *cutBtn;
@property (weak, nonatomic) IBOutlet UIButton *renameBtn;
@property (weak, nonatomic) IBOutlet UIButton *createDirBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;


- (IBAction)switchListMode:(id)sender;
- (IBAction)createDir:(id)sender;
- (IBAction)wifi:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)hideFileActionView;
- (IBAction)refresh:(id)sender;
- (IBAction)play:(id)sender;
@end

@implementation BrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTaped)];
        self.rootPath = [FileManager rootPath];
        NSLog(@"%s %@", __func__, _rootPath);
        [self initData];
    }
    return self;
}

- (void)initData
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[FileManager contentsOfPath:_rootPath]];

    if (tempArray.count == 0) {
        _isListMode = YES;
    } else {
        // sort the array, move dir to head
        NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:200];
        for (NSString *path in tempArray) {
            if (![FileManager isDirPath:[_rootPath stringByAppendingPathComponent:path]]) {
                [fileArray addObject:path];
            }
        }
        // sort files with file type
        [fileArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *path1 = obj1;
            NSString *path2 = obj2;
            return [[path1 pathExtension] compare:[path2 pathExtension]];
        }];
        [tempArray removeObjectsInArray:fileArray];
        [tempArray addObjectsFromArray:fileArray];
    }
    self.contentArray = [NSArray arrayWithArray:tempArray];
    self.cacheDict = [NSMutableDictionary dictionaryWithCapacity:10];
    if (![_action isEqualToString:@"cut"])
        self.selectedPathArray = [NSMutableArray arrayWithCapacity:10];
}

- (void)clearCache
{
    [VideoThumbImageView clearCache];
    [FileManager clearCache];
    [_cacheDict removeAllObjects];
//    NSArray *subPathArray = [FileManager subPathOfPath:[FileManager rootPath]]; // only check one level of subpath
//    for (NSString *path in subPathArray) {
//        NSString *cacheFileName = [[FileManager rootPath] stringByAppendingPathComponent: [path stringByAppendingPathComponent:kFileListCacheFileName]];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFileName])
//            [[NSFileManager defaultManager] removeItemAtPath:cacheFileName error:nil];
//    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"iMage Manager";
    
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(0, 0, 50, 30);
    [actionButton setBackgroundImage:[UIImage imageNamed:@"blackBtn.png"] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(switchEditingMode) forControlEvents:UIControlEventTouchUpInside];
    [actionButton setTitle:@"Action" forState:UIControlStateNormal];
    actionButton.titleLabel.textColor = [UIColor whiteColor];
    actionButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.actionBarBtn = [[UIBarButtonItem alloc] initWithCustomView:actionButton];

    // Do any additional setup after loading the view from its nib.
    [_tableView registerNib:[UINib nibWithNibName:@"AssetsGroupsTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"AssetsCell"];
    _tableView.tableFooterView = [[UIView alloc] init];
    if (!SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    }
    [self configActionButtonsStatus];
}

- (void)configActionButtonsStatus
{
    if ([_selectedPathArray count] == 1) {
        _selectAllBtn.enabled = YES;
        _deselectAllBtn.enabled = YES;
        _cutBtn.enabled = YES;
        _renameBtn.enabled = YES;
        _createDirBtn.enabled = NO;
        _deleteBtn.enabled = YES;
    } else if ([_selectedPathArray count] == 0) { // select none
        _selectAllBtn.enabled = YES;
        _deselectAllBtn.enabled = NO;
        _cutBtn.enabled = NO;
        _renameBtn.enabled = NO;
        _createDirBtn.enabled = YES;
        _deleteBtn.enabled = NO;
    } else {                   // select more than 1
        _selectAllBtn.enabled = YES;
        _deselectAllBtn.enabled = YES;
        _cutBtn.enabled = YES;
        _renameBtn.enabled = NO;
        _createDirBtn.enabled = NO;
        _deleteBtn.enabled = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [_cacheDict removeAllObjects];
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && self.view.window == nil) { // not current view
        [self viewDidUnload];

        self.view = nil;
    }
}

- (void)viewDidUnload {
//    [self setTableView:nil];
//    [self setFileActionView:nil];
    [self setSelectAllBtn:nil];
    [self setDeselectAllBtn:nil];
    [self setCutBtn:nil];
    [self setRenameBtn:nil];
    [self setCreateDirBtn:nil];
    [self setDeleteBtn:nil];
    [super viewDidUnload];
}

- (void)backToParentFolder
{
    self.rootPath = [_rootPath stringByDeletingLastPathComponent];
    [self initData];
    [_tableView reloadData];

    if ([_rootPath isEqualToString:[FileManager rootPath]]) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        [self.navigationController.navigationBar setBackButtonTitle:[_rootPath lastPathComponent] target:self action:@selector(backToParentFolder)];
    }
}

- (IBAction)switchListMode:(id)sender
{
    if (_contentArray.count == 0) {
        return;
    }
    _isListMode = !_isListMode;
    //    _toolbar.hidden = _isListMode;
    _isEditingMode = NO;
    [self configActionBtn];
    [_tableView reloadData];
}

- (void)switchEditingMode
{
    _isEditingMode = ! _isEditingMode;
    _isEditingMode ? [self showFileActionView] : [self hideFileActionView];
    _tableView.contentInset = _isEditingMode ? UIEdgeInsetsMake(44, 0, 144, 0) : UIEdgeInsetsMake(44, 0, 44, 0);

    [self.tableView reloadData];
}

- (void)configActionBtn
{
    self.navigationItem.rightBarButtonItem = _isListMode ? _actionBarBtn : nil;

    UIButton *btn = (UIButton *)_actionBarBtn.customView;
    [btn setTitle:(_isEditingMode ? @"Done" : @"Action") forState:UIControlStateNormal];
}

- (void)showFileActionView
{
    self.toolbar.hidden = YES;
    _isEditingMode = YES;
    [self configActionBtn];
    
    if ([self.view viewWithTag:kFileActionViewTag] != nil) {
        [self hideFileActionView];
        return;
    }

    CGRect startRect = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, _fileActionView.frame.size.height);
    CGRect endRect = CGRectMake(0, self.view.frame.size.height - _fileActionView.frame.size.height, self.view.frame.size.width, _fileActionView.frame.size.height);
    _fileActionView.frame = startRect;
    _fileActionView.tag = kFileActionViewTag;
    [self.view addSubview:_fileActionView];
    [UIView animateWithDuration:0.3 animations:^{
        _fileActionView.frame = endRect;
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)hideFileActionView
{
    self.toolbar.hidden = NO;
    _isEditingMode = NO;
    [self configActionBtn];
    
    [_tableView removeGestureRecognizer:_tap];
    CGRect startRect = CGRectMake(0, self.view.frame.size.height - _fileActionView.frame.size.height, _fileActionView.frame.size.width, _fileActionView.frame.size.height);
    CGRect endRect = CGRectMake(0, self.view.frame.size.height, _fileActionView.frame.size.width, _fileActionView.frame.size.height);

    _fileActionView.frame = startRect;
    [self.view addSubview:_fileActionView];
    [UIView animateWithDuration:0.3 animations:^{
        _fileActionView.frame = endRect;
    } completion:^(BOOL finished) {
        [_fileActionView removeFromSuperview];
    }];
}

- (void)backgroundTaped
{
    [self hideFileActionView];
    [self hideInputView];
}

- (void)hideInputView
{
    InputView *inputView = (InputView *)[self.view viewWithTag:kInputViewTag];
    [inputView teardown];
}

- (IBAction)refresh:(id)sender
{
    [self showIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [FileManager moveAllToRootFolder];
        [self clearCache];
        [self initData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadData];
            [self hideIndicator];
        });
    });
}

- (IBAction)createDir:(id)sender {

    _action = @"create";
    InputView *inputView = getObjectFromNib(@"InputView", @"InputView");
    inputView.delegate = self;
    [inputView setTitle:@"创建目录" defaultValue:@"" placeholder:@"目录名"];
    NSLog(@"%s %@", __func__, [self.view viewWithTag:kInputViewTag]);
    [self.view addSubview:inputView];
}

- (IBAction)cut:(id)sender
{
    self.action = @"cut";
    [_cutBtn setTitle:@"Paste" forState:UIControlStateNormal];
    [_cutBtn removeTarget:self action:@selector(cut:) forControlEvents:UIControlEventTouchUpInside];
    [_cutBtn addTarget:self action:@selector(paste:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)paste:(id)sender
{
    _action = @"paste";
    [_cutBtn setTitle:@"Cut" forState:UIControlStateNormal];
    [_cutBtn removeTarget:self action:@selector(paste:) forControlEvents:UIControlEventTouchUpInside];
    [_cutBtn addTarget:self action:@selector(cut:) forControlEvents:UIControlEventTouchUpInside];
    [self doAction];
}

- (IBAction)selectAll:(id)sender
{
    [_selectedPathArray removeAllObjects];
    for (NSString *path in _contentArray) {
        [_selectedPathArray addObject: [_rootPath stringByAppendingPathComponent:path]];
    }
    [_tableView reloadData];

    _selectAllBtn.enabled = NO;
    _deselectAllBtn.enabled = YES;
    _cutBtn.enabled = YES;
    _renameBtn.enabled = NO;
    _createDirBtn.enabled = NO;
    _deleteBtn.enabled = YES;
}

- (IBAction)deselectAll:(id)sender
{
    [_selectedPathArray removeAllObjects];
    [_tableView reloadData];

    _selectAllBtn.enabled = YES;
    _deselectAllBtn.enabled = NO;
    _cutBtn.enabled = NO;
    _renameBtn.enabled = NO;
    _createDirBtn.enabled = YES;
    _deleteBtn.enabled = NO;
}

// delete multiple files
- (IBAction)delete:(id)sender
{
    for (NSString *path in _selectedPathArray) {
        NSLog(@"%s deleting %@", __func__, path);
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [self initData];
    [_tableView reloadData];
}

- (void)doAction
{
    if ([_action isEqualToString:@"paste"]) {
        
        [self showIndicator];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            for (NSString *fileName in _selectedPathArray) {

                NSString *toPath = [_rootPath stringByAppendingPathComponent:[fileName lastPathComponent]];

                NSLog(@"%s move [%@] to [%@]", __func__, fileName, toPath);
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:fileName toPath:toPath error:&error];
                if (error != nil) {
                    NSLog(@"%s [%@] move failed: %@", __FUNCTION__, fileName, error.description);
                    [self showAlertMessage:@"Move Failed."];// error.userInfo[@"NSUnderlyingError"]
                }
            }
//            [self clearCache];
//            self.rootPath = [FileManager rootPath];
            [self initData];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self configActionButtonsStatus];
                [self hideIndicator];
                [self hideFileActionView];
                [_tableView reloadData];
            });
        });

    } else if ([_action isEqualToString:@"rename"]) {

        InputView *inputView = getObjectFromNib(@"InputView", @"InputView");
        inputView.delegate = self;
        [inputView setTitle:@"rename" defaultValue:[_selectedPathArray[0] lastPathComponent] placeholder:@"name"];
        [self.view addSubview:inputView];

    } else if ([_action isEqualToString:@"delete"]) {
        NSLog(@"%s delete folder %@", __func__, _selectedPathArray[0]);
        [[NSFileManager defaultManager] removeItemAtPath:_selectedPathArray[0] error:nil];
        [self initData];
        [_tableView reloadData];
    }
}

- (void)unzipFile:(NSString *)fileName toFolder:(NSString *)destPath
{
    NSString *l_zipfile = [_rootPath stringByAppendingPathComponent:fileName];
    ZipArchive* zip = [[ZipArchive alloc] init];
    // 如果解压中文有问题，参考http://www.cocoachina.com/bbs/simple/?t10195.html解决
    if ([zip UnzipOpenFile:l_zipfile]) {
        BOOL ret = [zip UnzipFileTo:destPath overWrite:YES];
        if (NO == ret) {
            NSLog(@"%s Unzip file %@ failed.", __func__, fileName);
        }
        [zip UnzipCloseFile];
        [[NSFileManager defaultManager] removeItemAtPath:l_zipfile error:nil];
    }
}

- (void)showIndicator
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.view.center;
    [activityIndicator startAnimating];
    activityIndicator.tag = 555;
    [self.view addSubview:activityIndicator];
}

- (void)hideIndicator
{
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:555];
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
}

- (IBAction)rename:(id)sender
{
    if ([_selectedPathArray count] == 0)
        return;
    self.action = @"rename";
    [self doAction];
}

- (IBAction)wifi:(id)sender {
    UIViewController *viewController = [[NSClassFromString(@"CocoaWebResourceViewController") alloc] initWithNibName:@"CocoaWebResourceViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showImageViewControllerWithPath:(NSString *)path
{
    ImageViewerViewController *viewController = [[ImageViewerViewController alloc] initWithNibName:@"ImageViewerViewController" bundle:nil path:path startIdx:[_cacheDict[path][@"idx"] integerValue]];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)fillDetailCell:(UITableViewCell *)cell withImagesInPath:(NSString *)path
{
    CGFloat x = 0;
    if (_isEditingMode) {
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        selectButton.frame = CGRectMake(0, kImageTableCellHeight / 2 - 15, 30, 30);
        selectButton.backgroundColor = [UIColor clearColor];
        selectButton.showsTouchWhenHighlighted = YES;
        [selectButton setImage:[UIImage imageNamed:@"bulletNotSelected.png"] forState:UIControlStateNormal];
        [selectButton setImage:[UIImage imageNamed:@"bulletSelected.png"] forState:UIControlStateSelected];
        [selectButton addTarget:self action:@selector(cellSelectBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        x += 40;
        selectButton.tag = 101;
        selectButton.titleLabel.text = path;
        selectButton.titleLabel.hidden = YES;
        selectButton.selected = [_selectedPathArray containsObject:path];
        [cell addSubview:selectButton];
    }

    CGRect rect = CGRectMake(4 + x, 5, kImageTableCellHeight - 10, kImageTableCellHeight - 10);
    UIImageView *imageView = [self imageViewForPath:path];
    imageView.frame = rect;
    imageView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath];
    [cell addSubview:imageView];
    
    x += kImageTableCellHeight + 10;
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 5, 200, kImageTableCellHeight - 10)];
    textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    textLabel.text = [path lastPathComponent];
    textLabel.tag = 100;
    textLabel.font =  [UIFont boldSystemFontOfSize:17.0];
    [cell addSubview:textLabel];
}

- (UIImageView *)imageViewForPath:(NSString *)path
{
    if (_cacheDict[path] != nil && _cacheDict[path][@"image"] != nil) {
        return _cacheDict[path][@"image"];
    }
    
    UIImageView *imageView = nil;
    if ([FileManager isZIPFile:path]) {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zip.png"]];
    } else if ([FileManager isGIFFile:path]) {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gif.png"]];
    } else if ([FileManager isPICFile:path]) {
        imageView = [[PicThumbImageView alloc] init];
        [(PicThumbImageView *)imageView setImageWithPicPath:path placeholderImage:[UIImage imageNamed:@"pic.png"]];
    } else if ([FileManager isVideoFile:path]) {
        imageView = [[VideoThumbImageView alloc] init];
        [(VideoThumbImageView *)imageView setImageWithVideoPath:path placeholderImage:[UIImage imageNamed:@"video.png"]];
    }

    if (imageView != nil) {
        if (!_isListMode)
            _cacheDict[path] = @{@"idx": @(0), @"image":imageView};
        imageView.tag = 99;
        return imageView;
    }
    
    // if path is dir, select and show a pic as dir's cover
    if (![FileManager isDirPath:path]) {
        return nil;
    }
    NSMutableArray *filesInPathArray = [NSMutableArray arrayWithArray: [FileManager filesOfPath:path]];
    if (filesInPathArray.count == 0) {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"folder.png"]];
        imageView.tag = 99;
        return imageView;
    }

    NSInteger idx = arc4random() % [filesInPathArray count];
    NSString *fileName = filesInPathArray[idx];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) { // cache error
        NSLog(@"%s cache error: file not exist. clear cache.", __FUNCTION__);
        [self clearCache];
        return nil;
    }
    if ([FileManager isGIFFile:fileName]) {
        imageView = [[SCGIFImageView alloc] initWithGIFFile:filePath];
    } else {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        imageView = [[UIImageView alloc] initWithImage:image];
    }
    
    imageView.tag = 99;
    imageView.layer.shadowOffset = CGSizeMake(1, 1);
    imageView.layer.shadowOpacity = 1;
    imageView.layer.shadowColor = [[UIColor grayColor] CGColor];
    _cacheDict[path] = @{@"idx": @(idx), @"image":imageView};
    return imageView;
}

- (IBAction)play:(id)sender
{
    if ([self.contentArray count] == 0) {
        return;
    }
    [self showImageViewControllerWithPath:_rootPath];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)textInputDone:(NSString *)text
{
    NSLog(@"%s %@", __func__, text);
    
    if ([text length] == 0)
        return;

    if ([_action isEqualToString:@"create"]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[_rootPath stringByAppendingPathComponent:text ] withIntermediateDirectories:NO attributes:nil error:&error];
        if (error != nil) {
            NSLog(@"%s create failed: %@", __FUNCTION__, error.userInfo[@"NSUnderlyingError"]);
            [self showAlertMessage:@"Create Failed."];
        }
        [self initData];
        [_tableView reloadData];

    } else if ([_action isEqualToString:@"rename"]) {
    
        NSString *oldPath = _selectedPathArray[0];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[oldPath pathComponents]];
        [pathComponents removeLastObject];
        [pathComponents addObject:text];

        NSString *newPath = [NSString pathWithComponents:pathComponents];
        NSLog(@"%s, old name [%@], new name [%@]", __FUNCTION__, oldPath, newPath);
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
        if (error != nil) {
            NSLog(@"%s rename failed: %@", __FUNCTION__, error.description);
            [self showAlertMessage:@"Rename Failed."];
        }
        [self initData];
        [_tableView reloadData];
    }
//    [self hideFileActionView];
    [_selectedPathArray removeAllObjects];
    [self configActionButtonsStatus];
}

- (void)cellSelectBtnClicked:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.selected;
    btn.selected ? [_selectedPathArray addObject: btn.titleLabel.text] : [_selectedPathArray removeObject:btn.titleLabel.text];

    [self configActionButtonsStatus];
}

- (void)quickViewImage:(UIImageView *)imageView
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    view.alpha = 0;
    view.tag = 1985;
    view.backgroundColor = [UIColor whiteColor];

    imageView.frame = CGRectMake(0, 0, MIN(imageView.image.size.width, self.view.frame.size.width), MIN(imageView.image.size.height, self.view.frame.size.height));
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center = view.center;

    [view addSubview:imageView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quickViewTaped)];
    [view addGestureRecognizer:tapGesture];
    [self.view addSubview:view];
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 1;
        self.navigationController.navigationBar.alpha = 0;
    } completion:^(BOOL finished) {

    }];
}

- (void)quickViewTaped
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    CGRect rect = self.navigationController.navigationBar.frame;
    rect.origin.y = 20;
    self.navigationController.navigationBar.frame = rect;

    UIView *view = [self.view viewWithTag:1985];
    view.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 0;
        self.navigationController.navigationBar.alpha = 1;
    } completion: ^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

#pragma mark -
#pragma mark Table View Data Source Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (_isListMode) {
        static NSString *ListCellIdentifier = @"ListCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier];
        }
        [[cell viewWithTag:99] removeFromSuperview];
        [[cell viewWithTag:100] removeFromSuperview];
        [[cell viewWithTag:101] removeFromSuperview];
        
        if (_contentArray.count == 0) {
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.text = @"还没有图片，可通过wifi上传";
            return cell;
        } else {
//            cell.textLabel.font = [UIFont systemFontOfSize:17];
//            cell.textLabel.textColor = [UIColor blackColor];
//            cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        }

        cell.textLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        NSString *path = [_rootPath stringByAppendingPathComponent:_contentArray[indexPath.row]];
        [self fillDetailCell:cell withImagesInPath:path];

        return cell;

    } else {

        AssetsGroupsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AssetsCell"];
        cell.rowNumber = indexPath.row;
        cell.selectionDelegate = self;
        
        // Configure the cell.
        NSUInteger leftGroupIndex = indexPath.row * 2;
        NSUInteger rightGroupIndex = leftGroupIndex + 1;

        NSString *path = [_rootPath stringByAppendingPathComponent:_contentArray[leftGroupIndex]];
        UIImageView *leftPoster = [self imageViewForPath:path];
        [cell setLeftPosterImage:leftPoster];
        [cell setLeftLabelText:_contentArray[leftGroupIndex]];

        if ((indexPath.row + 1) * 2 <= _contentArray.count) {
            path = [_rootPath stringByAppendingPathComponent:_contentArray[rightGroupIndex]];
            UIImageView *rightPoster = [self imageViewForPath:path];
            [cell setRightPosterImage:rightPoster];
            [cell setRightLabelText:_contentArray[rightGroupIndex]];
        } else {
            [cell setRightPosterImage:nil];
            [cell setRightLabelText:nil];
        }
        
        return cell;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isListMode) {
        tableView.separatorColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1];
    } else {
        tableView.separatorColor = [UIColor clearColor];
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isListMode) {
        
        if (_contentArray.count == 0) {
            return 44;
        }
        return kImageTableCellHeight;
    } else {
        return kThumbnailCellHeight;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_contentArray.count == 0) {
        return 1;
    }

    return _isListMode ? _contentArray.count : ceil((float)_contentArray.count / 2);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_isListMode) {
        if (_contentArray.count == 0) {
            [self wifi:nil];
            return;
        }
        NSString *path = [_rootPath stringByAppendingPathComponent:_contentArray[indexPath.row]];
        if ([FileManager isDirPath:path] == NO) {
//            NSLog(@"%s Click on a file.", __func__);

            if ([FileManager isGIFFile:path]) {

                UIImageView *imageView = [[SCGIFImageView alloc] initWithGIFFile:path];
                [self quickViewImage:imageView];

            } else if ([FileManager isPICFile:path]) {

                UIImage *image = [UIImage imageWithContentsOfFile:path];
                CGSize size = CGSizeMake( MIN(image.size.width, self.view.frame.size.width), MIN(image.size.height, self.view.frame.size.height));
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[image resizeToSize:size keepAspectRatio:YES]];
                [self quickViewImage:imageView];
            }

        } else {
            [self.navigationController.navigationBar setBackButtonTitle:_contentArray[indexPath.row] target:self action:@selector(backToParentFolder)];
            self.rootPath = path;
            [self initData];
            [self.tableView reloadData];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _isListMode ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    _action = @"delete";
    NSString *path = [_rootPath stringByAppendingPathComponent:_contentArray[indexPath.row]];
    NSLog(@"%s about to delete folder [%@]", __func__, path);
    [_selectedPathArray removeAllObjects];
    _selectedPathArray[0] = path;
    [self doAction];
}

#pragma mark -
#pragma mark AssetsGroupsTableViewCellSelectionDelegate
- (void)assetsGroupsTableViewCell:(AssetsGroupsTableViewCell *)cell selectedGroupAtIndex:(NSUInteger)index {
    
    [self selectAsset:(cell.rowNumber * 2) + index];
}

- (void)selectAsset:(NSInteger)index
{
    NSString *path = [_rootPath stringByAppendingPathComponent:_contentArray[index]];
    NSLog(@"%s %@", __func__, path);
    
    if ([FileManager isZIPFile:path]) {
        NSString *fileName = _contentArray[index];
        NSString *folder = [path stringByDeletingPathExtension];
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
        [self unzipFile:fileName toFolder:folder];
        [self removeRubbishInFolder:folder];
        [self refresh:nil];
        return;
    }

    if ([FileManager isVideoFile:path]) {
        [self playVideo:path];
        return;
    }

    if ([FileManager isDirPath:path]) {
        [self showImageViewControllerWithPath:path];
        return;
    }
}

- (void)removeRubbishInFolder:(NSString *)path
{
    NSArray *rubbishNameArray = @[@"__MACOSX", @".DS_Store"];
    for (NSString *name in rubbishNameArray) {
        NSString *toRemovePath = [path stringByAppendingPathComponent: name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:toRemovePath]) {
            NSLog(@"%s about to remove rubbish folder:%@", __func__, toRemovePath);
            [[NSFileManager defaultManager] removeItemAtPath:toRemovePath error:nil];
        }
    }
}

- (void)playVideo:(NSString *)path
{
    // increase buffering for .wmv, it solves problem with delaying audio frames
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([path.pathExtension isEqualToString:@"wmv"])
        parameters[KxMovieParameterMinBufferedDuration] = @(5.0);

    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    
    // disable buffering
    //parameters[KxMovieParameterMinBufferedDuration] = @(0.0f);
    //parameters[KxMovieParameterMaxBufferedDuration] = @(0.0f);
    
    KxMovieViewController *vc = [KxMovieViewController movieViewControllerWithContentPath:path
                                                                               parameters:parameters];
    [self presentViewController:vc animated:YES completion:nil];
}
@end
