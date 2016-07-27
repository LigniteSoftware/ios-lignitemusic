//
//  TestViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <AVFoundation/AVAudioSession.h>
#import <PebbleKit/PebbleKit.h>
#import <YYImage/YYImage.h>
#import "LMNowPlayingViewController.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "KBPebbleImage.h"
#import "KBPebbleMessageQueue.h"

@interface LMNowPlayingViewController () <LMButtonDelegate, UIGestureRecognizerDelegate, PBPebbleCentralDelegate>

#define IPOD_RECONNECT_KEY @(0xFEFF)
#define IPOD_REQUEST_LIBRARY_KEY @(0xFEFE)
#define IPOD_REQUEST_OFFSET_KEY @(0xFEFB)
#define IPOD_LIBRARY_RESPONSE_KEY @(0xFEFD)
#define IPOD_NOW_PLAYING_KEY @(0xFEFA)
#define IPOD_REQUEST_PARENT_KEY @(0xFEF9)
#define IPOD_PLAY_TRACK_KEY @(0xFEF8)
#define IPOD_NOW_PLAYING_RESPONSE_TYPE_KEY @(0xFEF7)
#define IPOD_ALBUM_ART_KEY @(0xFEF6)
#define IPOD_ALBUM_ART_LENGTH_KEY @(0xFEF5)
#define IPOD_ALBUM_ART_INDEX_KEY @(0xFEF4)
#define IPOD_CHANGE_STATE_KEY @(0xFEF3)
#define IPOD_CURRENT_STATE_KEY @(0xFEF2)
#define IPOD_SEQUENCE_NUMBER_KEY @(0xFEF1)

#define MAX_LABEL_LENGTH 20
#define MAX_RESPONSE_COUNT 15
#define MAX_OUTGOING_SIZE 500 // This allows some overhead.

typedef enum {
    NowPlayingTitle,
    NowPlayingArtist,
    NowPlayingAlbum,
    NowPlayingTitleArtist,
    NowPlayingNumbers,
} NowPlayingType;

typedef enum {
    NowPlayingStatePlayPause = 1,
    NowPlayingStateSkipNext,
    NowPlayingStateSkipPrevious,
    NowPlayingStateVolumeUp,
    NowPlayingStateVolumeDown
} NowPlayingState;

@property NSTimer *refreshTimer;
@property UIView *shadingView;
@property BOOL finishedUserAdjustment;
@property BOOL loadedSubviews;

@property MPMusicShuffleMode shuffleMode;
@property MPMusicRepeatMode repeatMode;

@property int firstX, firstY;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property KBPebbleMessageQueue *messageQueue;

@end

@implementation LMNowPlayingViewController

- (void)move:(id)sender {
    UIView *viewToMove = (UIView*)self.contentContainerView;
    int sizeOfFavouritesSpace = self.view.frame.size.height/6;
    int halfHeight = self.view.frame.size.height/2;
    
    [self.view bringSubviewToFront:viewToMove];
    CGPoint translatedPoint = [sender translationInView:viewToMove];
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        self.firstX = [viewToMove center].x;
        self.firstY = [viewToMove center].y;
    }
    
    translatedPoint = CGPointMake(self.firstX, self.firstY+translatedPoint.y);
    
    if(translatedPoint.y > self.view.frame.size.height/2){
        [viewToMove setCenter:translatedPoint];
    }
    NSLog(@"translated %@", NSStringFromCGPoint(translatedPoint));
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityY = (0.1*[sender velocityInView:viewToMove].y);
        
        CGFloat finalX = self.firstX;
        CGFloat finalY = translatedPoint.y + velocityY;
        
        NSLog(@"final %f", finalY);
       // if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        if (finalY >= halfHeight && finalY < (halfHeight + sizeOfFavouritesSpace/2)) {
            finalY = halfHeight;
        } else if (finalY >= (halfHeight + sizeOfFavouritesSpace/2) && finalY <= (halfHeight + sizeOfFavouritesSpace)) {
            finalY = halfHeight + sizeOfFavouritesSpace;
        }
        else if(finalY < halfHeight){
            return;
        }
        else{
            if(finalY > halfHeight + sizeOfFavouritesSpace*3){
                NSLog(@"FIRE!");
                finalY = halfHeight;
            }
            else{
                finalY = halfHeight + sizeOfFavouritesSpace;
            }
        }
        NSLog(@"now final %f", finalY);
        
        CGFloat animationDuration = (ABS(velocityY)*.0002)+.2;
        
        NSLog(@"the duration is: %f", animationDuration);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        //[UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
        [viewToMove setCenter:CGPointMake(finalX, finalY)];
        [UIView commitAnimations];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
    return fabs(velocity.y) > fabs(velocity.x);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (void)nowPlayingItemChanged:(id) sender {
    //[self.playingView updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
    [self.songTitleLabel setText:self.musicPlayer.nowPlayingItem.title];
    [self.songArtistLabel setText:self.musicPlayer.nowPlayingItem.artist];
    [self.songAlbumLabel setText:self.musicPlayer.nowPlayingItem.albumTitle];
    [self.songNumberLabel setText:[NSString stringWithFormat:@"Song %lu of %lu", self.musicPlayer.nowPlayingItem.albumTrackNumber, self.musicPlayer.nowPlayingItem.albumTrackCount]];
    
    self.songDurationSlider.maximumValue = self.musicPlayer.nowPlayingItem.playbackDuration;
    //self.songDurationSlider.value = self.musicPlayer.currentPlaybackTime;
    [self updateSongDurationLabelWithPlaybackTime:self.musicPlayer.currentPlaybackTime];
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
        
        UIColor *averageColour = [albumImage averageColour];
        BOOL isLight = [averageColour isLight];
        self.shadingView.backgroundColor = isLight ? [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25] : [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
        UIColor *newTextColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
        self.songTitleLabel.textColor = newTextColour;
        self.songArtistLabel.textColor = newTextColour;
        self.songAlbumLabel.textColor = newTextColour;
        self.songDurationLabel.textColor = newTextColour;
        self.songNumberLabel.textColor = newTextColour;
        self.shuffleButton.titleLabel.textColor = newTextColour;
        self.repeatButton.titleLabel.textColor = newTextColour;
        self.dynamicPlaylistButton.titleLabel.textColor = newTextColour;
        
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
        NSLog(@"Music player current playback set to %f", self.musicPlayer.currentPlaybackTime);
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

- (void)reloadButtonTitles {
    NSString *shuffleArray[] = {
        @"Default", @"Off", @"Songs", @"Albums"
    };
    NSString *repeatArray[] = {
        @"Default", @"Off", @"This", @"All"
    };
    [self.shuffleButton setTitle:shuffleArray[self.musicPlayer.shuffleMode]];
    [self.repeatButton setTitle:repeatArray[self.musicPlayer.repeatMode]];
}

/*
 Sets the shuffle or repeat status of the music. See MPMusicShuffleMode and MPMusicRepeatMode.
 */
- (void)clickedButton:(LMButton *)button {
    if(button == self.shuffleButton){
        self.shuffleMode++;
        if(self.shuffleMode > MPMusicShuffleModeAlbums){
            self.shuffleMode = 0;
        }
        [self.musicPlayer setShuffleMode:self.shuffleMode];
    }
    else{
        self.repeatMode++;
        if(self.repeatMode > MPMusicRepeatModeAll){
            self.repeatMode = 0;
        }
        [self.musicPlayer setRepeatMode:self.repeatMode];
    }
    [self reloadButtonTitles];
    
    NSLog(@"Shuffle mode is %d, repeat mode is %d", (int)self.musicPlayer.shuffleMode, (int)self.musicPlayer.repeatMode);
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
    else{
        self.musicPlayer.currentPlaybackTime = slider.value;
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
        difference = labelSize.height - [testString sizeWithAttributes:@{NSFontAttributeName: tempFont}].height;
        
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

- (void)sendMessageToPebble:(NSDictionary*)toSend {
    /*
    [self.watch appMessagesPushUpdate:toSend onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if(error) {
            NSLog(@"Error sending update: %@", error);
        }
    }];
     */
    [self.messageQueue enqueue:toSend];
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)sendImageToPebble:(UIImage*)image {
    /*
    PBBitmap* pbBitmap = [PBBitmap pebbleBitmapWithUIImage:image];
    
    size_t length = [pbBitmap.pixelData length];
    uint8_t j = 0;
    
    for(size_t i = 0; i < length; i += MAX_OUTGOING_SIZE-1) {
        NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
        [outgoing appendData:[pbBitmap.pixelData subdataWithRange:NSMakeRange(i, MIN(MAX_OUTGOING_SIZE-1, length - i))]];
        
        NSDictionary *dict = @{IPOD_ALBUM_ART_KEY: outgoing, IPOD_ALBUM_ART_INDEX_KEY:[NSNumber numberWithUint16:j]};
        NSLog(@"Sending image dict %@", dict);
        [self sendMessageToPebble:dict];

        j++;
    }
     */
    
    NSData *bitmap = [KBPebbleImage ditheredBitmapFromImage:image withHeight:64 width:64];
    
    size_t length = [bitmap length];
    NSDictionary *sizeDict = @{IPOD_ALBUM_ART_LENGTH_KEY: [NSNumber numberWithUint16:[bitmap length]]};
    NSLog(@"sizedict %@", sizeDict);
    [self sendMessageToPebble:sizeDict];
    uint8_t j = 0;
    for(size_t i = 0; i < length; i += MAX_OUTGOING_SIZE-1) {
        NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
        [outgoing appendData:[bitmap subdataWithRange:NSMakeRange(i, MIN(MAX_OUTGOING_SIZE-1, length - i))]];
        NSDictionary *dict = @{IPOD_ALBUM_ART_KEY: outgoing, IPOD_ALBUM_ART_INDEX_KEY:[NSNumber numberWithUint16:j]};
        NSLog(@"Sending image dict %@", dict);
        [self sendMessageToPebble:dict];
        j++;
    }
}

- (void)pushNowPlayingItemToWatch:(BOOL)detailed {
    MPMediaItem *item = [self.musicPlayer nowPlayingItem];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    if(!title) title = @"";
    if(!artist) artist = @"";
    if(!album) album = @"";
    if(!detailed) {
        NSString *value;
        if(!item) {
            value = @"Nothing playing.";
        } else {
            value = [NSString stringWithFormat:@"%@ - %@", title, artist, nil];
        }
        if([value length] > MAX_OUTGOING_SIZE) {
            value = [value substringToIndex:MAX_OUTGOING_SIZE];
        }
        [self sendMessageToPebble:@{IPOD_NOW_PLAYING_KEY: value, IPOD_NOW_PLAYING_RESPONSE_TYPE_KEY: @(NowPlayingTitleArtist)}];
        NSLog(@"Now playing: %@", value);
    } else {
        NSLog(@"Pushing everything.");
        //[self pushCurrentStateToWatch:watch];
        [self sendMessageToPebble:@{IPOD_NOW_PLAYING_KEY: title, IPOD_NOW_PLAYING_RESPONSE_TYPE_KEY: @(NowPlayingTitle)}];
        [self sendMessageToPebble:@{IPOD_NOW_PLAYING_KEY: artist, IPOD_NOW_PLAYING_RESPONSE_TYPE_KEY:@(NowPlayingArtist)}];
        [self sendMessageToPebble:@{IPOD_NOW_PLAYING_KEY: album, IPOD_NOW_PLAYING_RESPONSE_TYPE_KEY: @(NowPlayingAlbum)}];
        
        // Get and send the artwork.
        MPMediaItemArtwork *artwork = [item valueForProperty:MPMediaItemPropertyArtwork];
        if(artwork) {
            UIImage* image = [artwork imageWithSize:CGSizeMake(64, 64)];
            if(!image) {
                [self sendMessageToPebble:@{IPOD_ALBUM_ART_KEY: [NSNumber numberWithUint8:255]}];
            }
            else {
                NSLog(@"Sending image...");
                /*
                NSData *bitmap = [KBPebbleImage ditheredBitmapFromImage:image withHeight:64 width:64];
                
                size_t length = [bitmap length];
                NSDictionary *sizeDict = @{IPOD_ALBUM_ART_LENGTH_KEY: [NSNumber numberWithUint16:[bitmap length]]};
                NSLog(@"sizedict %@", sizeDict);
                [self sendMessageToPebble:sizeDict];
                uint8_t j = 0;
                for(size_t i = 0; i < length; i += MAX_OUTGOING_SIZE-1) {
                    NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
                    [outgoing appendData:[bitmap subdataWithRange:NSMakeRange(i, MIN(MAX_OUTGOING_SIZE-1, length - i))]];
                    NSDictionary *dict = @{IPOD_ALBUM_ART_KEY: outgoing, IPOD_ALBUM_ART_INDEX_KEY:[NSNumber numberWithUint16:j]};
                    NSLog(@"Sending image dict %@", dict);
                    [self sendMessageToPebble:dict];
                    ++j;
                }
                 */
                [self sendImageToPebble:image];
            }
        }
    }
}

- (void)pushCurrentStateToWatch:(PBWatch *)watch {
    uint16_t current_time = (uint16_t)[self.musicPlayer currentPlaybackTime];
    uint16_t total_time = (uint16_t)[[[self.musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    uint8_t metadata[] = {
        [self.musicPlayer playbackState],
        [self.musicPlayer shuffleMode],
        [self.musicPlayer repeatMode],
        total_time >> 8, total_time & 0xFF,
        current_time >> 8, current_time & 0xFF
    };
    NSLog(@"Current state: %@", [NSData dataWithBytes:metadata length:7]);
    [self sendMessageToPebble:@{IPOD_CURRENT_STATE_KEY: [NSData dataWithBytes:metadata length:7]}];
}

- (void)changeState:(NowPlayingState)state {
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    volumeView.showsRouteButton = NO;
    volumeView.showsVolumeSlider = NO;
    [self.view addSubview:volumeView];
    
    // Get the Volume Slider
    UISlider* volumeViewSlider = nil;
    
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }

    switch(state) {
        case NowPlayingStatePlayPause:
            if([self.musicPlayer playbackState] == MPMusicPlaybackStatePlaying) [self.musicPlayer pause];
            else [self.musicPlayer play];
            break;
        case NowPlayingStateSkipNext:
            [self.musicPlayer skipToNextItem];
            [self pushNowPlayingItemToWatch:YES];
            break;
        case NowPlayingStateSkipPrevious:
            if([self.musicPlayer currentPlaybackTime] < 3) {
                [self.musicPlayer skipToPreviousItem];
                [self pushNowPlayingItemToWatch:YES];
            } else {
                [self.musicPlayer skipToBeginning];
            }
            break;
        case NowPlayingStateVolumeUp:
            [volumeViewSlider setValue:self.musicPlayer.volume + 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            //[self.musicPlayer setVolume:[self.musicPlayer volume] + 0.0625];
            break;
        case NowPlayingStateVolumeDown:
            [volumeViewSlider setValue:self.musicPlayer.volume - 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            //[self.musicPlayer setVolume:[self.musicPlayer volume] - 0.0625];
            break;
    }
    [self performSelector:@selector(pushCurrentStateToWatch:) withObject:self.watch afterDelay:0.1];
}

- (void)sendTestImage {
    UIImage* image = [UIImage imageNamed:@"robot_ios.png"];
    if(!image) {
        NSLog(@"No image!");
        [self sendMessageToPebble:@{IPOD_ALBUM_ART_KEY: [NSNumber numberWithUint8:255]}];
    }
    else {
        NSLog(@"Sending test image...");
        
        YYImageEncoder *pngEncoder = [[YYImageEncoder alloc] initWithType:YYImageTypePNG];
        [pngEncoder addImage:image duration:0];
        NSData *bitmap = [pngEncoder encode];

        UIImage *image = [UIImage imageWithData:bitmap];
        UIImageView *view = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 150, 150)];
        view.userInteractionEnabled = YES;
        [view setImage:image];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendTestImage)];
        [view addGestureRecognizer:recognizer];
        [self.view addSubview:view];
        NSLog(@"Got length %lu", (unsigned long)bitmap.length);
        
        size_t length = [bitmap length];
        NSDictionary *sizeDict = @{IPOD_ALBUM_ART_LENGTH_KEY: [NSNumber numberWithUint16:[bitmap length]]};
        NSLog(@"sizedict %@", sizeDict);
        [self sendMessageToPebble:sizeDict];
        
        uint8_t j = 0;
        for(size_t i = 0; i < length; i += MAX_OUTGOING_SIZE-1) {
            NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
            NSRange rangeOfBytes = NSMakeRange(i, MIN(MAX_OUTGOING_SIZE-1, length - i));
            [outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
            NSDictionary *dict = @{IPOD_ALBUM_ART_KEY: outgoing, IPOD_ALBUM_ART_INDEX_KEY:[NSNumber numberWithUint16:j]};
            NSLog(@"Sending image dict %@", dict);
            [self sendMessageToPebble:dict];
            j++;
        }
    }

}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
    if (self.watch) {
        return;
    }
    self.watch = watch;
    
    self.messageQueue = [[KBPebbleMessageQueue alloc]init];
    self.messageQueue.watch = self.watch;
    
    NSLog(@"Got watch %@", self.watch);
    
    /*
    NSMutableDictionary *outgoing = [NSMutableDictionary new];
    [self.watch appMessagesPushUpdate:outgoing onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (error) {
            NSLog(@"Error sending update: %@", error);
        }
    }];
     */
    
    [self sendTestImage];
    
    
    // Sign up for AppMessage
    __weak typeof(self) welf = self;

    // Register for AppMessage delivery
    [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        __strong typeof(welf) sself = welf;
        if (!sself) {
            // self has been destroyed
            NSLog(@"self is destroyed!");
            return NO;
        }
        if(update[IPOD_NOW_PLAYING_KEY]) {
            NSLog(@"Now playing key sent");
            [self pushNowPlayingItemToWatch:YES];
        }
        else if(update[IPOD_CHANGE_STATE_KEY]) {
            [self changeState:(NowPlayingState)[update[IPOD_CHANGE_STATE_KEY] integerValue]];
        }
        return YES;
    }];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    NSLog(@"Lost watch %@", self.watch);
    if (self.watch == watch) {
        self.watch = nil;
    }
}

- (void)viewDidLayoutSubviews {
    self.songTitleLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songTitleLabel.frame.size withMinimumSize:20];
    
    self.songArtistLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songArtistLabel.frame.size withMinimumSize:16];
    
    self.songAlbumLabel.font = [LMNowPlayingViewController findAdaptiveFontWithName:@"HelveticaNeue-Light" forUILabelSize:self.songAlbumLabel.frame.size withMinimumSize:14];
    
    if(self.loadedSubviews){
        return;
    }
    
    self.view.backgroundColor = [UIColor redColor];
    
    self.songTitleLabel.fadeLength = 10;
    self.songTitleLabel.leadingBuffer = 6;
    self.songArtistLabel.fadeLength = 10;
    self.songArtistLabel.leadingBuffer = 6;
    self.songAlbumLabel.fadeLength = 10;
    self.songAlbumLabel.leadingBuffer = 6;
    
    self.songDurationSlider.tintColor = [UIColor redColor];
    [self.songDurationSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self.songDurationSlider addTarget:self action:@selector(fireRefreshTimer) forControlEvents:UIControlEventTouchDragExit];
    
    [self.albumArtView setupWithAlbumImage:[UIImage imageNamed:@"no_album.png"]];
    
    [self.shuffleButton setupWithTitle:@"Shuffle" withImage:[UIImage imageNamed:@"shuffle_black.png"]];
    self.shuffleButton.delegate = self;
    [self.repeatButton setupWithTitle:@"Repeat" withImage:[UIImage imageNamed:@"repeat_black.png"]];
    self.repeatButton.delegate = self;
    [self.dynamicPlaylistButton setupWithTitle:@"Playlist" withImage:[UIImage imageNamed:@"dynamic_playlist.png"]];
    
    self.shadingView = [[UIView alloc]init];
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
    
    [self.backgroundImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.backgroundImageView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0]];
    
    [self.backgroundImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.backgroundImageView
                                                                         attribute:NSLayoutAttributeBottom
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
    
    self.shuffleMode = self.musicPlayer.shuffleMode;
    self.repeatMode = self.musicPlayer.repeatMode;
    [self reloadButtonTitles];
        
    UITapGestureRecognizer *screenTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playPauseMusic)];
    [self.contentContainerView addGestureRecognizer:screenTapRecognizer];
    
    UISwipeGestureRecognizer *nextRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(nextSong:)];
    [nextRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.contentContainerView addGestureRecognizer:nextRecognizer];
    
    UISwipeGestureRecognizer *previousRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(previousSong:)];
    [previousRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.contentContainerView addGestureRecognizer:previousRecognizer];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];    panRecognizer.delegate = self;
    [self.contentContainerView addGestureRecognizer:panRecognizer];
    
    self.loadedSubviews = YES;
    
   // NSLog(@"Sending test image...");
   // [self sendTestImage];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"set");
    
    // Set the delegate to receive PebbleKit events
    self.central = [PBPebbleCentral defaultCentral];
    self.central.delegate = self;
    
    [self.central setAppUUID:[[NSUUID alloc] initWithUUIDString:@"4e601687-8739-49e0-a280-1a633ee46eef"]];
    
    // Begin connection
    [self.central run];
    
    /*
    //Make sure that we can actually read the volume
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
     */
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
