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
#import "NSObject+ScreenSize.h"
#import "ZipArchive.h"
#import "FileManager.h"
#import "SCGIFImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "VideoThumbImageView.h"
#import "PicThumbImageView.h"
#import "UINavigationBar+Ext.h"
#import "UIImage+Ext.h"
#import "ImageCell.h"
#import "InputView.h"
#import "IJKMoviePlayerViewController.h"
#import "FolderSelectionViewController.h"
#import "UIDevice+Ext.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define kImageTableCellHeight 74
#define kThumbnailCellHeight 170

#define kInputViewTag 10
#define kMaskViewTag 88
#define kFileActionViewTag 999

@interface SectionHeaderView : UICollectionReusableView

@property (nonatomic, strong) UILabel *label;
@end

@implementation SectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 40)];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor darkGrayColor];
        [self addSubview:_label];
    }
    return self;
}

@end

@interface BrowseViewController () <FolderSelectionDelegate, InputViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate >

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UIView *fileActionView;// use strong to retain it when remove frow superView
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) NSArray *contentArray;
@property (nonatomic, strong) NSMutableArray *selectedPathArray;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) UIBarButtonItem *editBarBtn;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, assign) BOOL isEditingMode;
@property (nonatomic, assign) BOOL isBrowsingMode;
// action buttons
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *deselectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *moveBtn;
@property (weak, nonatomic) IBOutlet UIButton *renameBtn;
@property (weak, nonatomic) IBOutlet UIButton *createDirBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

@implementation BrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.rootPath = [FileManager rootPath];
        NSLog(@"%s %@", __func__, _rootPath);
        [self initData];
        self.cache = [[NSCache alloc] init];
        [_cache setCountLimit:50];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"iMage Manager";
    

//    [_collectionView addGestureRecognizer:_tap];
    [_collectionView registerNib:[UINib nibWithNibName:@"ImageCell" bundle:nil] forCellWithReuseIdentifier:kImageCellId];
    [_collectionView registerClass:[SectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    _collectionView.allowsMultipleSelection = YES;
    [self updateActionButtonsStatus];
    [self configEditBtn];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([self.view viewWithTag:kFileActionViewTag]) {
        CGRect rect = CGRectMake(0, self.view.frame.size.height - _fileActionView.frame.size.height, self.view.frame.size.width, _fileActionView.frame.size.height);
        _fileActionView.frame = rect;
    }
    
    UIView *inputView = [self.view viewWithTag:kInputViewTag];
    if (inputView) {
        CGRect rect = inputView.frame;
        rect.size.width = self.view.frame.size.width;
        inputView.frame = rect;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && self.view.window == nil) { // not current view
        self.view = nil;
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)refresh:(id)sender
{
    [self showIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [FileManager moveAllToRootFolder];
        [self clearCache];
        [self initData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_collectionView reloadData];
            [self hideIndicator];
        });
    });
}

- (IBAction)switchBrowsingMode
{
    _isBrowsingMode = !_isBrowsingMode;
    _collectionView.backgroundColor = _isBrowsingMode ? [UIColor lightGrayColor] : [UIColor whiteColor];
    
    self.title = _isBrowsingMode ? @"Browse Mode" : @"iMage Manager";
    self.navigationController.navigationBar.barStyle = _isBrowsingMode ? UIBarStyleDefault : UIBarStyleBlack;
    _isEditingMode = NO;
    [self updateEditBtn];
    [_collectionView reloadData];
}

- (IBAction)createDir:(id)sender
{
    self.action = @"create";
    [self showInputViewTitle:@"创建目录" defaultValue:@"" placeHolder:@"目录名"];
    [self doAction];
}

- (IBAction)move:(id)sender
{
    self.action = @"move";
    [self doAction];
}

- (IBAction)selectAll:(id)sender
{
    [_selectedPathArray removeAllObjects];
    for (NSArray *array in _contentArray) {
        for (NSString *path in array) {
            [_selectedPathArray addObject: [_rootPath stringByAppendingPathComponent:path]];
        }
    }
    
    [_collectionView reloadData];
    [self updateActionButtonsStatus];
    _selectAllBtn.enabled = NO;
}

- (IBAction)deselectAll:(id)sender
{
    [_selectedPathArray removeAllObjects];
    [_collectionView reloadData];
    
    [self updateActionButtonsStatus];
}

// delete multiple files
- (IBAction)delete:(id)sender
{
    [self showAlertMessage:[NSString stringWithFormat:@"要删除%lu个文件吗？", [_selectedPathArray count]] title:@"确认删除" tag:1 delegate:self];
}

- (IBAction)rename:(id)sender
{
    if ([_selectedPathArray count] == 0)
        return;
    self.action = @"rename";
    [self doAction];
}

- (IBAction)wifi:(id)sender
{
    UIViewController *viewController = [[NSClassFromString(@"WebServerViewController") alloc] initWithNibName:@"WebServerViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)play:(id)sender
{
    if ([_contentArray count] == 0) {
        return;
    }
    [self showImageViewControllerWithPath:_rootPath];
}

#pragma mark -
#pragma mark private method
- (void)initData
{
    NSMutableArray *videoArray = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *allItemsArray = [NSMutableArray arrayWithArray:[FileManager contentsOfPath:_rootPath]];
    
    // sort the array, keep dir on head, move files to tail
    NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:200];
    for (NSString *path in allItemsArray) {
        if (![FileManager isDirPath:[_rootPath stringByAppendingPathComponent:path]]
            ) {
            if ([FileManager isVideoFile:path]) {
                [videoArray addObject:path];
            } else {
                [fileArray addObject:path];
            }
        }
    }
    // sort files with file type
    [fileArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *path1 = obj1;
        NSString *path2 = obj2;
        return [[path1 pathExtension] compare:[path2 pathExtension]];
    }];
    [allItemsArray removeObjectsInArray:fileArray];
    [allItemsArray removeObjectsInArray:videoArray];
    [allItemsArray addObjectsFromArray:fileArray];
    
    self.contentArray = @[allItemsArray, videoArray]; // todo : consider nil
    self.selectedPathArray = [NSMutableArray arrayWithCapacity:100];
}

- (void)clearCache
{
    [VideoThumbImageView clearCache];
    [FileManager clearCache];
    [_cache removeAllObjects];
}

- (void)configEditBtn {
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editButton.frame = CGRectMake(0, 0, 50, 30);
    [editButton setBackgroundImage:[UIImage imageNamed:@"blackBtn.png"] forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(switchEditingMode) forControlEvents:UIControlEventTouchUpInside];
    [editButton setTitle:@"Edit" forState:UIControlStateNormal];
    editButton.titleLabel.textColor = [UIColor whiteColor];
    editButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.editBarBtn = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    self.navigationItem.rightBarButtonItem = _editBarBtn;
}

- (void)observeKeyboardNotify
{
    // 监听键盘尺寸改变（包含键盘弹出）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    // 监听收回键盘
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(keyboardDidHide:)
    //                                                 name:UIKeyboardDidHideNotification
    //                                               object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    
    NSDictionary *info = [notification userInfo];
    //获取改变尺寸后的键盘的frame
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:0.2 animations:^{
        UIView *inputView = [self.view viewWithTag:kInputViewTag];
        CGRect frame = inputView.frame;
        float screenHeight = SCREEN_HEIGHT;
        frame.origin.y = screenHeight - endKeyboardRect.size.height - frame.size.height;
        //如果是监听键盘尺寸改变 一定要用计算最终高度的方式来计算 如果用控件自加自减的方式会出错
        inputView.frame = frame;
    }];
}

- (void)updateActionButtonsStatus
{
    _selectAllBtn.enabled   = YES;
    _deselectAllBtn.enabled = ([_selectedPathArray count] > 0);
    _deleteBtn.enabled      = ([_selectedPathArray count] > 0);
    _moveBtn.enabled        = ([_selectedPathArray count] > 0);
    _renameBtn.enabled      = ([_selectedPathArray count] == 1);
    _createDirBtn.enabled   = ([_selectedPathArray count] == 0);
}

- (void)backToParentFolder
{
    self.rootPath = [_rootPath stringByDeletingLastPathComponent];
    [self initData];
    [_collectionView reloadData];

    if ([_rootPath isEqualToString:[FileManager rootPath]]) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        [self.navigationController.navigationBar setBackButtonTitle:[_rootPath lastPathComponent] target:self action:@selector(backToParentFolder)];
    }
}

- (void)switchEditingMode
{
    _isEditingMode = ! _isEditingMode;

    if (_isEditingMode) {
        [self updateActionButtonsStatus];
        [self showFileActionView];
    } else {
        [self hideInputView];
        [self hideFileActionView];
        [_selectedPathArray removeAllObjects];
    }
    [_collectionView reloadData];
    [self updateEditBtn];
}

- (void)updateEditBtn
{
    UIButton *btn = (UIButton *)_editBarBtn.customView;
    [btn setTitle:(_isEditingMode ? @"Done" : @"Edit") forState:UIControlStateNormal];
}

- (void)showFileActionView
{
    self.toolbar.hidden = YES;
    
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

- (void)hideFileActionView
{
    CGRect startRect = CGRectMake(0, self.view.frame.size.height - _fileActionView.frame.size.height, _fileActionView.frame.size.width, _fileActionView.frame.size.height);
    CGRect endRect = CGRectMake(0, self.view.frame.size.height, _fileActionView.frame.size.width, _fileActionView.frame.size.height);

    _fileActionView.frame = startRect;
    [self.view addSubview:_fileActionView];
    [UIView animateWithDuration:0.3 animations:^{
        _fileActionView.frame = endRect;
    } completion:^(BOOL finished) {
        self.toolbar.hidden = NO;
        [_fileActionView removeFromSuperview];
    }];
}

//- (void)backgroundTaped
//{
//    [self hideFileActionView];
//    [self hideInputView];
//}

- (void)showInputViewTitle:(NSString *)title defaultValue:(NSString *)defaultValue placeHolder:(NSString *)placeHolder
{
    [[self.view viewWithTag:kInputViewTag] removeFromSuperview];
    InputView *inputView = getObjectFromNib(@"InputView", @"InputView");
    inputView.tag = kInputViewTag;
    CGRect frame = inputView.frame;
    frame.size.width = SCREEN_WIDTH;
    inputView.frame = frame;
    inputView.delegate = self;
    [inputView setTitle:title defaultValue:defaultValue placeholder:placeHolder];
    [self observeKeyboardNotify];
    [self.view addSubview:inputView];
}

- (void)hideInputView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    InputView *inputView = (InputView *)[self.view viewWithTag:kInputViewTag];
    [inputView teardown];
    [inputView removeFromSuperview];
}

- (void)doAction
{
    if ([_action isEqualToString:@"move"]) {

        [self showFolderSelectionView];

    } else if ([_action isEqualToString:@"rename"]) {

        [self showInputViewTitle:@"改名" defaultValue:[_selectedPathArray[0] lastPathComponent] placeHolder:@"新文件名"];

    } else if ([_action isEqualToString:@"delete"]) {
        NSLog(@"%s delete folder %@", __func__, _selectedPathArray[0]);
        [[NSFileManager defaultManager] removeItemAtPath:_selectedPathArray[0] error:nil];
        [self initData];
        [_collectionView reloadData];
    }
}

// move file to path, select dst path
- (void)showFolderSelectionView
{
    FolderSelectionViewController *viewController = [[FolderSelectionViewController alloc] initWithNibName:@"FolderSelectionViewController" bundle:nil basePath:[FileManager rootPath]];
    viewController.delegate = self;
    viewController.title = @"Move To";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    nav.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

// move file to path selection done
- (void)pathSelected:(NSString *)toPath
{
    [self showIndicator];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSInteger failCount = 0;
        for (NSString *fileName in _selectedPathArray) {
            
            NSLog(@"%s move [%@] to [%@]", __func__, fileName, toPath);
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:fileName toPath:[NSString stringWithFormat:@"%@/%@", toPath, [fileName lastPathComponent]] error:&error];
            if (error != nil) {
                NSLog(@"%s [%@] move failed: %@", __FUNCTION__, fileName, error.description);
                failCount++;
            }
        }
        [self initData];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (failCount) {
                [self showAlertMessage:[NSString stringWithFormat:@"%ld个文件移动失败。", failCount]];
            }

            [self updateActionButtonsStatus];
            [self hideIndicator];
            [self switchEditingMode];
            [self hideFileActionView];
            [_collectionView reloadData];
        });
    });
}

- (void)showImageViewControllerWithPath:(NSString *)path
{
    ImageViewerViewController *viewController = [[ImageViewerViewController alloc] initWithNibName:@"ImageViewerViewController" bundle:nil path:path startIdx:[[_cache objectForKey:path][@"idx"] integerValue]];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (UIImageView *)imageViewForPath:(NSString *)path
{
    UIImageView *imageView = nil;
    NSInteger idx = 0;

    if (_isBrowsingMode && [FileManager isDirPath:path]) {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"folder.png"]];
        imageView.tag = 99;
    } else {
        if ([_cache objectForKey:path] && [_cache objectForKey:path][@"image"]) {
//            NSLog(@"cache hit for key: %@", path);
            return [_cache objectForKey:path][@"image"];
        } else {
//            NSLog(@"cache miss for key: %@", path);
        }

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
        } else if ([FileManager isDirPath:path]) {
            // folder thumbnail, random select a pic as dir's cover
            NSMutableArray *filesInPathArray = [NSMutableArray arrayWithArray: [FileManager filesOfPath:path]];
            if (filesInPathArray.count == 0) {
                imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"folder.png"]];
                imageView.tag = 99;
            } else {
                idx = arc4random() % [filesInPathArray count];
                NSString *fileName = filesInPathArray[idx];
                NSString *filePath = [path stringByAppendingPathComponent:fileName];

                if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    NSLog(@"%s error: file not exist. ", __FUNCTION__);
                    return nil;
                }
                if ([FileManager isGIFFile:fileName]) {
                    imageView = [[SCGIFImageView alloc] initWithGIFFile:filePath];
                } else {
                    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                    imageView = [[UIImageView alloc] initWithImage:[image resizeToSize:kImageCellSize]];
                }

                imageView.tag = 99;
                imageView.layer.shadowOffset = CGSizeMake(1, 1);
                imageView.layer.shadowOpacity = 1;
                imageView.layer.shadowColor = [[UIColor grayColor] CGColor];
            }
        }
    }

    if (imageView != nil) {
        [_cache setObject:@{@"idx": @(idx), @"image":imageView} forKey:path];
        imageView.tag = 99;
        return imageView;
    }
    return nil;
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

- (void)playItem:(NSIndexPath *)indexPath
{
    NSString *name = _contentArray[indexPath.section][indexPath.row];
    NSString *path = [_rootPath stringByAppendingPathComponent:name];
    NSLog(@"%s %@", __func__, path);

    if ([FileManager isZIPFile:path]) {
        NSString *folder = [path stringByDeletingPathExtension];
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
        [self unzipFile:name toFolder:folder];
        [self removeRubbishInFolder:folder];
        [self refresh:nil];
        return;
    }

    if ([FileManager isVideoFile:path]) {
        [IJKVideoViewController presentFromViewController:self withTitle:[NSString stringWithFormat:@"File: %@", path] URL:[NSURL fileURLWithPath:path] completion:^{
        }];
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

- (void)showImageOrEnterDir:(NSString *)path
{
    if ([FileManager isDirPath:path] == NO) {
        
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
        [self.navigationController.navigationBar setBackButtonTitle:@"上一级" target:self action:@selector(backToParentFolder)];
        self.rootPath = path;
        [self initData];
        [_collectionView reloadData];
    }
}

#pragma mark -
#pragma mark utils
- (void)unzipFile:(NSString *)fileName toFolder:(NSString *)destPath
{
    [self showIndicator];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
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
        
        //通知主线程刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新，
            [self hideIndicator];
        });
    });
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

#pragma mark -
#pragma mark inputView delegate method
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
        [_collectionView reloadData];
        
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
        [self changeCacheKey:oldPath withKey:newPath];
        [_collectionView reloadData];
    }
    [self hideInputView];
    [_selectedPathArray removeAllObjects];
    [self updateActionButtonsStatus];
}

- (void)changeCacheKey:(NSString *)oldKey withKey:(NSString *)key
{
    NSObject *obj = [_cache objectForKey:oldKey];
    if (obj) {
        [_cache setObject:obj forKey:key];
        [_cache removeObjectForKey:oldKey];
    }
    // update video thumb cache and flush to file
    if ([FileManager isVideoFile:key]) {
        [VideoThumbImageView changeCacheKey:[oldKey lastPathComponent] toKey:[key lastPathComponent]];
        [VideoThumbImageView flush];
    }
}

#pragma mark -
#pragma mark Collection View Methods
- (NSInteger)numberOfSectionsInCollectionView:( UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return ((NSArray *)_contentArray[section]).count;
}

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;

    if (kind == UICollectionElementKindSectionHeader) {

        SectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        NSString *title = indexPath.section == 0 ? @"Images" : @"Videos";
        if (((NSArray *)_contentArray[indexPath.section]).count == 0) {
            title = nil;
        }
        headerView.label.text = title;
        reusableview = headerView;
    }
    return reusableview;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    ImageCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kImageCellId forIndexPath:indexPath];
    NSString *name = _contentArray[indexPath.section][indexPath.row];
    NSString *path = [_rootPath stringByAppendingPathComponent:name];
    [cell setImageView:[self imageViewForPath:path] title:name];
    cell.desc = path;
    [cell setEditing:_isEditingMode];
    [cell setChecked:[_selectedPathArray containsObject:cell.desc]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isEditingMode) {
        ImageCell *cell = (ImageCell *)[collectionView cellForItemAtIndexPath:indexPath];

        BOOL hasChecked = [_selectedPathArray containsObject:cell.desc];
        [cell setChecked:!hasChecked];
        if (hasChecked) {
            [_selectedPathArray removeObject:cell.desc];
        } else {
            [_selectedPathArray addObject: cell.desc];
        }

        [self updateActionButtonsStatus];
    } else if (_isBrowsingMode) {
        NSString *name = _contentArray[indexPath.section][indexPath.row];
        NSString *path = [_rootPath stringByAppendingPathComponent:name];
        [self showImageOrEnterDir:path];
    } else {
        [self playItem:indexPath];
    }
}

#pragma mark -
#pragma mark alertView delegate method
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1:  // delete file
        {
            if (buttonIndex == 1) { // ok
                for (NSString *path in _selectedPathArray) {
                    NSLog(@"%s deleting %@", __func__, path);
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
                [self initData];
                [_collectionView reloadData];
            }
            break;
        }
        default:
            break;
    }
}

@end
