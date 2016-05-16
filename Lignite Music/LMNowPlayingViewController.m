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
        albumImage = [UIImage imageNamed:@"lignite_background.jpg"];
    }
    else{
        albumImage = [[self.musicPlayer.nowPlayingItem artwork]imageWithSize:CGSizeMake(size.width, size.height)];
    }
    
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

- (void)nowPlayingTimeChanged:(NSTimer*)timer {
    long currentPlaybackTime = self.musicPlayer.currentPlaybackTime;
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
    
    if(timer != nil){
        [UIView animateWithDuration:0.3 animations:^{
            self.songDurationSlider.value = currentPlaybackTime;
        }];
    }
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.albumArtView setupWithAlbumImage:[UIImage imageNamed:@"no_album.png"]];
    
    [self.shuffleButton setupWithTitle:@"Shuffle" withImage:[UIImage imageNamed:@"shuffle_black.png"]];
    [self.repeatButton setupWithTitle:@"Repeat" withImage:[UIImage imageNamed:@"repeat_black.png"]];
    [self.dynamicPlaylistButton setupWithTitle:@"Playlist" withImage:[UIImage imageNamed:@"dynamic_playlist.png"]];
    
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
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(nowPlayingTimeChanged:) userInfo:nil repeats:YES];
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
