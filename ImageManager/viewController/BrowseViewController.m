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
#import "KxMovieViewController.h"
#import "KxMovieDecoder.h"
#import "VideoThumbImageView.h"
#import "PicThumbImageView.h"
#import "UINavigationBar+Ext.h"
#import "UIImage+Ext.h"
#import "ImageCell.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define kImageTableCellHeight 74
#define kThumbnailCellHeight 170

#define kInputViewTag 10
#define kMaskViewTag 88
#define kFileActionViewTag 999

@interface SectionHeaderView : UICollectionReusableView
{
    
}

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

@interface BrowseViewController ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UIView *fileActionView;// use strong to retain it when remove frow superView
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) NSArray *contentArray;
@property (nonatomic, strong) NSMutableArray *selectedPathArray;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) UIBarButtonItem *actionBarBtn;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, assign) BOOL isBrowseMode;
@property (nonatomic, assign) BOOL isEditingMode;

// action buttons
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *deselectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *cutBtn;
@property (weak, nonatomic) IBOutlet UIButton *renameBtn;
@property (weak, nonatomic) IBOutlet UIButton *createDirBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

@implementation BrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
//        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTaped)];
        self.rootPath = [FileManager rootPath];
        NSLog(@"%s %@", __func__, _rootPath);
        [self initData];
    }
    return self;
}

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
    self.cache = [[NSCache alloc] init];
    [_cache setCountLimit:50];
    if (![_action isEqualToString:@"cut"])
        self.selectedPathArray = [NSMutableArray arrayWithCapacity:10];
}

- (void)clearCache
{
    [VideoThumbImageView clearCache];
    [FileManager clearCache];
    [_cache removeAllObjects];
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
    [actionButton setTitle:@"Edit" forState:UIControlStateNormal];
    actionButton.titleLabel.textColor = [UIColor whiteColor];
    actionButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.actionBarBtn = [[UIBarButtonItem alloc] initWithCustomView:actionButton];

//    [_collectionView addGestureRecognizer:_tap];
    [_collectionView registerNib:[UINib nibWithNibName:@"ImageCell" bundle:nil] forCellWithReuseIdentifier:kImageCellId];
    [_collectionView registerClass:[SectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    _collectionView.allowsMultipleSelection = YES;
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
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && self.view.window == nil) { // not current view
        self.view = nil;
    }
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

- (IBAction)switchBrowseMode:(id)sender
{
    _isBrowseMode = !_isBrowseMode;
    self.title = _isBrowseMode ? @"Browse Mode" : @"iMage Manager";
    self.navigationController.navigationBar.barStyle = _isBrowseMode ? UIBarStyleDefault : UIBarStyleBlack;
    _collectionView.backgroundColor = _isBrowseMode ? [UIColor grayColor] : [UIColor whiteColor];
    _isEditingMode = NO;
    [self configActionBtn];
    [_collectionView reloadData];
}

- (void)switchEditingMode
{
    _isEditingMode = ! _isEditingMode;
    _isEditingMode ? [self showFileActionView] : [self hideFileActionView];
//    _tableView.contentInset = _isEditingMode ? UIEdgeInsetsMake(44, 0, 144, 0) : UIEdgeInsetsMake(44, 0, 44, 0);

    [_collectionView reloadData];
}

- (void)configActionBtn
{
    self.navigationItem.rightBarButtonItem = _isBrowseMode ? _actionBarBtn : nil;

    UIButton *btn = (UIButton *)_actionBarBtn.customView;
    [btn setTitle:(_isEditingMode ? @"Done" : @"Edit") forState:UIControlStateNormal];
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

- (void)hideFileActionView
{
    _isEditingMode = NO;
    [self configActionBtn];

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
            [_collectionView reloadData];
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
    [_cutBtn addTarget:self action:@selector(paste) forControlEvents:UIControlEventTouchUpInside];
    [self doAction];
}

- (void)paste
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
    for (NSArray *array in _contentArray) {
        for (NSString *path in array) {
            [_selectedPathArray addObject: [_rootPath stringByAppendingPathComponent:path]];
        }
    }

    [_collectionView reloadData];

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
    [_collectionView reloadData];

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
    [_collectionView reloadData];
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
                    break;
                }
            }
//            [self clearCache];
//            self.rootPath = [FileManager rootPath];
            [self initData];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self configActionButtonsStatus];
                [self hideIndicator];
                [self hideFileActionView];
                [_collectionView reloadData];
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
        [_collectionView reloadData];
    }
}

- (void)unzipFile:(NSString *)fileName toFolder:(NSString *)destPath
{
    [self showIndicator];
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
        [self hideIndicator];
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

- (IBAction)wifi:(id)sender
{
    UIViewController *viewController = [[NSClassFromString(@"CocoaWebResourceViewController") alloc] initWithNibName:@"CocoaWebResourceViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showImageViewControllerWithPath:(NSString *)path
{
    ImageViewerViewController *viewController = [[ImageViewerViewController alloc] initWithNibName:@"ImageViewerViewController" bundle:nil path:path startIdx:[[_cache objectForKey:path][@"idx"] integerValue]];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (UIImageView *)imageViewForPath:(NSString *)path
{
    if ([_cache objectForKey:path] && [_cache objectForKey:path][@"image"]) {
        return [_cache objectForKey:path][@"image"];
    }
    
    UIImageView *imageView = nil;
    NSInteger idx = 0;
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
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) { // cache error
                NSLog(@"%s cache error: file not exist. clear cache.", __FUNCTION__);
                [self clearCache];
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

    if (imageView != nil) {
        [_cache setObject:@{@"idx": @(idx), @"image":imageView} forKey:path];
        imageView.tag = 99;
        return imageView;
    }
    return nil;
}

- (IBAction)play:(id)sender
{
    if ([_contentArray count] == 0) {
        return;
    }
    [self showImageViewControllerWithPath:_rootPath];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([self.view viewWithTag:kFileActionViewTag] == nil) {
        return;
    }

    CGRect endRect = CGRectMake(0, self.view.frame.size.height - _fileActionView.frame.size.height, self.view.frame.size.width, _fileActionView.frame.size.height);
    _fileActionView.frame = endRect;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
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
        [_collectionView reloadData];
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

- (void)selectItem:(NSIndexPath *)indexPath
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
    [cell setSelected:[_selectedPathArray containsObject:cell.desc]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = (ImageCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (_isBrowseMode) {
        if (_isEditingMode) {
            [_selectedPathArray removeObject:cell.desc];
            [self configActionButtonsStatus];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = (ImageCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSString *name = _contentArray[indexPath.section][indexPath.row];
    if (_isBrowseMode) {
        if (_isEditingMode) {
            [_selectedPathArray addObject: cell.desc];
            [self configActionButtonsStatus];
        } else {
            NSString *path = [_rootPath stringByAppendingPathComponent:name];
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
                [self.navigationController.navigationBar setBackButtonTitle:name target:self action:@selector(backToParentFolder)];
                self.rootPath = path;
                [self initData];
                [collectionView reloadData];
            }
        }
        
    } else {
        [self selectItem:indexPath];
    }
}

@end
