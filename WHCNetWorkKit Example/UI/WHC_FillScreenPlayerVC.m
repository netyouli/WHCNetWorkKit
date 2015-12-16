//
//  WHC_FillScreenPlayerVC.m
//  PhoneBookBag
//
//  Created by 吴海超 on 15/7/8.
//  Copyright (c) 2015年 吴海超. All rights reserved.
//

/*
 *  qq:712641411
 *  iOSqq群:302157745
 *  gitHub:https://github.com/netyouli
 *  csdn:http://blog.csdn.net/windwhc/article/category/3117381
 */

#import "WHC_FillScreenPlayerVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+WHC_ViewProperty.h"
#import "UIView+WHC_Loading.h"
#define kRotateAnimationDuring         (0.2)       //旋转动画
@interface WHC_FillScreenPlayerVC (){
    MPMoviePlayerController  *               _moviePlayer;      //视频播放器
    CGRect                                   _moviePlayerRect;  //初始视频区域
    BOOL                                     _visableStatusBar;      //状态栏是否可见
    BOOL                                     _isRotate;         //是否旋转
}

@end

@implementation WHC_FillScreenPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self layoutUI];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.view startLoading];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self removeMovieNotificationHandlers];
    [self showNavigationBar];
}

- (void)layoutUI{
    [self hideNavigationBar];
    self.view.backgroundColor = [UIColor whiteColor];
    _moviePlayer = [[MPMoviePlayerController alloc]init];
    _moviePlayer.controlStyle = MPMovieControlStyleDefault;
    _moviePlayer.movieSourceType = MPMovieScalingModeAspectFit;
    _moviePlayer.shouldAutoplay = YES;
    _moviePlayer.view.frame = _moviePlayerRect;
    [self.view addSubview:_moviePlayer.view];
    _moviePlayer.contentURL = _playUrl;
    [_moviePlayer prepareToPlay];
    [_moviePlayer play];
}

- (void)initData{
    _moviePlayerRect = [UIScreen mainScreen].bounds;
    [self installMovieNotificationObservers];
}

- (void)moviePlayerReadyForDisplay:(NSNotification *)notifiy{
    [self.view stopLoading];
}

- (void)showNavigationBar{
    _visableStatusBar = NO;
    self.navigationController.navigationBarHidden = NO;
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]){
        [self prefersStatusBarHidden];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)hideNavigationBar{
    _visableStatusBar = YES;
    self.navigationController.navigationBarHidden = YES;
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]){
        [self prefersStatusBarHidden];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)prefersStatusBarHidden{
    return _visableStatusBar;
}

- (void)scanButton:(UIView *)view visable:(BOOL)visable{
    NSArray  * subViewArr = view.subviews;
    if(subViewArr && subViewArr.count > 0){
        for (UIButton * btn in subViewArr) {
            if([btn isKindOfClass:[UIButton class]]){
                if([btn.titleLabel.text isEqualToString:@"Done"] ||
                   [btn.titleLabel.text isEqualToString:@"完成"]){
                    [btn addTarget:self action:@selector(clickDone:) forControlEvents:UIControlEventTouchUpInside];
                }else if(btn.x < 160 + 5 && btn.x > 160 - 5){
                    btn.hidden = NO;
                }else{
                    btn.hidden = !visable;
                }
            }else{
                [self scanButton:btn visable:visable];
            }
        }
    }
}

- (void)clickDone:(UIButton *)sender{
    _moviePlayer.view.xy = _moviePlayerRect.origin;
    _moviePlayer.controlStyle = MPMovieControlStyleDefault;
    [self scanButton:_moviePlayer.view visable:NO];
    __weak  typeof(self) sf = self;
    [UIView animateWithDuration:kRotateAnimationDuring delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _moviePlayer.view.size = CGSizeMake(CGRectGetHeight(_moviePlayerRect), CGRectGetWidth(_moviePlayerRect));
        _moviePlayer.view.center = CGPointMake(CGRectGetMidX(_moviePlayerRect), CGRectGetMidY(_moviePlayerRect));
        _moviePlayer.view.transform = CGAffineTransformMakeRotation(0);
        _moviePlayer.view.size = _moviePlayerRect.size;
    } completion:^(BOOL finished) {
        [_moviePlayer stop];
        [self showNavigationBar];
        [sf.navigationController popViewControllerAnimated:NO];
    }];
}

- (void)enterFullScreenMode{
    _moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    _moviePlayer.view.xy = CGPointZero;
    [self scanButton:_moviePlayer.view visable:NO];
    [self.view bringSubviewToFront:_moviePlayer.view];
    [UIView animateWithDuration:kRotateAnimationDuring delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _moviePlayer.view.size = CGSizeMake(self.view.height, self.view.width);
        _moviePlayer.view.center = CGPointMake(self.view.width / 2.0, self.view.height / 2.0);
        _moviePlayer.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    } completion:^(BOOL finished) {
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark Movie Notification Handlers

/*  Notification called when the movie finished playing. */
- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
    NSNumber *reason = [notification userInfo][MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    switch ([reason integerValue])
    {
            /* The end of the movie was reached. */
        case MPMovieFinishReasonPlaybackEnded:
            /*
             Add your code here to handle MPMovieFinishReasonPlaybackEnded.
             */
            break;
            
            /* An error was encountered during playback. */
        case MPMovieFinishReasonPlaybackError:
            NSLog(@"An error was encountered during playback");
            [self clickDone:nil];
            break;
            
            /* The user stopped playback. */
        case MPMovieFinishReasonUserExited:
            NSLog(@"An error was encountered during MPMovieFinishReasonUserExited");
            break;
            
        default:
            break;
    }
}

/* Handle movie load state changes. */
- (void)loadStateDidChange:(NSNotification *)notification
{
    MPMoviePlayerController *player = notification.object;
    MPMovieLoadState loadState = player.loadState;
    if (loadState & MPMovieLoadStateUnknown)
    {
//        [self clickDone:nil];
    }
}

/* Called when the movie playback state has changed. */
- (void) moviePlayBackStateDidChange:(NSNotification*)notification
{
    MPMoviePlayerController *player = notification.object;
    
    if (player.playbackState == MPMoviePlaybackStateInterrupted)
    {
        [self clickDone:nil];
    }
}

/* Notifies observers of a change in the prepared-to-play state of an object
 conforming to the MPMediaPlayback protocol. */
- (void) mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    // Add an overlay view on top of the movie view
    [self.view stopLoading];
    if(!_isRotate){
        _isRotate = YES;
        [self scanButton:_moviePlayer.view visable:NO];
        [self enterFullScreenMode];
    }
    
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:_moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:_moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification 
                                               object:_moviePlayer];
}

-(void)removeMovieNotificationHandlers
{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:_moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayer];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
