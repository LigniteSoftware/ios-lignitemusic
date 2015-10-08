//
//  LMMainViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMMainViewController.h"
#import "LMNowPlayingView.h"
#import "LMAlbumView.h"

@interface LMMainViewController ()

@property SwitcherType viewMode;
@property LMNowPlayingView *playingView;
@property LMAlbumView *albumView;

@end

@implementation LMMainViewController

- (void)handle_NowPlayingItemChanged:(id) sender {
    [self.playingView updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
}

- (void)handle_PlaybackStateChanged:(id) sender {
    NSLog(@"Playing state changed");
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    
    self.albumView = [[LMAlbumView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.albumView];
    
    
    /*
    self.playingView = [[LMNowPlayingView alloc]initWithFrame:self.view.frame];
    self.playingView.musicPlayer = self.musicPlayer;
    [self.playingView setupView];
    self.playingView.userInteractionEnabled = YES;
    [self.view addSubview:self.playingView];
    */
    
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
