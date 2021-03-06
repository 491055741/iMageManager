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

#import "IJKMediaControl.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@implementation IJKMediaControl
{
    BOOL _isMediaSliderBeingDragged;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    self.bottomPanel.tag = kBottomPanelTag;
    self.mediaProgressSlider.tag = kBottomPanelTag;
    self.playButton.tag = self.pauseButton.tag = self.currentTimeLabel.tag = self.totalDurationLabel.tag = kBottomPanelTag;
    
    [self refreshMediaControl];
    [super awakeFromNib];
}

- (void)showNoFade
{
    self.overlayPanel.hidden = NO;
    [self cancelDelayedHide];
    [self refreshMediaControl];
}

- (void)showAndFade
{
    [self showNoFade];
    [self performSelector:@selector(fadeOut) withObject:nil afterDelay:3];
}

- (void)fadeOut
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.6];
    [self.overlayPanel setAlpha:0.0f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hide)];
    [UIView commitAnimations];
}

- (void)hide
{
    self.overlayPanel.hidden = YES;
    [self.overlayPanel setAlpha:1];
    [self cancelDelayedHide];
    if (self.delegate) {
        [self.delegate mediaControlDidHide];
    }
}

- (void)cancelDelayedHide
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
}

- (void)beginDragMediaSlider
{
    _isMediaSliderBeingDragged = YES;
}

- (void)endDragMediaSlider
{
    _isMediaSliderBeingDragged = NO;
}

- (void)continueDragMediaSlider
{
    [self refreshMediaControl];
}

- (NSString *)getSysTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSDate *datenow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:datenow];
//    NSLog(@"currentTimeString =  %@",currentTimeString);
    return currentTimeString;
}

- (void)refreshMediaControl
{
    self.timeLabel.text = [self getSysTime];
    
    // duration
    NSTimeInterval duration = self.delegatePlayer.duration;
    NSInteger intDuration = duration + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.maximumValue = duration;
        self.totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    } else {
        self.totalDurationLabel.text = @"--:--";
        self.mediaProgressSlider.maximumValue = 1.0f;
    }


    // position
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.mediaProgressSlider.value;
    } else {
        position = self.delegatePlayer.currentPlaybackTime;
    }
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.value = position;
    } else {
        self.mediaProgressSlider.value = 0.0f;
    }
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];


    // status
    BOOL isPlaying = [self.delegatePlayer isPlaying];
    self.playButton.hidden = isPlaying;
    self.pauseButton.hidden = !isPlaying;


    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    if (!self.overlayPanel.hidden) {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
}

#pragma mark IBAction

@end
