//
//  CourseContentMainController.m
//
//
//  Created by tech on 16/1/27.
//  Copyright © 2016年 tech. All rights reserved.
//

#import "CourseContentMainController.h"
#import "DWMoviePlayerController.h"

//tools
#import "SCTools.h"
#import "Masonry.h"

// 获取屏幕的宽高
#define SCREEN_WIDTH    MIN([UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)

#define SCREEN_HEIGHT   MAX([UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)

// 导航条+状态栏 高度
#define NAVBAR_HEIGHT  64

#define VIDEO_HEIGHT (SCREEN_HEIGHT - NAVBAR_HEIGHT)/ 3

#define VIDEO_CONSTRAINT SCREEN_HEIGHT - NAVBAR_HEIGHT - VIDEO_HEIGHT

@interface CourseContentMainController ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSDictionary *playUrls;//视频播放信息
@property (strong, nonatomic) IBOutlet UIView *overlayView;//透明层
@property (weak, nonatomic) IBOutlet UIView *headerView;//透明层上的header
@property (weak, nonatomic) IBOutlet UIView *footerView;//透明层上的footer
@property (weak, nonatomic) IBOutlet UIButton *rotateBtn;//切换
@property (assign, nonatomic)BOOL hiddenOverlayViews;//是否隐藏透明层上views
@property (assign, nonatomic)NSInteger hiddenDelaySeconds;//隐藏时间
@property (strong, nonatomic)UITapGestureRecognizer *tapGesture;//手势
@property (weak, nonatomic) IBOutlet UIButton *playbackButton;//播放/暂停按钮
@property (weak, nonatomic) IBOutlet UISlider *durationSlider;//时间滑动条
@property (weak, nonatomic) IBOutlet UILabel *playbackTimeLabel;//当前时间/总时间
@property (copy, nonatomic) NSString *duration;//播放总时间
@property (copy, nonatomic) NSString *currentTime; //当前时间/播放进度
@property (weak, nonatomic) IBOutlet UILabel *videoStatusLabel;//播放状态

@end

@implementation CourseContentMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createNav];
    // 加载播放器
    [self loadPlayer];
    // 播放视频
    [self loadPlayUrls];
    // 加载播放器上的透明层
    [self loadOverlayViewFromXIB];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self addObserverForMPMoviePlayController];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [_player cancelRequestPlayInfo];
    _player.contentURL = nil;
    [_player stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  加载导航
 */
- (void)createNav{
    self.navigationItem.title = @"视频播放";
}

#pragma mark - 视频播放器
/**
 *   加载播放器
 */
- (void)loadPlayer
{
    self.player.controlStyle = MPMovieControlStyleNone;
    [self.view addSubview:self.player.view];
    [self playerViewSmallScreenConstraint];
}

/**
 *   播放视频
 */
- (void)loadPlayUrls
{
    //请求播放信息HTTP通信超时时间
    _player.timeoutSeconds = 10;
    
    __weak CourseContentMainController *blockSelf = self;
    self.player.failBlock = ^(NSError *error) {
        NSLog(@"error: %@", [error localizedDescription]);
        blockSelf.videoStatusLabel.hidden = NO;
        blockSelf.videoStatusLabel.text = @"加载失败";
    };
    
    self.player.getPlayUrlsBlock = ^(NSDictionary *playUrls) {
        // [必须]判断 status 的状态，不为"0"说明该视频不可播放，可能正处于转码、审核等状态。
        NSNumber *status = [playUrls objectForKey:@"status"];
        
        if (status == nil || [status integerValue] != 0) {
            NSString *message = [NSString stringWithFormat:@"%@:%@",
                                 [playUrls objectForKey:@"status"],
                                 [playUrls objectForKey:@"statusinfo"]];
            
            NSLog(@"%@",message);
            return;
        }
        blockSelf.playUrls = playUrls;
        
        [blockSelf.player prepareToPlay];
        
        [blockSelf.player play];
    };
    
    [_player startRequestPlayInfo];

}

#pragma mark - 覆盖播放器视图
/**
 *  加载透明层
 */
- (void)loadOverlayViewFromXIB{
    [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
    _overlayView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_overlayView];
    [self overlayViewSmallScreenConstraint];
    [self loadFooterView];
    //添加手势
    [self addTapGesture];
    //首次加载 隐藏时间设为10秒
    _hiddenDelaySeconds = 10;
    //投屏 AirPlay
    [self addAirPlay];
}

/**
 *  加载透明层上的footer
 */
- (void)loadFooterView{
    [_playbackButton setImage:[UIImage imageNamed:@"player-playbutton.png"] forState:UIControlStateNormal];
    _duration = @"00:00:00";
    [_durationSlider setThumbImage:[UIImage imageNamed:@"player-slider-handle.png"] forState:UIControlStateNormal];
    [_rotateBtn setImage:[UIImage imageNamed:@"player_small.png"] forState:UIControlStateNormal];
}

/**
 *  添加手势
 */
- (void)addTapGesture{
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    _tapGesture.delegate = self;
    [_overlayView addGestureRecognizer:_tapGesture];
}

/**
 *  AirPlay
 */
- (void)addAirPlay{
    MPVolumeView *volume = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 100, 44, 44)];
    volume.showsVolumeSlider = NO;
    [volume sizeToFit];
    [_overlayView addSubview:volume];
}

/**
 *  透明层上的view是否隐藏
 */
- (void)overlayViewsHidden:(BOOL)hidden{
    _headerView.hidden = hidden;
    _footerView.hidden = hidden;
    _hiddenOverlayViews = hidden;
}

#pragma mark - footer views
/**
 *  播放按钮点击
 */
- (IBAction)playbackButtonAction:(id)sender {
    _hiddenDelaySeconds = 5;
    if (!_playUrls) {
        [self loadPlayUrls];
        return;
    }
    UIImage *image = nil;
    if (_player.playbackState == MPMoviePlaybackStatePlaying) {
        // 暂停播放
        image = [UIImage imageNamed:@"player-playbutton.png"];
        [_player pause];
    }else{
        // 继续播放
        image = [UIImage imageNamed:@"player-pausebutton.png"];
        [_player play];
    }
    
    [_playbackButton setImage:image forState:UIControlStateNormal];
}

/**
 *  滑动条滑动
 */
- (IBAction)durationSliderMoving:(id)sender {
    UISlider *slider = (UISlider *)sender;
    if (_player.playbackState != MPMoviePlaybackStatePaused) {
        [_player pause];
    }
    _player.currentPlaybackTime = slider.value;
}

- (IBAction)durationSliderDone:(id)sender {
    if (_player.playbackState != MPMoviePlaybackStatePlaying) {
        [_player play];
    }
}

#pragma mark - 切换半屏和全屏
/**
 *  切换半屏和全屏
 */
- (IBAction)rotatoButtonTouchUpInside:(id)sender {
    
    if([SCTools isOrientationLandscape]) {
        [SCTools forceOrientation: UIInterfaceOrientationPortrait];
    }else {
        [SCTools forceOrientation: UIInterfaceOrientationLandscapeRight];
    }
}

//iOS8旋转动作的具体执行
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator: coordinator];
    // 监察者将执行： 1.旋转前的动作  2.旋转后的动作（completion）
    [coordinator animateAlongsideTransition: ^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         if ([SCTools isOrientationLandscape]) {
             [self p_prepareFullScreen];
         }
         else {
             [self p_prepareSmallScreen];
         }
     } completion: ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         
     }];
    
}

/**
 *  切换成全屏的准备工作
 */
- (void)p_prepareFullScreen {
    [self changeScreenViewsHidden:YES];
    [self playerViewFullScreenConstraint];
    [self overlayViewFullScreenConstraint];
    [_rotateBtn setImage:[UIImage imageNamed:@"player_big.png"] forState:UIControlStateNormal];
    
}

/**
 *  切换成半屏的准备工作
 */
- (void)p_prepareSmallScreen {
    [self changeScreenViewsHidden:NO];
    [self playerViewSmallScreenConstraint];
    [self overlayViewSmallScreenConstraint];
    [_rotateBtn setImage:[UIImage imageNamed:@"player_small.png"] forState:UIControlStateNormal];
    
}

/**
 *  切换屏幕时是否隐藏的视图
 */
- (void)changeScreenViewsHidden:(BOOL)hidden{
    self.navigationController.navigationBar.hidden = hidden;
}

/**
 *  播放器半屏约束
 */
- (void)playerViewSmallScreenConstraint{
    [_player.view mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(UIEdgeInsetsMake(NAVBAR_HEIGHT, 0, VIDEO_CONSTRAINT, 0));
    }];
}

/**
 *  透明层半屏约束
 */
- (void)overlayViewSmallScreenConstraint{
    [_overlayView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(UIEdgeInsetsMake(NAVBAR_HEIGHT, 0, VIDEO_CONSTRAINT, 0));
    }];
}

/**
 *  播放器全屏约束
 */
- (void)playerViewFullScreenConstraint{
    [_player.view mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
}

/**
 *  透明层全屏约束
 */
- (void)overlayViewFullScreenConstraint{
    [_overlayView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
}


- (void)timerHandler{
    
    //设置时间进度条
    _currentTime = [SCTools formatSecondsToString:_player.currentPlaybackTime];
    _playbackTimeLabel.text = [NSString stringWithFormat:@"%@/%@",_currentTime,_duration];
    _durationSlider.value = _player.currentPlaybackTime;
    
    if (_hiddenOverlayViews) {
        return;
    }
    _hiddenDelaySeconds --;
    if (_hiddenDelaySeconds <= 0) {
        [self overlayViewsHidden:YES];
    }
}

#pragma mark - 手势识别
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer{
    
    if (_hiddenOverlayViews) {
        [self overlayViewsHidden:NO];
        _hiddenDelaySeconds = 5;
    }else{
        [self overlayViewsHidden:YES];
        _hiddenDelaySeconds = 0;
    }
}

//点击事件冲突解决
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if (gestureRecognizer == _tapGesture) {
        if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UISlider class]] || [touch.view isKindOfClass:[UIImageView class]] || [touch.view isKindOfClass:[UITableView class]] || [touch.view isKindOfClass:[UITableViewCell class]] || [touch.view.superview isKindOfClass:[UITableView class]] || [touch.view.superview isKindOfClass:[UITableViewCell class]]) {
            return NO;
        }
    }
    return YES;
}

# pragma mark - MPMoviePlayController Notifications
- (void)addObserverForMPMoviePlayController
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(moviePlayerDurationAvailable) name:MPMovieDurationAvailableNotification object:self.player];
    
    [notificationCenter addObserver:self selector:@selector(moviePlayerLoadStateDidChange) name:MPMoviePlayerLoadStateDidChangeNotification object:self.player];
    
    [notificationCenter addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.player];
    
    [notificationCenter addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.player];
}

/**
 *  确定了播放时长后
 */
- (void)moviePlayerDurationAvailable
{
    _duration = [SCTools formatSecondsToString:_player.duration];
    _currentTime = [SCTools formatSecondsToString:0];
    _playbackTimeLabel.text = [NSString stringWithFormat:@"%@/%@",_currentTime,_duration];
    _durationSlider.maximumValue = _player.duration;
    
}

- (void)moviePlayerLoadStateDidChange
{
    switch (self.player.loadState) {
        case MPMovieLoadStatePlayable:
            // 可播放
            _videoStatusLabel.hidden = YES;
            break;
        case MPMovieLoadStatePlaythroughOK:
            // 状态为缓冲几乎完成，可以连续播放
            _videoStatusLabel.hidden = YES;
            break;
        case MPMovieLoadStateStalled:
            // 缓冲中
            _videoStatusLabel.hidden = NO;
            _videoStatusLabel.text = @"正在加载...";
            break;
        default:
            break;
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    NSNumber *n = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    switch ([n intValue]) {
        case MPMovieFinishReasonPlaybackEnded:
            break;
        case MPMovieFinishReasonPlaybackError:
            _videoStatusLabel.hidden = NO;
            _videoStatusLabel.text = @"加载失败";
            break;
        case MPMovieFinishReasonUserExited:
            break;
        default:
            break;
    }
}

- (void)moviePlayerPlaybackStateDidChange
{
    
    switch ([self.player playbackState]) {
        case MPMoviePlaybackStateStopped:
            [self.playbackButton setImage:[UIImage imageNamed:@"player-playbutton.png"] forState:UIControlStateNormal];
            break;
        case MPMoviePlaybackStatePlaying:
            [self.playbackButton setImage:[UIImage imageNamed:@"player-pausebutton.png"] forState:UIControlStateNormal];
            _videoStatusLabel.hidden = YES;
            break;
        case MPMoviePlaybackStatePaused:
            [self.playbackButton setImage:[UIImage imageNamed:@"player-playbutton.png"] forState:UIControlStateNormal];
            _videoStatusLabel.hidden = NO;
            _videoStatusLabel.text = @"暂停";
            break;
        case MPMoviePlaybackStateInterrupted:
            [self.playbackButton setImage:[UIImage imageNamed:@"player-playbutton.png"] forState:UIControlStateNormal];
            _videoStatusLabel.hidden = NO;
            _videoStatusLabel.text = @"加载中。。。";
            break;
        case MPMoviePlaybackStateSeekingForward:
            _videoStatusLabel.hidden = YES;
            break;
        case MPMoviePlaybackStateSeekingBackward:
            _videoStatusLabel.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
