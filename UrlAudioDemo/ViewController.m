//
//  ViewController.m
//  UrlAudioDemo
//
//  Created by TianMeng on 2019/1/14.
//  Copyright © 2019年 TianMeng. All rights reserved.
//  播放网络音频 使用AVPlayer

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, strong) AVPlayerItem* currentItem;
@property (nonatomic, strong) id timerObserver;//监听音乐播放进度
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;

@property (nonatomic, strong) UIProgressView* progressView;
@property (nonatomic, strong) UISlider* slider;

@property (nonatomic, strong) UILabel* startLabel;
@property (nonatomic, strong) UILabel* endLabel;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //进度条
    self.progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(80, 500, [UIScreen mainScreen].bounds.size.width-160, 50);
    self.progressView.userInteractionEnabled = YES;
    //设置进度条默认颜色
    self.progressView.trackTintColor = [UIColor yellowColor];
    self.progressView.progress = 0.0f;
    //设置进度条上进度的颜色
    self.progressView.progressTintColor = [UIColor grayColor];
    [self.view addSubview:self.progressView];
    
    //滑块
    self.slider = [[UISlider alloc]initWithFrame:CGRectMake(80,self.progressView.frame.origin.y-24, self.progressView.bounds.size.width, 50)];
    self.slider.value = 0.f;
     //设置滑块左边（小于部分）线条的颜色
    self.slider.minimumTrackTintColor = [UIColor blueColor];
    //设置滑块右边（大于部分）线条的颜色
    self.slider.maximumTrackTintColor = [UIColor clearColor];
    //设置滑块颜色（影响已划过一端的颜色）
     self.slider.thumbTintColor = [UIColor blueColor];
    [self.view addSubview:self.slider];
    //添加点击事件
    [self.slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    
    //音频播放了多少时间
    self.startLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 500-25, 65, 50)];
    self.startLabel.font = [UIFont systemFontOfSize:13];
    self.startLabel.textColor = [UIColor blackColor];
    self.startLabel.textAlignment = NSTextAlignmentRight;
    self.startLabel.text = @"00:00";
    [self.view addSubview:self.startLabel];
    
    //音频的总时间
    self.endLabel = [[UILabel alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-75, 500-24, 65, 50)];
    self.endLabel.font = [UIFont systemFontOfSize:13];
    self.endLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.endLabel];
    
    
    //注册音频播放完成的通知
    [self addNSNotificationForPlayMusicFinish];
    
   
    //激活音频会话，弹出权限
    AVAudioSession* session = [AVAudioSession sharedInstance];
    //设置类型:播放。
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    //激活音频会话。
    [session setActive:YES error:nil];
    
    
    AVPlayerItem* item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://download.lingyongqian.cn//music//MinuetInG.mp3"]];
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.currentItem = item;
    //监听音乐缓存进度
    [self addAudioObserver];
  
    
    
}


//移除监听音乐播放进度
-(void)removeTimeObserver
{
    if (self.timerObserver) {
        [self.player removeTimeObserver:self.timerObserver];
        self.timerObserver = nil;
    }
}


//  暂停/继续
- (IBAction)clickPause:(id)sender {
    self.pauseBtn.selected = !self.pauseBtn.selected;
    if (self.pauseBtn.selected) {
        //暂停
        [self.player pause];
    }else{
        [self.player play];
    }
}



// 切换下一首
- (IBAction)clickNext:(id)sender {
    self.slider.value = 0.f;
    self.progressView.progress = 0.f;
    //先移除之前的音乐缓存进度观察者
    [self removeAudioObserver];
    [self removeTimeObserver];
    AVPlayerItem* item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://download.lingyongqian.cn//music//ForElise.mp3"]];
    self.currentItem = item;
    [self.player replaceCurrentItemWithPlayerItem:item];
    self.startLabel.text = @"00:00";
    //监听音乐缓存进度
    [self addAudioObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {//音乐缓存进度
        NSArray * timeRanges = self.player.currentItem.loadedTimeRanges;
        //本次缓冲的时间范围
        CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
        //缓冲总长度
        NSTimeInterval totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        //音乐的总时间
        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
        //计算缓冲百分比例
        NSTimeInterval scale = totalLoadTime/duration;
        //更新缓冲进度条
        NSLog(@"%f",scale);
        self.progressView.progress = scale;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.player.status) {
            case AVPlayerStatusUnknown:
            {
                NSLog(@"网路音频播放器状态不明");
            }
                break;
            case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"网路音频播放器状态可播放");
                self.pauseBtn.selected = NO;
                [self.player play];
                NSLog(@"网络媒体总时长%f",CMTimeGetSeconds(self.currentItem.asset.duration));
                self.endLabel.text = [self timeFormatted:CMTimeGetSeconds(self.currentItem.asset.duration)];
            }
                break;
            case AVPlayerStatusFailed:
            {
                NSLog(@"网路音频播放器状态失败");
            }
                break;
            default:
                break;
        }
    }
}

//转换成时分秒
- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}


#pragma mark --  网络音乐开始播放需要的所有监听
- (void)addAudioObserver {
    //监听音乐缓存进度
    /*
     AVPlayerItemStatus
     AVPlayerItemStatusUnknown,//未知状态
     AVPlayerItemStatusReadyToPlay,//准备播放,这种状态才可以播放
     AVPlayerItemStatusFailed//加载失败
     **/
    
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    //监听播放进度
    //音乐的播放进度
    if (self.timerObserver != nil) {
        [self removeTimeObserver];
    }
    __weak typeof(self) weakSelf = self;
    self.timerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //当前播放的时间
        float current = CMTimeGetSeconds(time);
        //总时间
        float total = CMTimeGetSeconds(weakSelf.currentItem.duration);
        if(current) {
            float progress = current / total;
            //更新播放进度条
            NSLog(@"音乐播放的进度:%f",progress);
            weakSelf.slider.value = progress;
            weakSelf.startLabel.text = [weakSelf timeFormatted:current];
        }
    }];
}

- (void)removeAudioObserver {
   
        [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    
}

- (void)sliderAction:(UISlider*)slider {
    NSLog(@"slider在变化");
    //根据值计算时间
    float time = slider.value * CMTimeGetSeconds(self.player.currentItem.duration);
    //跳转到当前指定时间
    [self.player seekToTime:CMTimeMake(time, 1)];
}


#pragma mark - NSNotification
-(void)addNSNotificationForPlayMusicFinish
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

-(void)playFinished:(NSNotification*)notification
{
    //播放下一首
    [self clickNext:nil];
}


- (void)dealloc {
    NSLog(@"dealloc");
    [self removeAudioObserver];
    [self removeTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


@end
