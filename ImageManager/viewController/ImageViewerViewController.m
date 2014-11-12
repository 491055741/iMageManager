//
//  ImageViewerViewController.m
//  ImageManager
//
//  Created by li peng on 13-5-1.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "ImageViewerViewController.h"
#import "SCGIFImageView.h"
#import "NSObject+Alert.h"
#import <QuartzCore/QuartzCore.h>
#import "UINavigationBar+Ext.h"
#import "FileManager.h"
#import "UIImage+Ext.h"

#define kStaticImageDelay 3.5
#define kDynamicImageDelay 5
#define kMaxRepeatTimes 2

@interface ImageViewerViewController ()
@property (nonatomic, strong) NSMutableArray *fileArray;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger showNextDelay;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isToolBarShowing;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, assign) BOOL isAllowGesture;

- (IBAction)swipeRight:(id)sender;
- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeUp:(id)sender;
- (IBAction)swipeDown:(id)sender;
- (IBAction)tapOnView:(id)sender;
- (IBAction)deleteBtnClicked:(id)sender;
- (IBAction)playBtnClicked:(id)sender;
@end

@implementation ImageViewerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil path:(NSString *)path startIdx:(NSInteger)idx
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.path = path;
        _currentIndex = -1;
        _isToolBarShowing = YES;
        _isAllowGesture = YES;
        [self initDataWithStartIdx: idx];
    }
    return self;
}

- (void)initDataWithStartIdx:(NSInteger)startIdx
{
    self.cache = [[NSCache alloc] init];
    [_cache setCountLimit:10];
    self.fileArray = [NSMutableArray arrayWithCapacity:1000];
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[FileManager filesOfPath:_path]];

    if ([FileManager isPICFile:tempArray[startIdx]] || [FileManager isGIFFile:tempArray[startIdx]]) {
        [self.fileArray addObject:tempArray[startIdx]];
    }
    [tempArray removeObjectAtIndex:startIdx];

    while ([tempArray count] > 0) {
        NSInteger idx = arc4random() % [tempArray count];
        if ([FileManager isPICFile:tempArray[idx]] || [FileManager isGIFFile:tempArray[idx]]) {
            [self.fileArray addObject:tempArray[idx]];
        }

        [tempArray removeObjectAtIndex:idx];
    }
//    self.fileArray = [FileManager filesOfPath:_path];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%d张图片", [_fileArray count]];
    self.wantsFullScreenLayout = YES;
    [self.navigationController.navigationBar setBackButtonTitle:@"返回" target:self action:@selector(back)];
    if ([_fileArray count] == 0) {
        [self performSelector:@selector(back) withObject:nil afterDelay:0.5];
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:self.navigationController.navigationBar.hidden withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([_fileArray count] != 0) {
        [self playBtnClicked:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && self.view.window == nil) { // not current view
        self.view = nil;
    }
}

- (void)showPic
{
    NSInteger idx = _currentIndex;
    if (idx > [_fileArray count] - 1) {
        NSLog(@"%s wrong idx:%d, file count:%d", __func__, idx, [_fileArray count]);
        idx = _currentIndex = 0;
//        return;
    }
//    NSLog(@"%s %d", __func__, idx);

    UIImageView *imageView = [self imageViewOfIndex:idx];
    
    if ([imageView isKindOfClass:[SCGIFImageView class]]) {
        _showNextDelay = MIN(10, MAX(kDynamicImageDelay, imageView.animationDuration * kMaxRepeatTimes));
    } else {
        _showNextDelay = kStaticImageDelay;
    }

    imageView.tag = 999;
    [self layoutImage:imageView];
    imageView.alpha = 0;
    UIView *oldView = [self.view viewWithTag:999];

    self.view.userInteractionEnabled = NO;
    [self.view insertSubview:imageView atIndex:0];
    [UIView animateWithDuration:0.3
                     animations:^{
                         oldView.alpha = 0;
                         imageView.alpha = 1;
                     } completion:^(BOOL finished){
                         [oldView removeFromSuperview];
                         self.view.userInteractionEnabled = YES;
    }];
    [self cacheImage:[self nextIndex]];
    [self cacheImage: (_currentIndex + 2) % [_fileArray count]];
}

- (void)cacheImage:(NSInteger)idx
{
    if ([_cache objectForKey:@(idx)] != nil) {
        return;
    }
    [_cache setObject:[NSNull null] forKey:@(idx)]; // NSNull is loading flag
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_cache setObject:[self loadFile:idx] forKey:@(idx)];
//        NSLog(@"cacheImage: load image %d into cache.", idx);
    });
}

- (UIImageView *)imageViewOfIndex:(NSInteger)idx
{
    if (idx > [_fileArray count] - 1) {
        NSLog(@"%s wrong idx:%d, file count:%d", __func__, idx, [_fileArray count]);
        return nil;
    }

    if ([_cache objectForKey:@(idx)] == nil) { // miss, load into cache
        [self cacheImage:idx];
    }

    if ([_cache objectForKey:@(idx)] == [NSNull null]) {  // wait loading
        _isAllowGesture = NO;
        while ([_cache objectForKey:@(idx)] == [NSNull null]) { // wait until loading done
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
        _isAllowGesture = YES;
    }

    return [self getImageFromCache:idx];
}

- (UIImageView *)getImageFromCache:(NSInteger)idx
{
    if ([_cache objectForKey:@(idx)] != nil && [_cache objectForKey:@(idx)] != [NSNull null]) {
        NSData *data = [_cache objectForKey:@(idx)];
        UIImageView *imageView;
        if ([SCGIFImageView isGifImage:data]) {
            imageView = [[SCGIFImageView alloc] initWithGIFData:data];
        } else {
            UIImage *image = [UIImage imageWithData:data];
            NSAssert(image != nil, @"image is nil!");
            imageView = [[UIImageView alloc] initWithImage:image];
        }
        return imageView;
    }
    return nil;
}

- (NSData *)loadFile:(NSInteger)idx
{
    NSString *fileName = _fileArray[idx];
    NSString *filePath = [_path stringByAppendingPathComponent:fileName];

    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if ([SCGIFImageView isGifImage:data]) {
        return data;
    }
    UIImage *image = [UIImage imageWithData:data];
    CGSize size = CGSizeMake( MIN(image.size.width, self.view.frame.size.width), MIN(image.size.height, self.view.frame.size.height));
    UIImage *newImage = [image resizeToSize:size keepAspectRatio:YES];
    NSData *data2 = UIImageJPEGRepresentation(newImage, 0.75);
    return data2;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    self.navigationController.navigationBar.alpha = _isToolBarShowing ? 1.0 : 0.0;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self layoutImage:(SCGIFImageView *)[self.view viewWithTag:999]];
}

- (void)layoutImage:(UIImageView *)imageView
{
    imageView.frame = CGRectMake(0, 0, MIN(imageView.image.size.width, self.view.frame.size.width), MIN(imageView.image.size.height, self.view.frame.size.height));
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center = self.view.center;
    
    if (![imageView isKindOfClass:[SCGIFImageView class]])
        [self addAnimationToImageView:imageView];
}

- (NSInteger)previousIndex
{
    NSInteger index = _currentIndex;
    if (index > 0) {
        index--;
    } else {
        index = [_fileArray count] - 1;
    }
    return index;
}

- (NSInteger)nextIndex
{
    return (_currentIndex + 1) % [_fileArray count];
}

// swipe from left to right, show previous page
- (IBAction)swipeRight:(id)sender
{
    [self stopPlay];
    _currentIndex = [self previousIndex];
    [self showPic];
    [self cacheImage:[self previousIndex]];
}

// swipe to left, show next page
- (IBAction)swipeLeft:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _currentIndex = [self nextIndex];
    [self showPic];
    if (_isPlaying)
        [self performSelector:@selector(play) withObject:nil afterDelay:_showNextDelay];
}

- (void)back
{
    [self stopPlay];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteBtnClicked:(id)sender
{
    [self showAlertMessage:@"要删除这个图片吗？" title:@"确认删除" tag:1 delegate:self];
}
// direction: from bottom to top
- (IBAction)swipeUp:(id)sender
{
    [self showToolBar];
    [self back];
}

- (IBAction)swipeDown:(id)sender
{
    [self playBtnClicked:nil];
}

- (void)showToolBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    CGRect rect = self.navigationController.navigationBar.frame;
    rect.origin.y = 20;
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.frame = rect;
    [UIView animateWithDuration:0.3 animations:^{
        _toolBar.alpha = 1.0;
        self.navigationController.navigationBar.alpha = 1.0;
    } completion:^(BOOL finished) {
        _isToolBarShowing = YES;
    }];
}

- (void)hideToolBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:0.3 animations:^{
        _toolBar.alpha = 0;
        self.navigationController.navigationBar.alpha = 0;
        self.navigationController.navigationBar.hidden = YES;
    } completion:^(BOOL finished) {
        _isToolBarShowing = NO;
    }];
}

- (IBAction)tapOnView:(id)sender {
    
    NSLog(@"%s", __func__);
    if (!_isToolBarShowing) {
        [self stopPlay];
        [self showToolBar];
    } else {
        [self hideToolBar];
    }
}

- (IBAction)playBtnClicked:(id)sender
{
    if (_isToolBarShowing) {
        [self hideToolBar];
    }

    [self startPlay];
}

- (void)startPlay
{
    if (_isPlaying == YES) {
        return;
    }
    _isPlaying = YES;
    [self play];
}

- (void)play
{
    if (_isPlaying == NO) {
        return;
    }

    _currentIndex = [self nextIndex];
    [self showPic];
    [self performSelector:@selector(play) withObject:nil afterDelay:_showNextDelay];
}

- (void)stopPlay
{
    NSLog(@"%s", __func__);
    if (_isPlaying) {
        _isPlaying = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

// move file to path, select dst path
- (IBAction)showFolderSelectionView
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
    NSString *fileName = _fileArray[_currentIndex];
    NSString *filePath = [_path stringByAppendingPathComponent:fileName];

    NSLog(@"%s move [%@] to [%@]", __func__, filePath, [toPath stringByAppendingPathComponent:fileName]);
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[toPath stringByAppendingPathComponent:fileName] error:&error];
    if (error != nil) {
        NSLog(@"%s [%@] move failed: %@", __FUNCTION__, filePath, error.description);
        [self showAlertMessage:@"Move Failed."];
    } else {
        [_fileArray removeObjectAtIndex:_currentIndex];
        _currentIndex = [self nextIndex];
        [self showPic];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view.tag == 1 && _isAllowGesture) {
        return YES;
    }
    return NO;
}

#pragma mark UIImage
- (void)addAnimationToImageView:(UIImageView *)imageView
{
    CGPoint point = imageView.center;
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.duration = _showNextDelay + 1;
    positionAnimation.fillMode = kCAFillModeForwards;
    positionAnimation.autoreverses = NO;
    positionAnimation.removedOnCompletion = FALSE;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, (point.x + arc4random() % 30 - 15), (point.y + arc4random() % 30 - 15));
    CGPathAddLineToPoint(path, NULL, (point.x + arc4random() % 30 - 15), (point.y + arc4random() % 30 - 15));
    positionAnimation.path = path;
    CGPathRelease(path);
    //    NSLog(@"%d, %d", arc4random() % 100 - 50, arc4random() % 100 - 50);
    
    CABasicAnimation *scaleAnimation;
    scaleAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.delegate = self;
    scaleAnimation.duration = _showNextDelay + 1;
    scaleAnimation.repeatCount = 0;
    scaleAnimation.removedOnCompletion = FALSE;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.autoreverses = NO;
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1 + ((float)(arc4random() % 2) / 10)];
    
    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, scaleAnimation, nil];
    animationgroup.delegate = self;
    animationgroup.duration = _showNextDelay + 1;
    animationgroup.autoreverses = NO;
    animationgroup.removedOnCompletion = FALSE;
    animationgroup.fillMode = kCAFillModeForwards;
    animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [imageView.layer addAnimation:animationgroup forKey:@"Expand"];
}

#pragma mark alert
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1:  // delete file
        {
            if (buttonIndex == 1) { // ok

                NSString *fileName = _fileArray[_currentIndex];
                NSString *filePath = [_path stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                [_fileArray removeObjectAtIndex:_currentIndex];
                [_cache removeAllObjects];
                self.title = [NSString stringWithFormat:@"%d张图片", [_fileArray count]];
                [self swipeLeft:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (void)viewDidUnload
{
    [self setToolBar:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}
@end
