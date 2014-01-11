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

@property (nonatomic, strong) NSMutableDictionary *cacheDict;
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
    self.cacheDict = [NSMutableDictionary dictionaryWithCapacity:10];
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

    [self playBtnClicked:nil];
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
        [self viewDidUnload];
        self.view = nil;
    }
    [_cacheDict removeAllObjects];
}

- (void)showPicOfIndex:(NSInteger)idx
{
    if (idx > [_fileArray count] - 1) {
        NSLog(@"%s wrong idx:%d, file count:%d", __func__, idx, [_fileArray count]);
        return;
    }
    NSLog(@"%s %d", __func__, idx);

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
}

- (void)cacheImage:(NSInteger)idx
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _cacheDict[@(idx)] = [NSNull null]; // it is loading flag
        NSString *filePath = [_path stringByAppendingPathComponent:_fileArray[idx]];
        _cacheDict[@(idx)] = [NSData dataWithContentsOfFile:filePath];
    });
}

- (UIImageView *)imageViewOfIndex:(NSInteger)idx
{
    if (idx > [_fileArray count] - 1) {
        NSLog(@"%s wrong idx:%d, file count:%d", __func__, idx, [_fileArray count]);
        return nil;
    }

    if (_cacheDict[@(idx)] == [NSNull null]) {  // loading
        _isAllowGesture = NO;
//        NSLog(@"%s wait loading...", __FUNCTION__);
        while (_cacheDict[@(idx)] == [NSNull null]) { // wait until loading done
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
//        NSLog(@"%s loading done", __FUNCTION__);
        _isAllowGesture = YES;
        return [self getImageFromCache:idx];
    } else if (_cacheDict[@(idx)] != nil) {
        return [self getImageFromCache:idx];
    } else {
        return [self loadImageView:idx];
    }
}

- (UIImageView *)getImageFromCache:(NSInteger)idx
{
    if (_cacheDict[@(idx)] != nil) {
        NSData *data = _cacheDict[@(idx)];
        [_cacheDict removeObjectForKey:@(idx)];
        UIImageView *imageView;
        if ([SCGIFImageView isGifImage:data]) {
            imageView = [[SCGIFImageView alloc] initWithGIFData:data];
        } else {
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
        }
        return imageView;
    }
    return nil;
}

- (UIImageView *)loadImageView:(NSInteger)idx
{
//    NSLog(@"%s begin-- [%d]", __FUNCTION__, idx);
//    if ([NSThread isMainThread]) {
//        NSLog(@"%s Warning! Load image in main thread!", __FUNCTION__);
//    }
    
//    [NSThread sleepForTimeInterval:2];  // for test
    
    NSString *fileName = _fileArray[idx];
    NSString *filePath = [_path stringByAppendingPathComponent:fileName];
    
    UIImageView *imageView;
    if ([FileManager isGIFFile:fileName]) {
        imageView = [[SCGIFImageView alloc] initWithGIFFile:filePath];
    } else {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        NSAssert(image != nil, @"image is nil!");
        CGSize size = CGSizeMake( MIN(image.size.width, self.view.frame.size.width), MIN(image.size.height, self.view.frame.size.height));
        imageView = [[UIImageView alloc] initWithImage:[image resizeToSize:size keepAspectRatio:YES]];
    }
//    NSLog(@"%s --end [%d] fileName:[%@].", __func__, idx, fileName);
    return imageView;
}

- (NSData *)loadFile:(NSInteger)idx
{
    NSString *fileName = _fileArray[idx];
    NSString *filePath = [_path stringByAppendingPathComponent:fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return data;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
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
    if (_currentIndex > 0) {
        _currentIndex--;
    } else {
        _currentIndex = [_fileArray count] - 1;
    }
    return _currentIndex;
}

- (NSInteger)nextIndex
{
    _currentIndex = (_currentIndex + 1) % [_fileArray count];
    return _currentIndex;
}

// swipe from left to right, show previous page
- (IBAction)swipeRight:(id)sender
{
    [self stopPlay];
    [_cacheDict removeAllObjects];
    [self cacheImage:_currentIndex];
    [self showPicOfIndex:[self previousIndex]];
}

// swipe to left, show next page
- (IBAction)swipeLeft:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
    [self showPicOfIndex:[self nextIndex]];
    [self cacheImage:(_currentIndex + 1) % _fileArray.count];
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
//    [self deleteBtnClicked:nil];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//    self.navigationController.navigationBar.alpha = 1.0;
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
    NSLog(@"%s", __func__);
    [self play];
}

- (void)play
{
    if (_isPlaying == NO) {
        return;
    }

    [self showPicOfIndex:[self nextIndex]];
    [self cacheImage:(_currentIndex + 1) % _fileArray.count];
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

- (IBAction)showFolderSelectionView
{
    FolderSelectionViewController *viewController = [[FolderSelectionViewController alloc] initWithNibName:@"FolderSelectionViewController" bundle:nil basePath:[FileManager rootPath]];
    viewController.delegate = self;
    viewController.title = @"Move To";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    nav.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController presentModalViewController:nav animated:YES];
}

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
        [self showPicOfIndex:[self nextIndex]];
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
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    switch (alertView.tag) {
        case 1:  // delete file
        {
            if (buttonIndex == 1) { // ok

                NSString *fileName = _fileArray[_currentIndex];
                NSString *filePath = [_path stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                [_fileArray removeObjectAtIndex:_currentIndex];
                [self swipeLeft:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (void)viewDidUnload {
    [self setToolBar:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}
@end
