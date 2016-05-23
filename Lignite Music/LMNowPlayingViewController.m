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
    [self.albumArtView updateContentWithMusicPlayer:self.musicPlayer];
    
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
        [gaussianBlurFilter setValue:@5 forKey:kCIInputRadiusKey];
        
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
    
    //NSLog(@"Playback state is %d", (int)playbackState);
    
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
    
    [UIView animateWithDuration:0.3 animations:^{
        self.songDurationSlider.maximumValue = [self.musicPlayer.nowPlayingItem playbackDuration];
        self.songDurationSlider.value = currentPlaybackTime;
        [self.albumArtView updateContentWithMusicPlayer:self.musicPlayer];
    }];
}

- (void)nowPlayingTimeChanged:(NSTimer*)timer {
    //NSLog(@"Now playing time changed... %f", self.musicPlayer.currentPlaybackTime);
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
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(nowPlayingTimeChanged:) userInfo:nil repeats:YES];
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

+ (UIFont *)findAdaptiveFontWithName:(NSString *)fontName forUILabelSize:(CGSize)labelSize withMinimumSize:(NSInteger)minSize {
    UIFont *tempFont = nil;
    NSString *testString = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSInteger tempMin = minSize;
    NSInteger tempMax = 256;
    NSInteger mid = 0;
    NSInteger difference = 0;
    
    while (tempMin <= tempMax) {
        mid = tempMin + (tempMax - tempMin) / 2;
        tempFont = [UIFont fontWithName:fontName size:mid];
        difference = labelSize.height - [testString sizeWithFont:tempFont].height;
        
        if (mid == tempMin || mid == tempMax) {
            if (difference < 0) {
                return [UIFont fontWithName:fontName size:(mid - 1)];
            }
            
            return [UIFont fontWithName:fontName size:mid];
        }
        
        if (difference < 0) {
            tempMax = mid - 1;
        } else if (difference > 0) {
            tempMin = mid + 1;
        } else {
            return [UIFont fontWithName:fontName size:mid];
        }
    }
    
    return [UIFont fontWithName:fontName size:mid];
}

- (void)viewDidLayoutSubviews {
    // Do any additional setup after loading the view.
    
    self.songTitleLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songTitleLabel.frame.size withMinimumSize:1];
//    self.songTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.songTitleLabel.frame.size.height];
//    self.songTitleLabel.backgroundColor = [UIColor redColor];
    NSLog(@"Got a songTitleLabel font size %f with frame %@", [self.songTitleLabel.font pointSize], NSStringFromCGRect(self.songTitleLabel.frame));
    
    self.songArtistLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songArtistLabel.frame.size withMinimumSize:1];
//    self.songArtistLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.songArtistLabel.frame.size.height];
//    self.songArtistLabel.backgroundColor = [UIColor blueColor];
    NSLog(@"Got a songArtistLabel font size %f with frame %@", [self.songArtistLabel.font pointSize], NSStringFromCGRect(self.songArtistLabel.frame));
    
    self.songAlbumLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songAlbumLabel.frame.size withMinimumSize:1];
//    self.songAlbumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.songAlbumLabel.frame.size.height];
//    self.songAlbumLabel.backgroundColor = [UIColor yellowColor];
    NSLog(@"Got a songAlbumLabel font size %f with frame %@", [self.songAlbumLabel.font pointSize], NSStringFromCGRect(self.songAlbumLabel.frame));
    
    NSLog(@"container view frame %@ and superview frame %@", NSStringFromCGRect([self.songTitleLabel.superview frame]), NSStringFromCGRect(self.view.frame));
    /*
     self.songTitleLabel.minimumScaleFactor = 18/[self.songTitleLabel.font pointSize];
     self.songTitleLabel.adjustsFontSizeToFitWidth = YES;
     
     self.songArtistLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
     self.songArtistLabel.minimumScaleFactor = 14/[self.songArtistLabel.font pointSize];
     self.songArtistLabel.adjustsFontSizeToFitWidth = YES;
     
     self.songAlbumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
     self.songAlbumLabel.minimumScaleFactor = 12/[self.songAlbumLabel.font pointSize];
     self.songAlbumLabel.adjustsFontSizeToFitWidth = YES;
     */
    
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
    
    if(self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying){
        [self fireRefreshTimer];
    }
    else{
        //Update the contents of the slider/timing elements if the music is paused
        [self nowPlayingTimeChanged:nil];
    }
    
    UITapGestureRecognizer *screenTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playPauseMusic)];
    [self.view addGestureRecognizer:screenTapRecognizer];
    
    UISwipeGestureRecognizer *nextRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(nextSong:)];
    [nextRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:nextRecognizer];
    
    UISwipeGestureRecognizer *previousRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(previousSong:)];
    [previousRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:previousRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload:(BOOL)animated {
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
