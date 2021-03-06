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

#import <UIKit/UIKit.h>

@protocol IJKMediaPlayback;
@protocol IJKMediaControlDelegate <NSObject>
- (void)mediaControlDidHide;
@end
#define kBottomPanelTag 8899
@interface IJKMediaControl : UIControl

- (void)showNoFade;
- (void)showAndFade;
- (void)fadeOut;
- (void)refreshMediaControl;
- (void)beginDragMediaSlider;
- (void)endDragMediaSlider;
- (void)continueDragMediaSlider;

@property(nonatomic,weak) id<IJKMediaPlayback> delegatePlayer;
@property(nonatomic,weak) id<IJKMediaControlDelegate> delegate;

@property(nonatomic,strong) IBOutlet UIView *overlayPanel;
@property(nonatomic,strong) IBOutlet UIView *topPanel;
@property(nonatomic,strong) IBOutlet UIView *bottomPanel;
@property(nonatomic,strong) IBOutlet UILabel *timeLabel;        // 当前系统时间
@property(nonatomic,strong) IBOutlet UILabel *titleLabel;
@property(nonatomic,strong) IBOutlet UIButton *playButton;
@property(nonatomic,strong) IBOutlet UIButton *pauseButton;

@property(nonatomic,strong) IBOutlet UILabel *currentTimeLabel; // 当前播放时间
@property(nonatomic,strong) IBOutlet UILabel *totalDurationLabel; // 视频总时长
@property(nonatomic,strong) IBOutlet UISlider *mediaProgressSlider;


@end
