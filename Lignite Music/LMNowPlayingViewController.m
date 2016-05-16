//
//  TestViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMNowPlayingViewController.h"

@interface LMNowPlayingViewController ()

@property NSTimer *refreshTimer;
@property UIView *shadingView;
@property BOOL finishedUserAdjustment;

@end

@implementation LMNowPlayingViewController


- (void)nowPlayingItemChanged:(id) sender {
    //[self.playingView updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
    [self.songTitleLabel setText:self.musicPlayer.nowPlayingItem.title];
    [self.songArtistLabel setText:self.musicPlayer.nowPlayingItem.artist];
    [self.songAlbumLabel setText:self.musicPlayer.nowPlayingItem.albumTitle];
    [self.songNumberLabel setText:[NSString stringWithFormat:@"Song %lu of %lu", self.musicPlayer.nowPlayingItem.albumTrackNumber, self.musicPlayer.nowPlayingItem.albumTrackCount]];
    
    self.songDurationSlider.maximumValue = [self.musicPlayer.nowPlayingItem playbackDuration];
    [self.albumArtView updateContentWithMediaItem:self.musicPlayer.nowPlayingItem];
    
    UIImage *albumImage;
    CGSize size = self.backgroundImageView.frame.size;
    if(![self.musicPlayer.nowPlayingItem artwork]){
        albumImage = [UIImage imageNamed:@"lignite_background_portrait.png"];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundImageView.image = albumImage;
    }
    else{
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        albumImage = [[self.musicPlayer.nowPlayingItem artwork]imageWithSize:CGSizeMake(size.width, size.height)];
        
        CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [gaussianBlurFilter setDefaults];
        CIImage *inputImage = [CIImage imageWithCGImage:[albumImage CGImage]];
        [gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
        [gaussianBlurFilter setValue:@10 forKey:kCIInputRadiusKey];
        
        CIImage *outputImage = [gaussianBlurFilter outputImage];
        CIContext *context   = [CIContext contextWithOptions:nil];
        CGImageRef cgimg     = [context createCGImage:outputImage fromRect:[inputImage extent]];
        UIImage *image       = [UIImage imageWithCGImage:cgimg];
        
        self.backgroundImageView.image = image;

    }
    
    //[self.view insertSubview:self.backgroundImageView atIndex:0];
    //self.backgroundImageView.hidden = YES;
    [self.view sendSubviewToBack:self.backgroundImageView];
}

- (void)nowPlayingStateChanged:(id) sender {
    MPMusicPlaybackState playbackState = [self.musicPlayer playbackState];
    
    NSLog(@"Playback state is %d", (int)playbackState);
    
    if (playbackState == MPMusicPlaybackStatePaused || playbackState == MPMusicPlaybackStatePlaying) {
        //[self.playingView.controlView setPlaying:nil];
    }
    else if (playbackState == MPMusicPlaybackStateStopped) {
        //[self.musicPlayer stop];
    }
}

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
    long totalPlaybackTime = [[self.musicPlayer nowPlayingItem] playbackDuration];
    
    long currentHours = (currentPlaybackTime / 3600);
    long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
    int currentSeconds = (currentPlaybackTime % 60);
    
    long totalHours = (totalPlaybackTime / 3600);
    long totalMinutes = ((totalPlaybackTime / 60) - totalHours*60);
    int totalSeconds = (totalPlaybackTime % 60);
    
    [UIView animateWithDuration:0.3 animations:^{
        if(totalHours > 0){
            self.songDurationLabel.text = [NSString stringWithFormat:@"%02i:%02d:%02d of %02i:%02d:%02d",
                                           (int)currentHours, (int)currentMinutes, currentSeconds,
                                           (int)totalHours, (int)totalMinutes, totalSeconds];
        }
        else{
            self.songDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d of %02d:%02d",
                                           (int)currentMinutes, currentSeconds,
                                           (int)totalMinutes, totalSeconds];
        }
    }];
    
    if([self.refreshTimer isValid]){
        [UIView animateWithDuration:0.3 animations:^{
            NSLog(@"Setting song duration slider value to %ld", currentPlaybackTime);
            self.songDurationSlider.value = currentPlaybackTime;
        }];
    }
}

- (void)nowPlayingTimeChanged:(NSTimer*)timer {
    NSLog(@"Now playing time changed... %f", self.musicPlayer.currentPlaybackTime);
    if((self.musicPlayer.currentPlaybackTime != self.songDurationSlider.value) && self.finishedUserAdjustment){
        self.finishedUserAdjustment = NO;
        self.musicPlayer.currentPlaybackTime = self.songDurationSlider.value;
    }
    [self updateSongDurationLabelWithPlaybackTime:self.musicPlayer.currentPlaybackTime];
}

- (void)playPauseMusic {
    if(self.musicPlayer.playbackState == MPMusicPlaybackStatePaused){
        [self.musicPlayer play];
        if(![self.refreshTimer isValid]){
            [self fireRefreshTimer];
        }
    }
    else{
        [self.musicPlayer pause];
        if(self.refreshTimer){
            [self.refreshTimer invalidate];
        }
    }
}

- (IBAction)nextSong:(id)sender {
    [self.musicPlayer skipToNextItem];
}

- (IBAction)previousSong:(id)sender {
    [self.musicPlayer skipToPreviousItem];
}

- (IBAction)setTimelinePosition:(id)sender {
    NSLog(@"Setting timeline position");
    UISlider *slider = sender;
    if(self.refreshTimer){
        [self.refreshTimer invalidate];
    }
    //self.musicPlayer.currentPlaybackTime = slider.value;
    [self updateSongDurationLabelWithPlaybackTime:slider.value];
    
    self.finishedUserAdjustment = YES;
    
    if(self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying){
        [self fireRefreshTimer];
    }
}

- (void)fireRefreshTimer {
    NSLog(@"Firing refresh timer");
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(nowPlayingTimeChanged:) userInfo:nil repeats:YES];
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.songDurationSlider.tintColor = [UIColor redColor];
    //[self.songDurationSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self.songDurationSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self.songDurationSlider addTarget:self action:@selector(fireRefreshTimer) forControlEvents:UIControlEventTouchDragExit];
    
    [self.albumArtView setupWithAlbumImage:[UIImage imageNamed:@"no_album.png"]];
    
    [self.shuffleButton setupWithTitle:@"Shuffle" withImage:[UIImage imageNamed:@"shuffle_black.png"]];
    [self.repeatButton setupWithTitle:@"Repeat" withImage:[UIImage imageNamed:@"repeat_black.png"]];
    [self.dynamicPlaylistButton setupWithTitle:@"Playlist" withImage:[UIImage imageNamed:@"dynamic_playlist.png"]];
    
    self.shadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.backgroundImageView.frame.size.width, self.backgroundImageView.frame.size.height)];
    self.shadingView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
    self.shadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundImageView addSubview:self.shadingView];
    
    [self.backgroundImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingView
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.backgroundImageView
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:1.0
                                                                          constant:0]];
    
    [self.backgroundImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.backgroundImageView
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0
                                                                          constant:0]];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter
     addObserver: self
     selector:    @selector(nowPlayingItemChanged:)
     name:        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:      self.musicPlayer];
    
    [notificationCenter
     addObserver: self
     selector:    @selector(nowPlayingStateChanged:)
     name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
     object:      self.musicPlayer];
        
    [self.musicPlayer beginGeneratingPlaybackNotifications];
    
    [self fireRefreshTimer];
    
    UITapGestureRecognizer *screenTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playPauseMusic)];
    [self.view addGestureRecognizer:screenTapRecognizer];
    
    UISwipeGestureRecognizer *nextRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(nextSong:)];
    [nextRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:nextRecognizer];
    
    UISwipeGestureRecognizer *previousRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(previousSong:)];
    [previousRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:previousRecognizer];
}

- (void)viewDidUnload:(BOOL)animated {
    NSLog(@"Unloading view");
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name:           MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:         self.musicPlayer];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name:           MPMusicPlayerControllerPlaybackStateDidChangeNotification
     object:         self.musicPlayer];
    
    [self.musicPlayer endGeneratingPlaybackNotifications];
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
