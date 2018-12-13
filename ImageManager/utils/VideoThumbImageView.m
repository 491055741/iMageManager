//
//  VideoThumbImageView.m
//  ImageManager
//
//  Created by Li Peng on 13-8-23.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "VideoThumbImageView.h"
#import "TimeMeter.h"
#import "FileManager.h"
#import "UIImage+Ext.h"
#import "KxMovieDecoder.h"

static NSMutableDictionary *videoThumbCacheDict;
static BOOL cacheDirtyFlag;

@interface VideoThumbImageView()

@end

@implementation VideoThumbImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [VideoThumbImageView loadCache];
    }
    return self;
}

+ (NSString *)cacheFilePath
{
    return [[FileManager rootPath] stringByAppendingPathComponent:kVideoThumbFileName];
}

+ (void)loadCache
{
    static dispatch_once_t onceToken;
    cacheDirtyFlag = NO;
    dispatch_once(&onceToken, ^{
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[VideoThumbImageView cacheFilePath]]) {
            videoThumbCacheDict = [NSMutableDictionary dictionaryWithContentsOfFile:[VideoThumbImageView cacheFilePath]];
        } else {
            videoThumbCacheDict = [NSMutableDictionary dictionaryWithCapacity:4];
        }
    });
}

+ (void)clearCache
{
    [videoThumbCacheDict removeAllObjects];
    cacheDirtyFlag = YES;
}

+ (void)flush
{
    if (cacheDirtyFlag)
        [videoThumbCacheDict writeToFile:[VideoThumbImageView cacheFilePath] atomically:NO];
    cacheDirtyFlag = NO;
}

+ (UIImage *)getImageFromCache:(NSString *)path
{
    NSString *fileName = [path lastPathComponent];
    if (videoThumbCacheDict[fileName]) {
        return [UIImage imageWithData:videoThumbCacheDict[fileName]];
    }
    return nil;
}

// for file rename
+ (void)changeCacheKey:(NSString *)oldKey toKey:(NSString *)key
{
    if (videoThumbCacheDict[oldKey]) {
        videoThumbCacheDict[key] = videoThumbCacheDict[oldKey];
        [videoThumbCacheDict removeObjectForKey:oldKey];
        cacheDirtyFlag = YES;
    }
}

- (void)setImageWithVideoPath:(NSString *)path placeholderImage:(UIImage *)placeholder
{
    NSString *fileName = [path lastPathComponent];
    __block UIImage *image = [VideoThumbImageView getImageFromCache:fileName];
    if (image != nil) {
        self.image = image;
        [self addPlayButtonImage];
        return;
    } else {
        self.image = placeholder;
    }
    dispatch_async(dispatch_get_main_queue(), ^{

        KxMovieDecoder *decoder = [KxMovieDecoder movieDecoderWithContentPath:path error:nil];// must run in main thread
        if (decoder == nil)
            return;
        [decoder closeAudioStream]; // only get video stream

        if (decoder.duration == MAXFLOAT || decoder.duration == 0) {
            decoder.position = 0;
        } else {
            decoder.position = arc4random() % (int)(decoder.duration);
        }
        
        NSArray *frames = [decoder decodeFrames:0];
        [decoder closeFile];

        if ([frames count] > 0 && [frames[0] isKindOfClass:[KxVideoFrameRGB class]]) {
            image = [[frames[0] asImage] resizeToSize:CGSizeMake(self.frame.size.width, self.frame.size.height)];
        }
        if (image == nil) {
            return;
        }

        videoThumbCacheDict[fileName] = UIImagePNGRepresentation(image);
        cacheDirtyFlag = YES;

        self.image = image;
        [self addPlayButtonImage];

    });

}

- (void)addPlayButtonImage
{
    // add play button image
    UIImageView *playImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playBtn.png"]];
    playImage.frame = CGRectMake(0, 0, 40, 40);
    playImage.alpha = 0.7;
    playImage.center = self.center;
    playImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self addSubview:playImage];
    [self setNeedsDisplay];
}

@end
