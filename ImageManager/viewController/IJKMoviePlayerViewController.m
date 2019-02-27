/*
 * Copyright (C) 2013-2015 Bilibili
 * Copyright (C) 2013-2015 Zhang Rui <bbcallen@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "IJKMoviePlayerViewController.h"
#import "IJKMediaControl.h"
#import "UIDevice+Ext.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,//左右手势
    DirectionUpOrDown,//上下手势
    DirectionNone//没有手势
};

@interface IJKVideoViewController() <UIGestureRecognizerDelegate, IJKMediaControlDelegate>


@property(atomic,strong) NSURL *url;
@property(atomic, retain) id<IJKMediaPlayback> player;

- (id)initWithURL:(NSURL *)url;


- (IBAction)onClickMediaControl:(id)sender;
- (IBAction)onClickOverlay:(id)sender;
- (IBAction)onClickDone:(id)sender;
- (IBAction)onClickPlay:(id)sender;
- (IBAction)onClickFastforward:(id)sender;
- (IBAction)onClickFastbackward:(id)sender;
- (IBAction)onClickPause:(id)sender;

- (IBAction)didSliderTouchDown;
- (IBAction)didSliderTouchCancel;
- (IBAction)didSliderTouchUpOutside;
- (IBAction)didSliderTouchUpInside;
- (IBAction)didSliderValueChanged;

@property(nonatomic,strong) IBOutlet IJKMediaControl *mediaControl;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) float originalVolume;
@property (assign, nonatomic) Direction direction;  // pan gesture direction
@property (assign, nonatomic) CGFloat sumTime;      // 临时保存当前播放时间秒数

@end

@implementation IJKVideoViewController

- (void)dealloc
{
}

+ (void)presentFromViewController:(UIViewController *)viewController withTitle:(NSString *)title URL:(NSURL *)url completion:(void (^)())completion {

    [viewController presentViewController:[[IJKVideoViewController alloc] initWithURL:url] animated:YES completion:completion];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [self initWithNibName:@"IJKMoviePlayerViewController" bundle:nil];
    if (self) {
        self.url = url;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

#define EXPECTED_IJKPLAYER_VERSION (1 << 16) & 0xFF) | 
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_SILENT];
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];

    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setOptionIntValue:1 forKey:@"videotoolbox" ofCategory:kIJKFFOptionCategoryPlayer];

    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.view.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;

    self.view.autoresizesSubviews = YES;
    
    self.mediaControl.delegate = self;
    self.mediaControl.frame = self.view.bounds;
    [self.view addSubview:self.player.view];
    [self.view addSubview:self.mediaControl];
    self.mediaControl.titleLabel.text = [self.url lastPathComponent];
    self.mediaControl.delegatePlayer = self.player;
    [self.mediaControl showAndFade];
    [self setupUserInteraction];

    _originalVolume = [[AVAudioSession sharedInstance] outputVolume]; // can't get volume via applicationMusicPlayer
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.05]; // 0 ~ 1.0f
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.player prepareToPlay];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:_originalVolume];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [self.player shutdown];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaControlDidHide
{
}

#pragma mark IBAction

- (IBAction)onClickMediaControl:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    //[self.mediaControl showAndFade];
}

- (IBAction)onClickOverlay:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    //[self.mediaControl hide];
}

- (IBAction)onClickDone:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self.player stop];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickPlay:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self.player play];
    [self.mediaControl refreshMediaControl];
}

- (IBAction)onClickPause:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self.player pause];
    [self.mediaControl refreshMediaControl];
}

- (IBAction)onClickFastforward:(id)sender
{
    NSLog(@"%s", __func__);
    const CGFloat ff = 30;
    self.player.currentPlaybackTime += ff;
}

- (IBAction)onClickFastbackward:(id)sender
{
    NSLog(@"%s", __func__);
    const CGFloat ff = -30;
    self.player.currentPlaybackTime += ff;
}

- (IBAction)didSliderTouchDown
{
    NSLog(@"%s", __FUNCTION__);
    [self.mediaControl beginDragMediaSlider];
}

- (IBAction)didSliderTouchCancel
{
    NSLog(@"%s", __FUNCTION__);
    [self.mediaControl endDragMediaSlider];
}

- (IBAction)didSliderTouchUpOutside
{
    NSLog(@"%s", __FUNCTION__);
    [self.mediaControl endDragMediaSlider];
}

- (IBAction)didSliderTouchUpInside
{
    NSLog(@"%s", __FUNCTION__);
    self.player.currentPlaybackTime = self.mediaControl.mediaProgressSlider.value;
    [self.mediaControl endDragMediaSlider];
}

- (IBAction)didSliderValueChanged
{
    [self.mediaControl continueDragMediaSlider];
}

- (void)setupUserInteraction
{
    UIView * view = [self view];
    view.userInteractionEnabled = YES;

    // single tap to show controller
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.numberOfTapsRequired = 1;

    // double tap to exit
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickDone:)];
    _doubleTapGestureRecognizer.delegate = self;
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];

    [view addGestureRecognizer:_tapGestureRecognizer];
    [view addGestureRecognizer:_doubleTapGestureRecognizer];
    [view addGestureRecognizer:_panGestureRecognizer];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    // 获取当前页面手指触摸的点
    // CGPoint locationPoint = [pan locationInView:self.view];
    // 移动速率，表示手势的快慢
    CGPoint veloctyPoint = [pan velocityInView:self.view];

    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                self.direction = DirectionLeftOrRight;
                // 记录滑动时播放器的时间
                self.sumTime  = self.player.currentPlaybackTime;
                // 暂停视频播放
                [self.player pause];
            } else if (x < y){ // 垂直移动
                // 音量
                self.direction = DirectionUpOrDown;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: // 正在移动
        {
            switch (self.direction) {//通过手势变量来判断是什么操作
                case DirectionUpOrDown://上下滑动
                {
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                case DirectionLeftOrRight:
                {
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                default:
                    break;
            }
            break;
            
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            switch (self.direction) {
                case DirectionUpOrDown: // 垂直
                {
                    break;
                }
                case DirectionLeftOrRight: //水平
                {
                    self.player.currentPlaybackTime = self.sumTime;
                    [self.player play];
                    break;
                }
                default:
                    break;
            }
        }
        default:
            break;
    }
}

- (void)horizontalMoved:(CGFloat)value
{
    // 播放进度控制
    NSLog(@"%s %f",__FUNCTION__, value);
    self.sumTime += value/100;
    self.mediaControl.mediaProgressSlider.value = self.sumTime;
}

- (void)verticalMoved:(CGFloat)value
{
    // 音量控制
    CGFloat volumeChangeValue = value/10000;
    NSLog(@"Volume change: %f", volumeChangeValue);
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    if (fabsf(musicPlayer.volume - volumeChangeValue) < 0.03) {
        musicPlayer.volume = 0;
    } else {
        musicPlayer.volume -= volumeChangeValue; // from 0 to 1.0
    }
}

- (void)handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == _tapGestureRecognizer) {
            NSLog(@"%s", __func__);
            if ([self.mediaControl.overlayPanel isHidden]) {
                [self.mediaControl showNoFade];
            } else {
                [self.mediaControl fadeOut];
            }
        }
    }
}


#pragma mark--
#pragma mark--UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view.tag == kBottomPanelTag)
    {
        return NO;
    }
    return YES;
}
// end

@end
