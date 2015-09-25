//
//  LMMainViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMMainViewController.h"
#import "LMNowPlayingView.h"

@interface LMMainViewController ()

@property UIScrollView *rootScrollView;
@property SwitcherType viewMode;
@property LMNowPlayingView *playingView;

@end

@implementation LMMainViewController

- (void)test {
    NSLog(@"test");
}

- (void)handle_NowPlayingItemChanged:(id) sender {
    [self.playingView updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
}

- (void)handle_PlaybackStateChanged:(id) sender {
    NSLog(@"Playing state changed");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    CGRect currentFrame = self.view.frame;
    CGRect rootFrame = currentFrame; //CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, currentFrame.size.height);
    self.rootScrollView = [[UIScrollView alloc]initWithFrame:rootFrame];
    [self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*2)];
    [self.view addSubview:self.rootScrollView];
    
    UIButton *testButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
    [testButton setTitle:@"Memememememememememe" forState:UIControlStateNormal];
    [testButton.titleLabel setTextColor:[UIColor whiteColor]];
    testButton.backgroundColor = [UIColor redColor];
    [testButton addTarget:self action:@selector(test) forControlEvents:UIControlEventAllEvents];
    [self.rootScrollView addSubview:testButton];
    
    self.playingView = [[LMNowPlayingView alloc]initWithFrame:self.view.frame];
    self.playingView.musicPlayer = self.musicPlayer;
    [self.playingView setupView];
    self.playingView.userInteractionEnabled = YES;
    [self.view addSubview:self.playingView];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter
     addObserver: self
     selector:    @selector(handle_NowPlayingItemChanged:)
     name:        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:      self.musicPlayer];
    
    [notificationCenter
     addObserver: self
     selector:    @selector(handle_PlaybackStateChanged:)
     name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
     object:      self.musicPlayer];
    
    [self.musicPlayer beginGeneratingPlaybackNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
