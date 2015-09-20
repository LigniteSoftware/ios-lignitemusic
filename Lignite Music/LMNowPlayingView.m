//
//  ViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMNowPlayingView.h"
#import "XYPieChart.h"
#import "PieChartView.h"

@interface LMNowPlayingView () <XYPieChartDataSource, XYPieChartDelegate, PieChartViewDataSource, PieChartViewDelegate>

@property UIView *view, *backgroundView;
@property MPMusicPlayerController *musicPlayer;
@property UIImageView *albumArt, *backgroundImageArt;
@property UILabel *songTitleLabel, *songArtistLabel, *songAlbumLabel, *songDurationLabel;
@property UIButton *playSongButton, *shuffleButton, *repeatButton;
@property UISlider *songPlacementSlider;
@property NSTimer *currentTimer;

@property XYPieChart *animatedMusicProgress;
@property PieChartView *batteryEfficientMusicProgress;
@property BOOL dragged;

@end

@implementation LMNowPlayingView

//http://stackoverflow.com/questions/17878462/mpmovieplayercontroller-getting-a-reliable-non-skipping-currentplaybacktime
#define BATTERY_SAVER YES

- (IBAction)setTimelinePosition:(id)sender {
    UISlider *slider = sender;
    if(self.currentTimer){
        [self.currentTimer invalidate];
    }
    self.musicPlayer.currentPlaybackTime = [slider value];
    [self onTimer:nil];
    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
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

- (IBAction)setShuffle:(id)sender {

}

- (IBAction)setRepeat:(id)sender {
    
}

- (IBAction)nextSong:(id)sender {
    [self.musicPlayer setNowPlayingItem:[[[MPMediaQuery songsQuery] items] objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]+1]];
}

- (IBAction)previousSong:(id)sender {
    [self.musicPlayer setNowPlayingItem:[[[MPMediaQuery songsQuery] items] objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]-1]];
};

- (void)onTimer:(NSTimer *)timer {
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
        [self.animatedMusicProgress removeFromSuperview];
        [self.batteryEfficientMusicProgress removeFromSuperview];
        if(!BATTERY_SAVER){
            [self.view addSubview:self.animatedMusicProgress];
            [self.animatedMusicProgress reloadData];
        }
        else{
            [self.view addSubview:self.batteryEfficientMusicProgress];
            [self.batteryEfficientMusicProgress reloadData];
        }
        [self.view addSubview:self.albumArt];
        [UIView animateWithDuration:0.3 animations:^{
            self.songPlacementSlider.value = currentPlaybackTime;
        }];
    }
}

- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying {
    if(nowPlaying == nil){
        self.songTitleLabel.text = @"Not playing anything, sorry";
        return;
    }
    self.songTitleLabel.textColor = [UIColor whiteColor];
    
    self.songTitleLabel.text = [nowPlaying title];
    self.songArtistLabel.text = [nowPlaying artist];
    self.songAlbumLabel.text = [nowPlaying albumTitle];
    
    self.songPlacementSlider.maximumValue = [nowPlaying playbackDuration];
    self.songPlacementSlider.value = [self.musicPlayer currentPlaybackTime];
    self.songPlacementSlider.minimumValue = 0;
    
    CGSize titleTextSize = [self.songTitleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songTitleLabel.font}];
    CGSize artistTextSize = [self.songArtistLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songArtistLabel.font}];
    CGSize albumTextSize = [self.songAlbumLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songAlbumLabel.font}];
    CGSize durationTextSize = [self.songDurationLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songDurationLabel.font}];
    
    [UIView animateWithDuration:0.4f animations:^{
        float albumArtY = self.view.frame.size.height/4;
        float textStartX = self.view.frame.size.width/3 + 20;
        
        float titleX = textStartX;
        float titleY = albumArtY;
        int titleOverflow = 0;
        if(titleTextSize.width+titleX > self.view.frame.size.width){
            titleOverflow = (titleTextSize.width+titleX)/(self.view.frame.size.width-titleX);
        }
        int titleHeight = titleTextSize.height*(titleOverflow+1)+10;
        CGRect newTitleRect = CGRectMake(titleX, titleY-(titleOverflow > 0 ? titleHeight/3 : 0), self.view.frame.size.width-titleX-10, titleHeight);
        self.songTitleLabel.frame = newTitleRect;
        
        NSLog(@"overflow of %d", titleOverflow);
        
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
        
        int newShuffleX = newSliderRect.origin.x+durationTextSize.width+10;
        CGRect newShuffleRect = CGRectMake(newShuffleX, durationOrigin+((self.view.frame.size.height-durationOrigin)/2)-playButtonSize/2, newSliderRect.size.width-durationTextSize.width-playButtonSize-20, playButtonSize);
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
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [gaussianBlurFilter setDefaults];
    CIImage *inputImage = [CIImage imageWithCGImage:[self.backgroundImageArt.image CGImage]];
    [gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
    [gaussianBlurFilter setValue:@10 forKey:kCIInputRadiusKey];
    
    CIImage *outputImage = [gaussianBlurFilter outputImage];
    CIContext *context   = [CIContext contextWithOptions:nil];
    CGImageRef cgimg     = [context createCGImage:outputImage fromRect:[inputImage extent]];
    UIImage *image       = [UIImage imageWithCGImage:cgimg];
    self.backgroundImageArt.image = image;
    
    if(self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying){
        [self.playSongButton setImage:[UIImage imageNamed:@"pause_white.png"] forState:UIControlStateNormal];
    }
    else{
        [self.playSongButton setImage:[UIImage imageNamed:@"play_white"] forState:UIControlStateNormal];
    }
    
    UISwipeGestureRecognizer *nextRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(nextSong:)];
    [nextRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:nextRecognizer];
    
    UISwipeGestureRecognizer *previousRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(previousSong:)];
    [previousRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:previousRecognizer];
}

- (void)handle_NowPlayingItemChanged:(id) sender {
    [self updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
}

- (void)handle_PlaybackStateChanged:(id) sender {
    NSLog(@"Playing state changed");
}

- (UIColor*)GetRandomUIColor:(int)index {
    UIColor *colour;
    if(index <= self.musicPlayer.currentPlaybackTime){
        colour = [UIColor colorWithRed:index*0.009 green:0.16 blue:0.17 alpha:1.0f];
    }
    else{
        colour = [UIColor clearColor];
    }
    return colour;
}

/*
 * Beautiful pie chart
 */
#pragma mark - XYPieChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart{
    return [[self.musicPlayer nowPlayingItem] playbackDuration];
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index{
    return 1;
}

- (UIColor*)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index{
    return [self GetRandomUIColor:(int)index];
}


/*
 * Battery efficient pie chart
 */
#pragma mark - PieChartViewDelegate

-(CGFloat)centerCircleRadius{
    return 1;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView{
    return [[self.musicPlayer nowPlayingItem] playbackDuration];
}

- (UIColor *)pieChartView:(PieChartView*)pieChartView colorForSliceAtIndex:(NSUInteger)index{
    return [self GetRandomUIColor:(int)index];
}

- (double)pieChartView:(PieChartView*)pieChartView valueForSliceAtIndex:(NSUInteger)index{
    return 1;
}

/*
#pragma mark - XYPieChart Delegate

- (void)pieChart:(XYPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index{
    NSLog(@"Will select");
    [self.view addSubview:self.albumArt];
    [self.view addSubview:self.animatedMusicProgress];
}

- (void)pieChart:(XYPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index{
    NSLog(@"Will deselect");
    [self.view addSubview:self.animatedMusicProgress];
    [self.view addSubview:self.albumArt];
}

- (void)pieChart:(XYPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index{
    NSLog(@"did deselect");
}
 */

- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index{
    [self.musicPlayer setCurrentPlaybackTime:index];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGPoint prevLocation = [touch previousLocationInView:self];
    int loc = location.y - prevLocation.y;
    float absoulteChange = abs(loc);
    if(absoulteChange < 25 && !self.dragged){
        NSLog(@"Not touch (%f) %d %d %d", absoulteChange, loc, (int)location.y, (int)prevLocation.y);
        return;
    }
    self.dragged = YES;
    CGPoint tappedPt = [touch locationInView: self];
    [UIView animateWithDuration:0.1 animations:^{
        CGRect newFrame = CGRectMake(self.view.frame.origin.x, tappedPt.y, self.view.frame.size.width, self.view.frame.size.height);
        self.view.frame = newFrame;
        
        float percent = tappedPt.y/(self.view.frame.size.height/2);
        self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:percent];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!self.dragged){
        return;
    }
    [UIView animateWithDuration:0.5 animations:^{
        BOOL isOverEdge = self.view.frame.origin.y >= (self.frame.size.height-self.frame.size.height/3)/2;
        
        CGRect newFrame = CGRectMake(self.view.frame.origin.x, isOverEdge ? self.view.frame.size.height/4 * 3 : 0, self.view.frame.size.width, self.view.frame.size.height);
        self.view.frame = newFrame;
        
        self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha: isOverEdge ? 1 : 0];
    }];
    self.dragged = NO;
}

- (void)viewDidLoad {
    self.view = [[UIView alloc]initWithFrame:self.frame];
    [self addSubview:self.view];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.backgroundImageArt = [[UIImageView alloc]initWithFrame:CGRectMake(-20, -20, self.view.frame.size.width+40, self.view.frame.size.height+40)];
    self.backgroundImageArt.contentMode = UIViewContentModeScaleAspectFill;
    [self.backgroundImageArt setClipsToBounds:YES];
    [self.view addSubview:self.backgroundImageArt];
    
    self.backgroundView = [[UIView alloc]initWithFrame:self.backgroundImageArt.frame];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backgroundView];
    
    float textStartX = self.view.frame.size.width/3 + 20;
    float textHeight = 30.0f;
    float albumArtSize = self.view.frame.size.height/5;
    float albumOriginX = textStartX/2 - albumArtSize;
    float albumArtY = self.view.frame.size.height/2 - albumArtSize;
    
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
    self.songArtistLabel.numberOfLines = 0;
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
    
    CGRect pieChartFrame = CGRectMake(albumOriginX-10, albumArtY-10, albumArtSize*2 + 20, albumArtSize*2 + 20);
    
    self.batteryEfficientMusicProgress = [[PieChartView alloc]initWithFrame:pieChartFrame];
    self.batteryEfficientMusicProgress.delegate = self;
    self.batteryEfficientMusicProgress.datasource = self;
    
    self.animatedMusicProgress = [[XYPieChart alloc]initWithFrame:pieChartFrame];
    [self.animatedMusicProgress setDataSource:self];
    [self.animatedMusicProgress setDelegate:self];
    [self.animatedMusicProgress setAnimationSpeed:1.0];
    //[self.animatedMusicProgress setLabelFont:[UIFont fontWithName:@"DBLCDTempBlack" size:24]];
    [self.animatedMusicProgress setPieBackgroundColor:[UIColor clearColor]];
    [self.animatedMusicProgress setPieRadius:75];
    //[self.animatedMusicProgress setPieCenter:CGPointMake(CGRectGetMidX(self.animatedMusicProgress.frame), CGRectGetMidY(self.animatedMusicProgress.frame))];
    [self.animatedMusicProgress setUserInteractionEnabled:YES];
    [self.animatedMusicProgress setLabelShadowColor:[UIColor clearColor]];
    [self.view addSubview:self.animatedMusicProgress];
    
    self.albumArt = [[UIImageView alloc]initWithFrame:CGRectMake(albumOriginX, albumArtY, albumArtSize*2, albumArtSize*2)];
    self.albumArt.layer.cornerRadius = self.albumArt.frame.size.width/2;
    self.albumArt.layer.masksToBounds = YES;
    [self.view addSubview:self.albumArt];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    [self onTimer:nil];
    if([self.musicPlayer nowPlayingItem]){
        [self updateNowPlayingItem:[self.musicPlayer nowPlayingItem]];
    }
    else{
        [self.musicPlayer setQueueWithQuery:[MPMediaQuery songsQuery]];
        [self.musicPlayer play];
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

@end
