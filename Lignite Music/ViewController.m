//
//  ViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property MPMusicPlayerController *musicPlayer;
@property UIImageView *albumArt, *backgroundImageArt;
@property UILabel *songTitleLabel, *songArtistLabel, *songAlbumLabel, *songDurationLabel;
@property UIButton *playSongButton, *shuffleButton, *repeatButton;
@property UISlider *songPlacementSlider;
@property NSTimer *currentTimer;

@end

@implementation ViewController

//http://stackoverflow.com/questions/17878462/mpmovieplayercontroller-getting-a-reliable-non-skipping-currentplaybacktime
- (IBAction)setTimelinePosition:(id)sender {
    UISlider *slider = sender;
    NSLog(@"setting to %f", [slider value]);
    [self.musicPlayer setCurrentPlaybackTime:[slider value]];
    self.songPlacementSlider.value = [slider value];
}

- (IBAction)setPlaying:(id)sender {
    if(self.musicPlayer.playbackState == MPMusicPlaybackStatePaused){
        [self.musicPlayer play];
        [self.playSongButton setImage:[UIImage imageNamed:@"pause_white.png"] forState:UIControlStateNormal];
    }
    else{
        [self.musicPlayer pause];
        [self.playSongButton setImage:[UIImage imageNamed:@"play_white.png"] forState:UIControlStateNormal];
    }
}

- (void)onTimer:(NSTimer *)timer {
    long currentPlaybackTime = self.musicPlayer.currentPlaybackTime;
    long totalPlaybackTime = [[self.musicPlayer nowPlayingItem] playbackDuration];
    
    long currentHours = (currentPlaybackTime / 3600);
    long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
    int currentSeconds = (currentPlaybackTime % 60);
    
    long totalHours = (totalPlaybackTime / 3600);
    long totalMinutes = ((totalPlaybackTime / 60) - totalHours*60);
    int totalSeconds = (totalPlaybackTime % 60);
     
    
    self.songPlacementSlider.value = currentPlaybackTime;
    
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
}

- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying {
    if(nowPlaying == nil){
        self.songTitleLabel.text = @"Not playing anything, sorry";
        return;
    }
    self.songTitleLabel.textColor = [UIColor whiteColor];
    
    NSArray *musicArray = [[NSArray alloc]initWithObjects:nowPlaying, nil];
    [self.musicPlayer setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:musicArray]];
    [self.musicPlayer play];
    
    self.songTitleLabel.text = [nowPlaying title];
    self.songArtistLabel.text = [nowPlaying artist];
    self.songAlbumLabel.text = [nowPlaying albumTitle];
    
    self.songPlacementSlider.maximumValue = [nowPlaying playbackDuration];
    self.songPlacementSlider.value = [self.musicPlayer currentPlaybackTime];
    self.songPlacementSlider.minimumValue = 0;
    
    NSLog(@"set to %f, %f, %f", self.songPlacementSlider.maximumValue, self.songPlacementSlider.value, self.songPlacementSlider.minimumValue);
    
    CGSize titleTextSize = [self.songTitleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songTitleLabel.font}];
    CGSize artistTextSize = [self.songArtistLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songArtistLabel.font}];
    CGSize albumTextSize = [self.songAlbumLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songAlbumLabel.font}];
    CGSize durationTextSize = [self.songDurationLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songDurationLabel.font}];
    
    NSLog(@"size %@", NSStringFromCGSize(durationTextSize));
    [UIView animateWithDuration:0.4f animations:^{
        float titleX = self.songTitleLabel.frame.origin.x;
        float titleY = self.songTitleLabel.frame.origin.y;
        int titleOverflow = 0;
        if(titleTextSize.width+titleX > self.view.frame.size.width){
            titleOverflow = (titleTextSize.width+titleX)-self.view.frame.size.width;
        }
        int titleHeight = titleTextSize.height*(titleOverflow > 0 ? 2 : 1)+20;
        CGRect newTitleRect = CGRectMake(titleX, titleY, titleTextSize.width-titleOverflow, titleHeight);
        self.songTitleLabel.frame = newTitleRect;
        
        float artistX = self.songTitleLabel.frame.origin.x;
        float artistY = titleY+newTitleRect.size.height;
        int artistOverflow = 0;
        if(artistTextSize.width+artistX > self.view.frame.size.width){
            artistOverflow = (artistTextSize.width+artistX)-self.view.frame.size.width;
        }

        CGRect newArtistRect = CGRectMake(artistX, artistY, artistTextSize.width-artistOverflow, artistTextSize.height*(artistOverflow > 0 ? 2 : 1));
        self.songArtistLabel.frame = newArtistRect;
        
        float albumX = self.songTitleLabel.frame.origin.x;
        float albumY = artistY+newArtistRect.size.height;
        int albumOverflow = 0;
        if(albumTextSize.width+albumX > self.view.frame.size.width){
            albumOverflow = (artistTextSize.width+albumX)-self.view.frame.size.width;
        }
        
        CGRect newAlbumRect = CGRectMake(albumX, albumY, albumTextSize.width, albumTextSize.height*(artistOverflow > 0 ? 2 : 1));
        self.songAlbumLabel.frame = newAlbumRect;
        
        int startingY = albumY+newAlbumRect.size.height+10;
        int playButtonSize = 35;
        
        CGRect newPlayRect = CGRectMake(albumX-5, startingY, playButtonSize, playButtonSize);
        self.playSongButton.frame = newPlayRect;
        
        CGRect newSliderRect = CGRectMake(albumX+playButtonSize, startingY, self.view.frame.size.width-albumX-playButtonSize*2, playButtonSize);
        self.songPlacementSlider.frame = newSliderRect;
        
        int durationOrigin = newSliderRect.origin.y+newSliderRect.size.height;
        CGRect newDurationRect = CGRectMake(newSliderRect.origin.x, durationOrigin, newSliderRect.size.width, self.view.frame.size.height-durationOrigin);
        self.songDurationLabel.frame = newDurationRect;
        
        int newShuffleX = durationOrigin+durationTextSize.width+10;
        CGRect newShuffleRect = CGRectMake(newShuffleX, durationOrigin+((self.view.frame.size.height-durationOrigin)/2)-playButtonSize/2, newSliderRect.size.width-durationTextSize.width, playButtonSize);
        NSLog(@"new shuffle %@, duration %@", NSStringFromCGRect(newShuffleRect), NSStringFromCGRect(newDurationRect));
        self.shuffleButton.frame = newShuffleRect;
        
        int newRepeatX = newSliderRect.origin.x+newSliderRect.size.width-playButtonSize-10;
        CGRect newRepeatRect = CGRectMake(newRepeatX, newShuffleRect.origin.y, playButtonSize, playButtonSize);
        self.repeatButton.frame = newRepeatRect;
    }];
    
    self.albumArt.image = [[nowPlaying artwork]imageWithSize:[[nowPlaying artwork] imageCropRect].size];
    CGSize size = self.view.frame.size;
    if(![nowPlaying artwork]){
        self.backgroundImageArt.image = [UIImage imageNamed:@"lignite_background.jpg"];
    }
    else{
        self.backgroundImageArt.image = [[nowPlaying artwork]imageWithSize:CGSizeMake(size.width, size.height)];
    }
    self.backgroundImageArt.contentMode = UIViewContentModeScaleAspectFill;
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [gaussianBlurFilter setDefaults];
    CIImage *inputImage = [CIImage imageWithCGImage:[self.backgroundImageArt.image CGImage]];
    [gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
    [gaussianBlurFilter setValue:@20 forKey:kCIInputRadiusKey];
    
    CIImage *outputImage = [gaussianBlurFilter outputImage];
    CIContext *context   = [CIContext contextWithOptions:nil];
    CGImageRef cgimg     = [context createCGImage:outputImage fromRect:[inputImage extent]];
    UIImage *image       = [UIImage imageWithCGImage:cgimg];
    self.backgroundImageArt.image = image;
    
    [self.playSongButton setImage:[UIImage imageNamed:@"pause_white.png"] forState:UIControlStateNormal];
}

- (void)handle_NowPlayingItemChanged:(id) sender {
    [self updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
}

- (void)handle_PlaybackStateChanged:(id) sender {
    NSLog(@"Playing state changed");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.backgroundImageArt = [[UIImageView alloc]initWithFrame:CGRectMake(-20, -20, self.view.frame.size.width+40, self.view.frame.size.height+40)];
    [self.view addSubview:self.backgroundImageArt];
    
    float albumArtY = self.view.frame.size.height/4;
    float textStartX = self.view.frame.size.width/3 + 20;
    float textHeight = 30.0f;
    
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue" size:28.0f];
    
    self.songTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(textStartX, albumArtY, self.view.frame.size.width-textStartX, textHeight)];
    self.songTitleLabel.text = @"Hello";
    self.songTitleLabel.font = titleFont;
    self.songTitleLabel.textColor = [UIColor whiteColor];
    self.songTitleLabel.contentMode = UIViewContentModeTopLeft;
    self.songTitleLabel.numberOfLines = 0;
    [self.view addSubview:self.songTitleLabel];
    
    self.songArtistLabel = [[UILabel alloc]init];
    self.songArtistLabel.text = @"Artist";
    self.songArtistLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:22.0f];
    self.songArtistLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.songArtistLabel];
    
    self.songAlbumLabel = [[UILabel alloc]init];
    self.songAlbumLabel.text = @"Album";
    self.songAlbumLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0f];
    self.songAlbumLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.songAlbumLabel];
    
    self.playSongButton = [[UIButton alloc]init];
    [self.playSongButton setImage:[UIImage imageNamed:@"play_white.png"] forState:UIControlStateNormal];
    [self.playSongButton addTarget:self action:@selector(setPlaying:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playSongButton];
    
    self.songDurationLabel = [[UILabel alloc]init];
    self.songDurationLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
    self.songDurationLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.songDurationLabel];
    
    self.shuffleButton = [[UIButton alloc]init];
    self.shuffleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.shuffleButton setImage:[UIImage imageNamed:@"shuffle_white.png"] forState:UIControlStateNormal];
    [self.view addSubview:self.shuffleButton];
    
    self.repeatButton = [[UIButton alloc]init];
    self.repeatButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.repeatButton setImage:[UIImage imageNamed:@"repeat_white.png"] forState:UIControlStateNormal];
    [self.view addSubview:self.repeatButton];
    
    self.songPlacementSlider = [[UISlider alloc]init];
    self.songPlacementSlider.tintColor = [UIColor colorWithRed:0.82 green:0.17 blue:0.16 alpha:1.0];
    [self.songPlacementSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.songPlacementSlider];
    
    self.albumArt = [[UIImageView alloc]initWithFrame:CGRectMake(20, albumArtY, albumArtY*2, albumArtY*2)];
    self.albumArt.layer.cornerRadius = self.albumArt.frame.size.width/2;
    self.albumArt.layer.masksToBounds = YES;
    [self.view addSubview:self.albumArt];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    [self onTimer:nil];
    if([self.musicPlayer nowPlayingItem]){
        [self updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
    }
    else{
        [self updateNowPlayingItem:nil];
    }
    
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
    
    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
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

@end
