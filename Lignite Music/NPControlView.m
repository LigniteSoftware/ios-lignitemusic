//
//  NPControlView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NPControlView.h"

#define durationSize 16.0f

@interface NPControlView()

@property UIDeviceOrientation currentOrientation;
@property BOOL isLandscape;

@property UILabel *songDurationLabel;
@property UIButton *playSongButton, *shuffleButton, *repeatButton;
@property UISlider *songPlacementSlider;
@property NSTimer *currentTimer;

@property MPMusicPlayerController *musicPlayer;

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
    //[self onTimer:nil];
    //self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

/*
 Sets whether or not the music is playing, and updates the UI accordingly.
 */
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

/*
 Sets the shuffle status of the music. There are 4 states; all of which are manually drawn.
 */
- (IBAction)setShuffle:(id)sender {
    
}

/*
 Sets the repeat status of the music. There are 4 states; all of which are manually drawn.
 */
- (IBAction)setRepeat:(id)sender {

}

/*
 This function is called when the music content changes internally, or when someone selects a new song.
 It updates the UI to fit the new item.
 */
- (void)updateWithMediaItem:(MPMediaItem*)newItem {
    NSLog(@"Updating controller for media item");
}

/*
 Update the rotation: this sets the frames of every item accordingly.
 */
- (void)updateWithOrientation:(UIDeviceOrientation)newOrientation{
    self.frame = WINDOW_FRAME;
    self.isLandscape = self.frame.size.height < self.frame.size.width;
    
    NSLog(@"isLandscape %d", self.isLandscape);
   /*
    switch(newOrientation){
            case UIDe
    }
    */
}

/*
 Initializes the control view with all standard elements: duration, song placement slider, play button,
 shuffle button, repeat button, and the music player.
 */
- (id)initWithMusicPlayer:(MPMusicPlayerController*)musicPlayer{
    self = [super init];
    
    self.musicPlayer = musicPlayer;
    
    self.backgroundColor = [UIColor orangeColor];
    
    self.playSongButton = [[UIButton alloc]init];
    [self.playSongButton setImage:[UIImage imageNamed:@"play_white.png"] forState:UIControlStateNormal];
    [self.playSongButton addTarget:self action:@selector(setPlaying:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playSongButton];
    
    self.songDurationLabel = [[UILabel alloc]init];
    self.songDurationLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:durationSize];
    self.songDurationLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.songDurationLabel];
    
    self.shuffleButton = [[UIButton alloc]init];
    self.shuffleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.shuffleButton setImage:[UIImage imageNamed:@"shuffle_white.png"] forState:UIControlStateNormal];
    [self addSubview:self.shuffleButton];
    
    self.repeatButton = [[UIButton alloc]init];
    self.repeatButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.repeatButton setImage:[UIImage imageNamed:@"repeat_white.png"] forState:UIControlStateNormal];
    [self addSubview:self.repeatButton];
    
    self.songPlacementSlider = [[UISlider alloc]init];
    self.songPlacementSlider.tintColor = LIGNITE_COLOUR;
    [self.songPlacementSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.songPlacementSlider];
    
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
