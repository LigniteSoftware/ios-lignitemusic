//
//  NPControlView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NPControlView.h"
#import "LMButton.h"
#import "LMNowPlayingView.h"

#define durationSize 16.0f

@interface NPControlView() <LMButtonDelegate>

@property UIDeviceOrientation currentOrientation;
@property BOOL isLandscape;
@property NowPlayingViewMode viewMode;

@property UILabel *songDurationLabel;
@property UIButton *playSongButton;
@property UISlider *songPlacementSlider;
@property LMButton *shuffleButton, *repeatButton;

@property NSTimer *currentTimer;

@property MPMusicPlayerController *musicPlayer;

@property NowPlayingViewMode currentViewMode;
@property MPMusicShuffleMode shuffleMode;
@property MPMusicRepeatMode repeatMode;

@end

@implementation NPControlView

/*
 Sets the current position of the song using songPlacementSlider.
 */
- (IBAction)setTimelinePosition:(id)sender {
    UISlider *slider = sender;
    if(self.currentTimer){
        [self.currentTimer invalidate];
    }
    self.musicPlayer.currentPlaybackTime = [slider value];
    [self onTimer:nil];
    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
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
            self.songPlacementSlider.value = currentPlaybackTime;
        }];
    }
    
    CGSize durationTextSize = [self.songDurationLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songDurationLabel.font}];
    CGRect newDurationFrame = CGRectMake(self.songPlacementSlider.frame.origin.x, self.songPlacementSlider.frame.origin.y+self.songPlacementSlider.frame.size.height+10, durationTextSize.width, durationTextSize.height);
    self.songDurationLabel.frame = newDurationFrame;
}

/*
 Sets whether or not the music is playing, and updates the UI accordingly.
 */
- (IBAction)setPlaying:(id)sender {
    NSLog(@"Got an actual playback state of %d sender is nil %d", (int)self.musicPlayer.playbackState, (sender == nil));
    if(sender != nil){
        self.musicPlayer.playbackState == MPMusicPlaybackStatePaused ? [self.musicPlayer play] : [self.musicPlayer pause];
    }
    
    if(self.musicPlayer.playbackState != MPMusicPlaybackStatePaused){
        [self.playSongButton setImage:[UIImage imageNamed:@"pause_white.png"] forState:UIControlStateNormal];
    }
    else{
        [self.playSongButton setImage:[UIImage imageNamed:@"play_white.png"] forState:UIControlStateNormal];
    }
}

/*
 Sets the shuffle or repeat status of the music. See MPMusicShuffleMode and MPMusicRepeatMode.
 */
- (void)clickedButton:(LMButton *)button {
    NSString *shuffleArray[] = {
        @"Default", @"Off", @"Songs", @"Albums"
    };
    NSString *repeatArray[] = {
        @"Default", @"Off", @"This", @"All"
    };
    if(button == self.shuffleButton){
        self.shuffleMode++;
        if(self.shuffleMode > MPMusicShuffleModeAlbums){
            self.shuffleMode = 0;
        }
        [self.musicPlayer setShuffleMode:self.shuffleMode];
        [self.shuffleButton setTitle:shuffleArray[self.shuffleMode]];
    }
    else{
        self.repeatMode++;
        if(self.repeatMode > MPMusicRepeatModeAll){
            self.repeatMode = 0;
        }
        [self.musicPlayer setRepeatMode:self.repeatMode];
        [self.repeatButton setTitle:repeatArray[self.repeatMode]];
    }
    
    NSLog(@"Shuffle mode is %d, repeat mode is %d", (int)self.shuffleMode, (int)self.repeatMode);
}

/*
 This function is called when the music content changes internally, or when someone selects a new song.
 It updates the UI to fit the new item.
 */
- (void)updateWithMediaItem:(MPMediaItem*)newItem {
    self.songPlacementSlider.maximumValue = [newItem playbackDuration];
}

/*
 Updates the whole view with new frames
 */
- (void)updateWithRootFrame:(CGRect)newRootFrame withViewMode:(BOOL)newViewMode {
    self.currentViewMode = newViewMode;
    
    static int padding = 10;
    
    int buttonSize = 40;
    CGRect newPlayButtonFrame = CGRectMake(0, 0, buttonSize, buttonSize);
    
    int sliderOriginX = newPlayButtonFrame.size.width+padding;
    CGRect newSliderFrame = CGRectMake(sliderOriginX, 0, self.frame.size.width-sliderOriginX-padding, buttonSize);
    
    CGSize durationTextSize = [self.songDurationLabel.text sizeWithAttributes:@{NSFontAttributeName: self.songDurationLabel.font}];

    CGRect newDurationFrame = CGRectMake(sliderOriginX, newSliderFrame.origin.y+newSliderFrame.size.height+padding, durationTextSize.width, durationTextSize.height);
    
    /*
    CGRect newShuffleFrame, newRepeatFrame;
    switch(self.currentViewMode){
        case NOW_PLAYING_VIEW_MODE_LANDSCAPE:
            newShuffleFrame = CGRectMake(newDurationFrame.origin.x+newDurationFrame.size.width, newDurationFrame.origin.y, buttonSize, buttonSize);
            break;
        case NOW_PLAYING_VIEW_MODE_PORTRAIT:
            newShuffleFrame = CGRectMake(newDurationFrame.origin.x+newDurationFrame.size.width, newDurationFrame.origin.y+newDurationFrame.size.height, buttonSize, buttonSize);
            break;
        default:
            NSAssert(NO, @"Cannot handle the current view mode.");
            break;
    }
     */
    
    CGSize controlButtonSize = CGSizeMake(60, 70);
    CGPoint controlButtonOrigin = CGPointMake(self.frame.size.width/2 - controlButtonSize.width - 10, self.frame.size.height-controlButtonSize.height);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = newRootFrame;
        self.playSongButton.frame = newPlayButtonFrame;
        self.songPlacementSlider.frame = newSliderFrame;
        self.songDurationLabel.frame = newDurationFrame;
    }];
    [self.shuffleButton updateWithFrame:CGRectMake(controlButtonOrigin.x, controlButtonOrigin.y, controlButtonSize.width, controlButtonSize.height)];
    [self.repeatButton updateWithFrame:CGRectMake(controlButtonOrigin.x + 20 + controlButtonSize.width, controlButtonOrigin.y, controlButtonSize.width, controlButtonSize.height)];
    /*
    int startingY = albumY+newAlbumRect.size.height+10;
    int playButtonSize = 35;
    
    CGRect newPlayRect = CGRectMake(albumX-5, startingY, playButtonSize, playButtonSize);
    self.playSongButton.frame = newPlayRect;
    
    CGRect newSliderRect = CGRectMake(albumX+playButtonSize, startingY, self.frame.size.width-albumX-playButtonSize*2, playButtonSize);
    self.songPlacementSlider.frame = newSliderRect;
    
    int durationOrigin = newSliderRect.origin.y+newSliderRect.size.height;
    CGRect newDurationRect = CGRectMake(newSliderRect.origin.x, durationOrigin, newSliderRect.size.width, self.frame.size.height-durationOrigin);
    self.songDurationLabel.frame = newDurationRect;
    
    int newShuffleX = newSliderRect.origin.x+durationTextSize.width+10;
    CGRect newShuffleRect = CGRectMake(newShuffleX, durationOrigin+((self.frame.size.height-durationOrigin)/2)-playButtonSize/2, newSliderRect.size.width-durationTextSize.width-playButtonSize-20, playButtonSize);
    self.shuffleButton.frame = newShuffleRect;
    
    int newRepeatX = newSliderRect.origin.x+newSliderRect.size.width-playButtonSize-10;
    CGRect newRepeatRect = CGRectMake(newRepeatX, newShuffleRect.origin.y, playButtonSize, playButtonSize);
    self.repeatButton.frame = newRepeatRect;
     */
}

- (bool)isMiniPlayer {
    return (self.viewMode == NowPlayingViewModeMiniPortrait) || (self.viewMode == NowPlayingViewModeMiniLandscape);
}

/*
 Initializes the control view with all standard elements: duration, song placement slider, play button,
 shuffle button, repeat button, and the music player.
 */

- (id)initWithMusicPlayer:(MPMusicPlayerController*)musicPlayer withViewMode:(uint8_t)viewMode onFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.musicPlayer = musicPlayer;
    self.viewMode = (NowPlayingViewMode)viewMode;
    
    //self.backgroundColor = [UIColor orangeColor];
    
    self.playSongButton = [[UIButton alloc]init];
    [self.playSongButton setImage:[UIImage imageNamed:@"play_white.png"] forState:UIControlStateNormal];
    [self.playSongButton addTarget:self action:@selector(setPlaying:) forControlEvents:UIControlEventTouchUpInside];
    //[self addSubview:self.playSongButton];
    
    self.songDurationLabel = [[UILabel alloc]init];
    self.songDurationLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:durationSize];
    self.songDurationLabel.textColor = [UIColor whiteColor];
    self.songDurationLabel.text = @"Hello there";
    if(![self isMiniPlayer]){
        [self addSubview:self.songDurationLabel];
    }
    
    CGRect songPlacementSliderFrame;
    if([self isMiniPlayer]){
        songPlacementSliderFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
    else{
        songPlacementSliderFrame = CGRectMake(0, 0, 0, 0);
    }
    self.songPlacementSlider = [[UISlider alloc]initWithFrame:songPlacementSliderFrame];
    self.songPlacementSlider.tintColor = LIGNITE_COLOUR;
    [self.songPlacementSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.songPlacementSlider];
    
    /*
    
    CGSize controlButtonSize = CGSizeMake(self.frame.size.width/6, self.frame.size.width/4 - 40);
    CGPoint controlButtonOrigin = CGPointMake(self.frame.size.width/2 - controlButtonSize.width - 20, self.frame.size.height-controlButtonSize.height-20);
    
    self.shuffleButton = [[LMButton alloc]initWithTitle:@"Default" withImage:[UIImage imageNamed:@"shuffle_black.png"] withFrame:CGRectMake(controlButtonOrigin.x, controlButtonOrigin.y, controlButtonSize.width, controlButtonSize.height)];
    self.shuffleButton.backgroundColor = [UIColor whiteColor];
    self.shuffleButton.delegate = self;
    if(![self isMiniPlayer]){
        [self addSubview:self.shuffleButton];
    }
    
    self.repeatButton = [[LMButton alloc]initWithTitle:@"Default" withImage:[UIImage imageNamed:@"repeat_black.png"] withFrame:CGRectMake(controlButtonOrigin.x + 40 + controlButtonSize.width, controlButtonOrigin.y, controlButtonSize.width, controlButtonSize.height)];
    self.repeatButton.backgroundColor = [UIColor whiteColor];
    self.repeatButton.delegate = self;
    if(![self isMiniPlayer]){
        [self addSubview:self.repeatButton];
    }
     
     */
    
    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
