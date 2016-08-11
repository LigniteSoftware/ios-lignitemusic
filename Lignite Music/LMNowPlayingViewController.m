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
#import "LMPebbleSettingsView.h"
#import "LMNowPlayingViewController.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "LMPebbleImage.h"
#import "LMPebbleMessageQueue.h"

@interface LMNowPlayingViewController () <LMButtonDelegate, UIGestureRecognizerDelegate, PBPebbleCentralDelegate>

/*
typedef enum {
    MessageKeyReconnect = 0,
    MessageKeyRequestLibrary,
    MessageKeyRequestOffset,
    MessageKeyLibraryResponse,
    MessageKeyNowPlaying,
    MessageKeyRequestParent,
    MessageKeyPlayTrack,
    MessageKeyNowPlayingResponseType,
    MessageKeyAlbumArt,
    MessageKeyAlbumArtLength,
    MessageKeyAlbumArtIndex,
    MessageKeyChangeState,
    MessageKeyCurrentState,
    MessageKeySequenceNumber
} MessageKey;
 */

#define MessageKeyReconnect @(0)
#define MessageKeyRequestLibrary @(1)
#define MessageKeyRequestOffset @(2)
#define MessageKeyLibraryResponse @(3)
#define MessageKeyNowPlaying @(4)
#define MessageKeyRequestParent @(5)
#define MessageKeyPlayTrack @(6)
#define MessageKeyNowPlayingResponseType @(7)
#define MessageKeyAlbumArt @(8)
#define MessageKeyAlbumArtLength @(9)
#define MessageKeyAlbumArtIndex @(10)
#define MessageKeyChangeState @(11)
#define MessageKeyCurrentState @(12)
#define MessageKeySequenceNumber @(13)

#define MAX_LABEL_LENGTH 20
#define MAX_RESPONSE_COUNT 90
#define MAX_OUTGOING_SIZE 1500 // This allows some overhead.

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

@property UIImage *lastAlbumArtImage;

@property LMPebbleMessageQueue *messageQueue;

@property MPMediaItemCollection *currentlyPlayingQueue;

@property BOOL overrideImageLogic;

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
    //NSLog(@"translated %@", NSStringFromCGPoint(translatedPoint));
    
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
    
    NSLog(@"Now playing item has changed");
    
    [self pushNowPlayingItemToWatch];
    
    if(!self.musicPlayer.nowPlayingItem){
        [self.songTitleLabel setText:@"No Music"];
        [self.songArtistLabel setText:@"Start music on your watch or phone"];
        [self.songAlbumLabel setText:@""];
        [self.songDurationLabel setText:@"--:--"];
        [self.songNumberLabel setText:@"No music"];
        
        UIImage *albumImage;
        albumImage = [UIImage imageNamed:@"lignite_background_portrait.png"];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundImageView.image = albumImage;
        
        [self.albumArtView updateContentWithMusicPlayer:self.musicPlayer];
        return;
    }
    
    [self.songTitleLabel setText:self.musicPlayer.nowPlayingItem.title];
    [self.songArtistLabel setText:self.musicPlayer.nowPlayingItem.artist];
    [self.songAlbumLabel setText:self.musicPlayer.nowPlayingItem.albumTitle];
    
    if(self.currentlyPlayingQueue){
        [self.songNumberLabel setText:[NSString stringWithFormat:@"Song %lu of %lu", self.musicPlayer.indexOfNowPlayingItem+1, self.currentlyPlayingQueue.items.count]];
    }
    else{
        [self.songNumberLabel setText:[NSString stringWithFormat:@"Song %lu", self.musicPlayer.indexOfNowPlayingItem+1]];
    }
    
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
    
    NSLog(@"Playback state is %d", (int)playbackState);
    
    if (playbackState == MPMusicPlaybackStatePaused || playbackState == MPMusicPlaybackStatePlaying) {
        //[self.playingView.controlView setPlaying:nil];
    }
    else if (playbackState == MPMusicPlaybackStateStopped) {
        //[self.musicPlayer stop];
    }
    [self pushCurrentStateToWatch];
}

- (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime {
    long totalHours = (totalPlaybackTime / 3600);
    int totalMinutes = (int)((totalPlaybackTime / 60) - totalHours*60);
    int totalSeconds = (totalPlaybackTime % 60);
    
    if(totalHours > 0){
        return [NSString stringWithFormat:@"%02i:%02d:%02d", (int)totalHours, totalMinutes, totalSeconds];
    }
    
    return [NSString stringWithFormat:@"%02d:%02d", totalMinutes, totalSeconds];
}

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
    long totalPlaybackTime = [[self.musicPlayer nowPlayingItem] playbackDuration];
    
    long currentHours = (currentPlaybackTime / 3600);
    long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
    int currentSeconds = (currentPlaybackTime % 60);
    
    long totalHours = (totalPlaybackTime / 3600);
    
    [UIView animateWithDuration:0.3 animations:^{
        if(totalHours > 0){
            self.songDurationLabel.text = [NSString stringWithFormat:@"%02i:%02d:%02d of %@",
                                           (int)currentHours, (int)currentMinutes, currentSeconds,
                                           [self durationStringTotalPlaybackTime:totalPlaybackTime]];
        }
        else{
            self.songDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d of %@",
                                           (int)currentMinutes, currentSeconds,
                                           [self durationStringTotalPlaybackTime:totalPlaybackTime]];
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
        [self pushCurrentStateToWatch];
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
    [self pushCurrentStateToWatch];
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
    else if(button == self.dynamicPlaylistButton){
        //LMPebbleSettingsView *settingsView = [[LMPebbleSettingsView alloc]initWithStyle:UITableViewStyleGrouped];
        if(self.watch){
            UINavigationController *settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"AllahuAkbar"];
            LMPebbleSettingsView *rootSettingsViewController = [settingsController.viewControllers firstObject];
            NSLog(@"count %ld", [settingsController.viewControllers count]);
            rootSettingsViewController.messageQueue = self.messageQueue;
            [self showDetailViewController:settingsController sender:self];
        }
        else{
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"No Pebble Connected"
                                         message:@"Settings are currently only for Pebble. Please connect a Pebble and try again."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Retry"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self clickedButton:self.dynamicPlaylistButton];
                                        }];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"Close"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action) {
                                           
                                       }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
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

- (void)pushNowPlayingItemToWatch {
    MPMediaItem *item = [self.musicPlayer nowPlayingItem];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    if(!title) title = @"";
    if(!artist) artist = @"";
    if(!album) album = @"";
    
    NSLog(@"Pushing now playing details to watch.");
    NSDictionary *titleDict = @{MessageKeyNowPlaying: title, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingTitle]};
    [self sendMessageToPebble:titleDict];
    
    NSDictionary *artistDict = @{MessageKeyNowPlaying: artist, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingArtist]};
    [self sendMessageToPebble:artistDict];
    
    NSDictionary *albumDict = @{MessageKeyNowPlaying: album, MessageKeyNowPlayingResponseType:[NSNumber numberWithUint8:NowPlayingAlbum]};
    [self sendMessageToPebble:albumDict];
    
    [self pushCurrentStateToWatch];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(sendAlbumArtImage)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)sendCurrentStateToWatch {
    //NSLog(@"Hi");
    uint16_t current_time = (uint16_t)[self.musicPlayer currentPlaybackTime];
    uint16_t total_time = (uint16_t)[[[self.musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    uint8_t metadata[] = {
        [self.musicPlayer playbackState],
        [self.musicPlayer shuffleMode],
        [self.musicPlayer repeatMode],
        total_time >> 8, total_time & 0xFF,
        current_time >> 8, current_time & 0xFF
    };
    //NSLog(@"Current state: %@", [NSData dataWithBytes:metadata length:7]);
    [self sendMessageToPebble:@{MessageKeyCurrentState: [NSData dataWithBytes:metadata length:7]}];

}

- (void)pushCurrentStateToWatch {
    [self performSelector:@selector(sendCurrentStateToWatch) withObject:nil afterDelay:0.1];
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
            [self playPauseMusic];
            break;
        case NowPlayingStateSkipNext:
            [self.musicPlayer skipToNextItem];
            break;
        case NowPlayingStateSkipPrevious:
            if([self.musicPlayer currentPlaybackTime] < 3) {
                [self.musicPlayer skipToPreviousItem];
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
    [self pushCurrentStateToWatch];
}

- (void)sendAlbumArtImage {
    CGSize imageSize = CGSizeMake(144, 144);
    UIImage *albumArtImage = [[self.musicPlayer.nowPlayingItem artwork]imageWithSize:imageSize];
    UIImage *image = [LMPebbleImage ditherImageForPebble:albumArtImage withColourPalette:YES withSize:imageSize];
    
    if([albumArtImage isEqual:self.lastAlbumArtImage] && !self.overrideImageLogic){
        NSLog(@"The album art is literally samezies...");
        return;
    }
    self.lastAlbumArtImage = albumArtImage;
    self.overrideImageLogic = NO;

    if(!albumArtImage) {
        NSLog(@"No image!");
        [self sendMessageToPebble:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint8:1]}];
    }
    else {
        YYImageEncoder *pngEncoder = [[YYImageEncoder alloc] initWithType:YYImageTypePNG];
        [pngEncoder addImage:image duration:0];
        NSData *bitmap = [pngEncoder encode];
        
        size_t length = [bitmap length];
        NSDictionary *sizeDict = @{MessageKeyAlbumArtLength: [NSNumber numberWithUint16:[bitmap length]]};
        NSLog(@"Album art size message: %@", sizeDict);
        [self sendMessageToPebble:sizeDict];
        
        uint8_t j = 0;
        for(size_t i = 0; i < length; i += MAX_OUTGOING_SIZE-1) {
            NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
            
            NSRange rangeOfBytes = NSMakeRange(i, MIN(MAX_OUTGOING_SIZE-1, length - i));
            [outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
            
            NSDictionary *dict = @{MessageKeyAlbumArt: outgoing, MessageKeyAlbumArtIndex:[NSNumber numberWithUint16:j]};
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
    
    NSLog(@"Got watch %@", self.watch);
    
    self.messageQueue.watch = self.watch;
    
    [self.watch appMessagesPushUpdate:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint8:1]} onSent:^(PBWatch * _Nonnull watch, NSDictionary * _Nonnull update, NSError * _Nullable error) {
        if(error){
            NSLog(@"Error sending to watch %@", error);
        }
        else{
            NSLog(@"Communications with watch opened.");
        }
    }];
    
    __weak typeof(self) welf = self;

    [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        __strong typeof(welf) sself = welf;
        if (!sself) {
            NSLog(@"self is destroyed!");
            return NO;
        }
        if(update[MessageKeyPlayTrack]) {
            NSLog(@"Will play track from message %@", update);
            [self playTrackFromMessage:update];
        }
        else if(update[MessageKeyRequestLibrary]) {
            if(update[MessageKeyRequestParent]) {
                [self sublistRequest:update];
            } else {
                [self libraryDataRequest:update];
            }
        }
        else if(update[MessageKeyNowPlaying]) {
            NSLog(@"Now playing key sent");
            self.overrideImageLogic = [update[MessageKeyNowPlaying] isEqual:@(100)];
            NSLog(@"Override: %d to %@", self.overrideImageLogic, update[MessageKeyNowPlaying]);
            [self pushNowPlayingItemToWatch];
        }
        else if(update[MessageKeyChangeState]) {
            [self changeState:(NowPlayingState)[update[MessageKeyChangeState] integerValue]];
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

- (void)playTrackFromMessage:(NSDictionary *)message {
    MPMediaItemCollection *queue = [self getCollectionFromMessage:message][0];
    MPMediaItem *track = [queue items][[message[MessageKeyPlayTrack] int16Value]];
    NSLog(@"Got index %d", [message[MessageKeyPlayTrack] int16Value]);
    for(int i = 0; i < [[queue items] count]; i++){
        NSLog(@"Got item %@: %d", [[[queue items] objectAtIndex:i]valueForProperty:MPMediaItemPropertyTitle], i);
    }
    NSLog(@"track %@", [track valueForProperty:MPMediaItemPropertyTitle]);
    [self.musicPlayer stop];
    self.currentlyPlayingQueue = queue;
    [self.musicPlayer setQueueWithItemCollection:queue];
    [self.musicPlayer setNowPlayingItem:track];
    [self.musicPlayer play];
    //[self.musicPlayer setCurrentPlaybackTime:0];
    NSLog(@"Now playing %@", [self.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyTitle]);
    //NSLog(@"Index in queue %ld", [self.musicPlayer indexOfNowPlayingItem]);
    //[self.musicPlayer play];
    //[self pushNowPlayingItemToWatch:watch detailed:YES];
    
}

- (void)libraryDataRequest:(NSDictionary *)request {
    NSUInteger request_type = [request[MessageKeyRequestLibrary] unsignedIntegerValue];
    NSUInteger offset = [request[MessageKeyRequestOffset] integerValue];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query setGroupingType:request_type];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
    NSArray* results = [query collections];
    [self pushLibraryResults:results withOffset:offset type:request_type isSubtitle:0];
}

- (void)sublistRequest:(NSDictionary*)request {
    NSArray *results = [self getCollectionFromMessage:request];
    MPMediaGrouping request_type = [request[MessageKeyRequestLibrary] integerValue];
    uint16_t offset = [request[MessageKeyRequestOffset] uint16Value];
    if(request_type == MPMediaGroupingTitle) {
        results = [results[0] items];
    }
    [self pushLibraryResults:results withOffset:offset type:request_type isSubtitle:0];
}

- (NSArray*)getCollectionFromMessage:(NSDictionary*)request {
    // Find what we're subsetting by iteratively grabbing the sets.
    MPMediaItemCollection *collection = nil;
    MPMediaGrouping parent_type;
    uint16_t parent_index;
    NSString *persistent_id;
    NSString *id_prop;
    NSData *data = request[MessageKeyRequestParent];
    uint8_t *bytes = (uint8_t*)[data bytes];
    for(uint8_t i = 0; i < bytes[0]; ++i) {
        parent_type = bytes[i*3+1];
        parent_index = *(uint16_t*)&bytes[i*3+2];
        NSLog(@"Parent type: %ld", (long)parent_type);
        NSLog(@"Parent index: %d", parent_index);
        NSLog(@"i: %d", i);
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query setGroupingType:parent_type];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
        if(collection) {
            [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistent_id forProperty:id_prop]];
        }
        if(parent_index >= [[query collections] count]) {
            NSLog(@"Out of bounds: %d", parent_index);
            return nil;
        }
        collection = [query collections][parent_index];
        id_prop = [MPMediaItem persistentIDPropertyForGroupingType:parent_type];
        persistent_id = [[collection representativeItem] valueForProperty:id_prop];
    }
    
    // Complete the lookup
    NSUInteger request_type = [request[MessageKeyRequestLibrary] unsignedIntegerValue];
    if(request_type == MPMediaGroupingTitle) {
        return @[collection];
    } else {
        NSLog(@"Got persistent ID: %@", persistent_id);
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query setGroupingType:request_type];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistent_id forProperty:id_prop]];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType]];
        return [query collections];
    }
}

- (void)pushLibraryResults:(NSArray *)results withOffset:(NSInteger)offset type:(MPMediaGrouping)type isSubtitle:(uint8_t)subtitleType {
    switch(subtitleType){
        case 1: //Album artist
            break;
        case 2: //Track subtitle
        case 3: //Playlist subtitle
            type = MPMediaGroupingPodcastTitle;
            break;
    }
    
    NSArray* subset;
    if(offset < [results count]) {
        NSInteger count = MAX_RESPONSE_COUNT;
        if([results count] <= offset + MAX_RESPONSE_COUNT) {
            count = [results count] - offset;
        }
        subset = [results subarrayWithRange:NSMakeRange(offset, count)];
    }
    NSMutableData *result = [[NSMutableData alloc] init];
    // Response format: header of one byte containing library data type, two bytes containing
    // the total number of results, and two bytes containing our current offset. Little endian.
    // This is followed by a sequence of entries, which consist of one length byte followed by UTF-8 data
    // (pascal style)
    uint8_t type_byte = (uint8_t)type;
    uint16_t metabytes[] = {[results count], offset};
    // Include the type of library
    [result appendBytes:&type_byte length:1];
    [result appendBytes:metabytes length:4];
    int i = 0;
    for (MPMediaItemCollection* item in subset) {
        NSString *value;
        if(type == MPMediaGroupingPodcastTitle && subtitleType == 3){
            value = [NSString stringWithFormat:@"%lu songs", (unsigned long)item.count];
        }
        else if([item isKindOfClass:[MPMediaPlaylist class]]) {
            value = [item valueForProperty:MPMediaPlaylistPropertyName];
        }
        //If this happens, it's tracks asking for its artist and duration.
        else if(type == MPMediaGroupingPodcastTitle && subtitleType == 2){
            NSNumber *trackLength = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
            NSString *artistName = [item valueForProperty:MPMediaItemPropertyArtist];
            
            if(artistName){
                value = [NSString stringWithFormat:@"%@ | %@",
                         [self durationStringTotalPlaybackTime:[trackLength longValue]],
                         artistName];
            }
            else{
                value = [NSString stringWithFormat:@"%@",
                         [self durationStringTotalPlaybackTime:[trackLength longValue]]];
            }
        }
        else if(type == MPMediaGroupingAlbumArtist){
            value = [[item representativeItem] valueForProperty:MPMediaItemPropertyArtist];
        }
        else {
            value = [[item representativeItem] valueForProperty:[MPMediaItem titlePropertyForGroupingType:type]];
        }
        if([value length] > MAX_LABEL_LENGTH) {
            value = [value substringToIndex:MAX_LABEL_LENGTH];
        }
        NSData *value_data = [value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        uint8_t length = [value_data length];
        if(([result length] + length) > MAX_OUTGOING_SIZE){
            NSLog(@"Cutting off length at %ld", [result length]);
            break;
        }
        [result appendBytes:&length length:1];
        [result appendData:value_data];
        NSLog(@"Value for %d: %@", i, value);
        i++;
    }
    [self.messageQueue enqueue:@{MessageKeyLibraryResponse: result}];

    if(type == MPMediaGroupingAlbum){
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingAlbumArtist isSubtitle:1];
    }
    else if(type == MPMediaGroupingTitle){
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingPodcastTitle isSubtitle:2];
    }
    else if(type == MPMediaGroupingPlaylist){
        NSLog(@"Pushing playlist subtitles");
        [self pushLibraryResults:results withOffset:offset type:MPMediaGroupingPodcastTitle isSubtitle:3];
    }
    
    NSLog(@"Sent message: %@ with length %lu", result, (unsigned long)[result length]);
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
    [self.dynamicPlaylistButton setupWithTitle:@"Settings" withImage:[UIImage imageNamed:@"settings.png"]];
    self.dynamicPlaylistButton.delegate = self;
    
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
    
    if(!self.musicPlayer){
        self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    }
    
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
    [panRecognizer setMaximumNumberOfTouches:1];
    panRecognizer.delegate = self;
    //[self.contentContainerView addGestureRecognizer:panRecognizer];
    
    self.loadedSubviews = YES;
    
    //NSLog(@"Starting test image...");
    //[self sendTestImage];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"pebble_coldstart"]){
        [self.central run];
    }
    else{
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Pebble Connection"
                                     message:@"iOS is about to ask for your permission to use Bluetooth devices. Please allow the permission as we use it to communicate with Lignite Music watchapps."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Okay"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [self.central run];
                                        [defaults setBool:YES forKey:@"pebble_coldstart"];
                                    }];
        
        [alert addAction:yesButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.central = [PBPebbleCentral defaultCentral];
    self.central.delegate = self;
    
    // UUID of watchapp starter project: af17efe7-2141-4eb2-b62a-19fc1b595595
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
    //[self.central run];
    
    
    self.messageQueue = [[LMPebbleMessageQueue alloc]init];
    
    self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
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
    
    [self nowPlayingItemChanged:self];
    
    NSLog(@"View did load");
}

- (void)viewDidUnload:(BOOL)animated {
    NSLog(@"View did unload");
    
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
