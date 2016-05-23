//
//  ViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/18/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMNowPlayingView.h"

@interface LMNowPlayingView ()

@property UIDeviceOrientation currentOrientation;

@property UIView *backgroundView;
@property UIImageView *backgroundImageArt;
@property NSTimer *currentTimer;

@property (nonatomic) NowPlayingViewMode viewMode;
@property BOOL dragged;
@property BOOL doNotContinueTouch;

@end

@implementation LMNowPlayingView

//http://stackoverflow.com/questions/17878462/mpmovieplayercontroller-getting-a-reliable-non-skipping-currentplaybacktime
#define BATTERY_SAVER NO

- (IBAction)nextSong:(id)sender {
    //[self.musicPlayer setNowPlayingItem:[[[MPMediaQuery songsQuery] items] objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]+1]];
    [self.musicPlayer skipToNextItem];
}

- (IBAction)previousSong:(id)sender {
    //[self.musicPlayer setNowPlayingItem:[[[MPMediaQuery songsQuery] items] objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]-1]];
    [self.musicPlayer skipToPreviousItem];
}

- (NowPlayingViewMode)getviewMode {
    return self.viewMode;
}

- (void)updateNowPlayingItem:(MPMediaItem*)nowPlaying {
    /*
    CGRect newInfoRect;
    if(IS_PORTRAIT){
        newInfoRect = CGRectMake(0, self.frame.size.height/4 * 2, self.frame.size.width, self.frame.size.height/3);
    }
    else{
        CGPoint infoOrigin = CGPointMake(newAlbumArtRect.origin.x+newAlbumArtRect.size.width+10, newAlbumArtRect.origin.y+newAlbumArtRect.size.height);
        newInfoRect = CGRectMake(infoOrigin.x, newAlbumArtRect.origin.y, self.frame.size.width-infoOrigin.x, 100);
    }
    [self.songInfoView updateContentWithFrame:newInfoRect isPortrait:IS_PORTRAIT];
        
    CGRect newControlRect;
    if(IS_PORTRAIT){
        newControlRect = CGRectMake(20, self.frame.size.height/4 * 2.7 + 20, self.frame.size.width - 40, self.frame.size.height/4 * 1.3 - 40);
    }
    else{
        int albumX = newAlbumArtRect.size.width+5;
        int startingControlY = newInfoRect.origin.y+newInfoRect.size.height;
        newControlRect = CGRectMake(albumX, startingControlY, self.frame.size.width-albumX-20, self.frame.size.height-startingControlY-20);
    }
    [self.controlView updateWithRootFrame:newControlRect withViewMode:self.viewMode];
     */
     
    
    CGSize size = self.frame.size;
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
    
    [self.controlView updateWithMediaItem:nowPlaying];
    [self.songInfoView updateContentWithMediaItem:nowPlaying];
    [self.albumArtView updateContentWithMusicPlayer:self.musicPlayer];
}

- (bool)isMiniPlayer {
    return (self.viewMode == NowPlayingViewModeMiniPortrait) || (self.viewMode == NowPlayingViewModeMiniLandscape);
}

- (void) orientationChanged:(NSNotification*)note{
    return;
    
    UIDevice *device = note.object;
    self.currentOrientation = device.orientation;
    switch(self.currentOrientation){
        case UIDeviceOrientationPortrait:
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            break;
        default:
            break;
    }
    self.frame = WINDOW_FRAME;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect newBackgroundFrame = WINDOW_FRAME;
        newBackgroundFrame.origin.x -= 20;
        newBackgroundFrame.origin.y -= 20;
        newBackgroundFrame.size.width += 40;
        newBackgroundFrame.size.height += 40;
        self.backgroundImageArt.frame = newBackgroundFrame;
    }];
    [self updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
    //[self.controlView updateWithOrientation:device.orientation];
}

- (id)initWithFrame:(CGRect)frame withViewMode:(NowPlayingViewMode)newViewMode {
    self = [super initWithFrame:frame];
    if(self){
        self.viewMode = newViewMode;
        [self setupView];
    }
    else{
        NSLog(@"Failed to initialize LMNowPLayingView with a frame, sadly.");
    }
    return self;
}

- (void)setupView {
    /*
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
     */
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    self.backgroundImageArt = [[UIImageView alloc]initWithFrame:CGRectMake(-20, -20, self.frame.size.width+40, self.frame.size.height+40)];
    self.backgroundImageArt.contentMode = UIViewContentModeScaleAspectFill;
    [self.backgroundImageArt setClipsToBounds:YES];
    if(![self isMiniPlayer]){
        [self addSubview:self.backgroundImageArt];
    }
    
    self.backgroundView = [[UIView alloc]initWithFrame:self.backgroundImageArt.frame];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.backgroundView];

    self.albumArtView = [[NPAlbumArtView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width/3, self.frame.size.width/3)];
    self.albumArtView.musicPlayer = self.musicPlayer;
    //self.albumArtView.backgroundColor = [UIColor redColor];
    [self addSubview:self.albumArtView];
    
    self.songInfoView = [[NPTextInfoView alloc]initWithFrame:CGRectMake(self.frame.size.width/3, 0, self.frame.size.width/3 * 2 - 10, self.frame.size.height * 0.6) withMiniPlayerStatus:[self isMiniPlayer]];
    //self.songInfoView.backgroundColor = [UIColor blueColor];
    [self addSubview:self.songInfoView];
    
    self.controlView = [[NPControlView alloc] initWithMusicPlayer:self.musicPlayer withViewMode:self.viewMode onFrame:CGRectMake(self.frame.size.width/3, self.songInfoView.frame.origin.y + self.songInfoView.frame.size.height, self.frame.size.width/3 * 2 - 10, 50)];
    [self addSubview:self.controlView];
    
    if([self.musicPlayer nowPlayingItem]){
        NSLog(@"now playing");
        [self updateNowPlayingItem:[self.musicPlayer nowPlayingItem]];
    }
    else{
        NSLog(@"not playing");
        [self.musicPlayer setQueueWithQuery:[MPMediaQuery songsQuery]];
        [self.musicPlayer play];
        NSLog(@"Got a now plaing item current of %@", self.musicPlayer);
        [self updateNowPlayingItem:[self.musicPlayer nowPlayingItem]];
    }
        
    UISwipeGestureRecognizer *nextRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(nextSong:)];
    [nextRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self addGestureRecognizer:nextRecognizer];
    
    UISwipeGestureRecognizer *previousRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(previousSong:)];
    [previousRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self addGestureRecognizer:previousRecognizer];
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

/*
 * Old shit
 *
 - (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event{
 UITouch *touch = [touches anyObject];
 CGPoint location = [touch locationInView:self];
 switch(self.viewMode){
 case NOW_PLAYING_VIDE_MODE_COMPRESSED:
 case NOW_PLAYING_VIEW_MODE_HIDDEN:
 if(location.y <= self.frame.origin.y){
 self.doNotContinueTouch = YES;
 }
 break;
 case NOW_PLAYING_VIEW_MODE_FULLSCREEN:
 break;
 }
 }
 
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 if(self.doNotContinueTouch){
 return;
 }
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
 CGRect newFrame = CGRectMake(self.frame.origin.x, tappedPt.y, self.frame.size.width, self.frame.size.height);
 self.frame = newFrame;
 
 float percent = tappedPt.y/(self.frame.size.height/4 * 3);
 self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:percent];
 }];
 }
 
 - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
 self.doNotContinueTouch = NO;
 if(!self.dragged){
 return;
 }
 [UIView animateWithDuration:0.5 animations:^{
 BOOL isOverEdge = self.frame.origin.y >= (self.frame.size.height-self.frame.size.height/3)/2;
 
 CGRect newFrame = CGRectMake(self.frame.origin.x, isOverEdge ? self.frame.size.height/4 * 3 : 0, self.frame.size.width, self.frame.size.height);
 self.frame = newFrame;
 
 self.viewMode = isOverEdge ? NOW_PLAYING_VIDE_MODE_COMPRESSED : NOW_PLAYING_VIEW_MODE_FULLSCREEN;
 
 self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha: isOverEdge ? 1 : 0];
 }];
 self.dragged = NO;
 }
 */

@end
