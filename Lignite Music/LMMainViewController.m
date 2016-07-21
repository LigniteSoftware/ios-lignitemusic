//
//  LMMainViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <PebbleKit/PebbleKit.h>
#import "LMMainViewController.h"
#import "LMAlbumView.h"
#import "LMMiniPlayerView.h"

@interface LMMainViewController () <PBPebbleCentralDelegate>

@property SwitcherType viewMode;
@property LMAlbumView *albumView;
@property LMMiniPlayerView *miniPlayerView;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@end

@implementation LMMainViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    self.albumView = [[LMAlbumView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.albumView];
    
    self.miniPlayerView = [[LMMiniPlayerView alloc]initWithFrame:CGRectMake(0, (self.view.frame.size.height/3 * 2) - MINI_PLAYER_CONTROL_BUTTON_RADIUS, self.view.frame.size.width, self.view.frame.size.height/3 + MINI_PLAYER_CONTROL_BUTTON_RADIUS)];
    [self.view addSubview:self.miniPlayerView];
    
    
     /*
    
    self.playingView = [[LMNowPlayingView alloc]initWithFrame:self.view.frame];
    self.playingView.musicPlayer = self.musicPlayer;
    [self.playingView setupView];
    self.playingView.userInteractionEnabled = YES;
    [self.view addSubview:self.playingView];
    */
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
