//
//  FFInternalMoviePlayerController.m
//  FFPlayer
//
//  Created by cyt on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFInternalMoviePlayerController.h"
#import "FFHelper.h"
#import "ALMoviePlayerControls.h"


static const CGFloat movieBackgroundPadding = 20.f; //if we don't pad the movie's background view, the edges will appear jagged when rotating
static const NSTimeInterval fullscreenAnimationDuration = 0.3;

@interface FFInternalMoviePlayerController () <ALMoviePlayerInterface>
{
    MPMoviePlayerController * _player;
    ALMoviePlayerControls * _controls;
}

@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, strong) UIView *movieBackgroundView;
@property (nonatomic, readwrite) BOOL movieFullscreen; //used to manipulate default fullscreen property

@end

@implementation FFInternalMoviePlayerController

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super init]) ) {
        
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];

        _player = nil;
        _controls = nil;
        _movieBackgroundView = nil;
    }
    return self;
}

- (void) viewDidLoad
{
    _player = [[MPMoviePlayerController alloc] init];
    [_player setControlStyle:MPMovieControlStyleNone];
    _movieFullscreen = YES;
    [_player setFullscreen:YES animated:NO];
    [self.view addSubview:_player.view];
    
    if (!_movieBackgroundView) {
        _movieBackgroundView = [[UIView alloc] init];
        _movieBackgroundView.alpha = 0.f;
        [_movieBackgroundView setBackgroundColor:[UIColor blackColor]];
    }

    if ( _controls == nil ) {
        _controls = [[ALMoviePlayerControls alloc] initWithMoviePlayer:self style:ALMoviePlayerControlsStyleFullscreen];
        _controls.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view addSubview:_controls];
    }
}

- (void)dealloc {
    _delegate = nil;
    [_durationTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - Getters

- (BOOL)isFullscreen {
    return _movieFullscreen;
}

- (CGFloat)statusBarHeightInOrientation:(UIInterfaceOrientation)orientation {
    if ([FFHelper iOSVersion] >= 7.0)
        return 0.f;
    else if ([UIApplication sharedApplication].statusBarHidden)
        return 0.f;
    return 20.f;
}

# pragma mark - Setters

- (void)setFrame:(CGRect)frame {
    [_player.view setFrame:frame];
    [_controls setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (void)setFullscreen:(BOOL)fullscreen {
    [_player setFullscreen:fullscreen animated:NO];
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated {
    _movieFullscreen = fullscreen;
    if (fullscreen) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillEnterFullscreenNotification object:nil];
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        if (!keyWindow) {
            keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        }
        if (CGRectEqualToRect(self.movieBackgroundView.frame, CGRectZero)) {
            [self.movieBackgroundView setFrame:keyWindow.bounds];
        }
        [keyWindow addSubview:self.movieBackgroundView];
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.movieBackgroundView.alpha = 1.f;
        } completion:^(BOOL finished) {
            self.view.alpha = 0.f;
            [self.movieBackgroundView addSubview:self.view];
            UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            [self rotateMoviePlayerForOrientation:currentOrientation animated:NO completion:^{
                [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.view.alpha = 1.f;
                } completion:^(BOOL finished) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidEnterFullscreenNotification object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
                }];
            }];
        }];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillExitFullscreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.view.alpha = 1.f;
            [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.movieBackgroundView.alpha = 0.f;
            } completion:^(BOOL finished) {
                [self.movieBackgroundView removeFromSuperview];
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidExitFullscreenNotification object:nil];
            }];
        }];
    }
}

#pragma mark - Notifications

- (void)statusBarOrientationWillChange:(NSNotification *)note {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[[note userInfo] objectForKey:UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    [self rotateMoviePlayerForOrientation:orientation animated:YES completion:nil];
}

- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^)(void))completion {
    CGFloat angle;
    CGSize windowSize = [FFHelper sizeInOrientation:orientation];
    CGRect backgroundFrame;
    CGRect movieFrame;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, -movieBackgroundPadding, windowSize.width + movieBackgroundPadding*2, windowSize.height + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding*2, backgroundFrame.size.height - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI_2;
            backgroundFrame = CGRectMake([self statusBarHeightInOrientation:orientation] - movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding*2, windowSize.width + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding*2, backgroundFrame.size.width - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding*2, windowSize.width + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding*2, backgroundFrame.size.width - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationPortrait:
        default:
            angle = 0.f;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, [self statusBarHeightInOrientation:orientation] - movieBackgroundPadding, windowSize.width + movieBackgroundPadding*2, windowSize.height + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding*2, backgroundFrame.size.height - movieBackgroundPadding*2);
            break;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
            self.movieBackgroundView.frame = backgroundFrame;
            [self setFrame:movieFrame];
        } completion:^(BOOL finished) {
            if (completion)
                completion();
        }];
    } else {
        self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
        self.movieBackgroundView.frame = backgroundFrame;
        [self setFrame:movieFrame];
        if (completion)
            completion();
    }
}

/////////////////////////////////////////////////////////////////////

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
}

- (void)movieFinished:(NSNotification *)note {
    [_player pause];
    [self.durationTimer invalidate];
    [self monitorMoviePlayback]; //reset values
    [_controls hideControls:nil];
    [self.delegate onFinish:self curPos:[_player currentPlaybackTime]];
}

- (void)movieLoadStateDidChange:(NSNotification *)note {
    switch (_player.loadState) {
        case MPMovieLoadStatePlayable:
        case MPMovieLoadStatePlaythroughOK:
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(movieTimedOut) object:nil];
            [_controls showControls:nil];
            break;
        case MPMovieLoadStateStalled:
        case MPMovieLoadStateUnknown:
            break;
        default:
            break;
    }
}

- (void)moviePlaybackStateDidChange:(NSNotification *)note {
    switch (_player.playbackState) {
        case MPMoviePlaybackStatePlaying:
            [self startDurationTimer];
            
            //local file
            if ([_player.contentURL.scheme isEqualToString:@"file"]) {
                [_controls setDurationSliderMaxMinValues:_player.duration];
                [_controls showControls:nil];
            }
        case MPMoviePlaybackStateSeekingBackward:
        case MPMoviePlaybackStateSeekingForward:
            break;
        case MPMoviePlaybackStateInterrupted:
            break;
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
            [self stopDurationTimer];
            break;
        default:
            break;
    }
    [_controls updatePlayState:[self isPlaying] hasNext:self.delegate != nil?[self.delegate hasNext]:FALSE hasPrev:self.delegate != nil?[self.delegate hasPre]:FALSE];
}

- (void)movieDurationAvailable:(NSNotification *)note {
    CGFloat totalTime = floor(_player.duration);
    [_controls setDurationSliderMaxMinValues:totalTime];
}

# pragma mark - Internal Methods

- (void)startDurationTimer {
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorMoviePlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer {
    [self.durationTimer invalidate];
}

- (void)monitorMoviePlayback {
    double currentTime = floor(_player.currentPlaybackTime);
    double totalTime = floor(_player.duration);
    [_controls updateMoviePlayback:currentTime total:totalTime];
}

/////////////////////////////////////////////////////////////////////

+ (id) movieViewControllerWithDelegate:(id <FFMovieCallback>)delegate
{
    return [[FFInternalMoviePlayerController alloc] initWithDelegate:delegate];
}

-(id)initWithDelegate:(id <FFMovieCallback>)delegate
{
    self = [self init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

-(BOOL)playing
{
    return [_player playbackState] == MPMoviePlaybackStatePlaying;
}

- (void) pause
{
    [_player pause];
}

-(void) playMovie:(NSString *)path pos:(CGFloat)pos parameters: (NSDictionary *) parameters
{
    [self setFullscreen:YES];
    [_player setContentURL:[NSURL URLWithString:path]];
    [_player setCurrentPlaybackTime:pos];
    [_player play];
}

# pragma mark - Internal Methods

- (void)play {
    [_player play];
    
    //remote file
    if (![_player.contentURL.scheme isEqualToString:@"file"] && _player.loadState == MPMovieLoadStateUnknown) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(movieTimedOut) object:nil];
        [self performSelector:@selector(movieTimedOut) withObject:nil afterDelay:20.f];
    }
}

-(void)movieTimedOut {
    if (!(_player.loadState & MPMovieLoadStatePlayable) || !(_player.loadState & MPMovieLoadStatePlaythroughOK)) {
        NSLog(@"Timeout");
    }
}

//////////////////

-(BOOL)isPlaying
{
    return self.playing;
}

-(CGFloat) getDuration
{
    return [_player duration];
}

-(CGFloat) getCurrentPlaybackRate
{
    return [_player currentPlaybackRate];
}

-(void) setCurrentPlaybackRate:(CGFloat) v
{
    [_player setCurrentPlaybackRate:v];
}

-(void) setScalingMode:(int)mode
{
    [_player setScalingMode:mode];
}

-(void) onPause
{
    [self pause];
}

-(void) setCurrentPlaybackTime:(CGFloat)pos
{
    [_player setCurrentPlaybackTime:floor(pos)];
    [_player play];
}

-(void) onPlay
{
    [self play];
}

-(void) onForward:(CGFloat)f
{
    CGFloat n = [_player currentPlaybackTime] + f;
    if ( n > [_player duration])
        n = [_player duration];
    [_player setCurrentPlaybackTime:n];
}

-(void) onRewind:(CGFloat)f
{
    CGFloat n = [_player currentPlaybackTime];
    if ( n > f)
        n -= f;
    [_player setCurrentPlaybackTime:n];
}

-(void) onNext
{
    if (self.playing)
        [self pause];
    if ( self.delegate )
        [self.delegate onNext:self curPos:[_player currentPlaybackTime]];
    NSLog(@"next movie");
}

-(void) onPrev
{
    if (self.playing)
        [self pause];
    if ( self.delegate )
        [self.delegate onPre:self curPos:[_player currentPlaybackTime]];
    NSLog(@"pre movie");
}

-(void) onDone
{
    if (self.presentingViewController || !self.navigationController)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

@end
