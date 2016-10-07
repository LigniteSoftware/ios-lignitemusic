//
//  TestViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <PebbleKit/PebbleKit.h>
#import <YYImage/YYImage.h>
#import "LMPebbleSettingsView.h"
#import "LMNowPlayingViewController.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "LMPebbleImage.h"
#import "LMPebbleMessageQueue.h"

@interface LMNowPlayingViewController () <LMButtonDelegate, UIGestureRecognizerDelegate, PBPebbleCentralDelegate>

@property NSTimer *refreshTimer;
@property UIView *shadingView;
@property BOOL finishedUserAdjustment;
@property BOOL loadedSubviews;

@property MPMusicShuffleMode shuffleMode;
@property MPMusicRepeatMode repeatMode;

@property int firstX, firstY;

@property (weak, nonatomic) PBWatch *watch;
@property (weak, nonatomic) PBPebbleCentral *central;

@property MPMediaEntityPersistentID lastAlbumArtImage;

@property LMPebbleMessageQueue *messageQueue;

@property MPMediaItemCollection *currentlyPlayingQueue;

@property WatchInfoModel watchModel;

@property NowPlayingRequestType requestType;

@property uint8_t imageParts;

@property int appMessageSize;

@property BOOL firstPebbleAppOpen;

@property LMPebbleSettingsView *rootSettingsViewController;

@property MPVolumeView *volumeView;
@property UISlider *volumeViewSlider;

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
				[self dismissViewControllerAnimated:YES completion:nil];
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


- (void)nowPlayingItemChanged:(id)sender {
    //[self.playingView updateNowPlayingItem:self.musicPlayer.nowPlayingItem];
    
    NSLog(@"Now playing item has changed");
	
	self.requestType = NowPlayingRequestTypeAllData;
    [self pushNowPlayingItemToWatch];
    
    if(!self.musicPlayer.nowPlayingItem){
        [self.songTitleLabel setText:NSLocalizedString(@"NoMusic", nil)];
        [self.songArtistLabel setText:NSLocalizedString(@"NoMusicDescription", nil)];
        [self.songAlbumLabel setText:@""];
		[self.songDurationLabel setText:NSLocalizedString(@"BlankDuration", nil)];
        [self.songNumberLabel setText:NSLocalizedString(@"NoMusic", nil)];
        
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
        [self.songNumberLabel setText:[NSString stringWithFormat:NSLocalizedString(@"SongXofX", nil), (int)self.musicPlayer.indexOfNowPlayingItem+1, (int)self.currentlyPlayingQueue.items.count]];
    }
    else{
        [self.songNumberLabel setText:[NSString stringWithFormat:NSLocalizedString(@"SongX", nil), (int)self.musicPlayer.indexOfNowPlayingItem+1]];
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
//        self.shuffleButton.titleLabel.textColor = newTextColour;
//        self.repeatButton.titleLabel.textColor = newTextColour;
//        self.dynamicPlaylistButton.titleLabel.textColor = newTextColour;
		
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

+ (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime {
    long totalHours = (totalPlaybackTime / 3600);
    int totalMinutes = (int)((totalPlaybackTime / 60) - totalHours*60);
    int totalSeconds = (totalPlaybackTime % 60);
    
    if(totalHours > 0){
        return [NSString stringWithFormat:NSLocalizedString(@"LongSongDuration", nil), (int)totalHours, totalMinutes, totalSeconds];
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"ShortSongDuration", nil), totalMinutes, totalSeconds];
}

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
    long totalPlaybackTime = [[self.musicPlayer nowPlayingItem] playbackDuration];
    
    long currentHours = (currentPlaybackTime / 3600);
    long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
    int currentSeconds = (currentPlaybackTime % 60);
    
    long totalHours = (totalPlaybackTime / 3600);
    
    [UIView animateWithDuration:0.3 animations:^{
        if(totalHours > 0){
            self.songDurationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LongSongDurationOfDuration", nil),
                                           (int)currentHours, (int)currentMinutes, currentSeconds,
                                           [LMNowPlayingViewController durationStringTotalPlaybackTime:totalPlaybackTime]];
        }
        else{
            self.songDurationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ShortSongDurationOfDuration", nil),
                                           (int)currentMinutes, currentSeconds,
                                           [LMNowPlayingViewController durationStringTotalPlaybackTime:totalPlaybackTime]];
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
    if(self.musicPlayer.playbackState != MPMusicPlaybackStatePlaying){
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
        @"DefaultShuffleMode", @"OffShuffleMode", @"SongsShuffleMode", @"AlbumsShuffleMode"
    };
    NSString *repeatArray[] = {
        @"DefaultRepeatMode", @"OffRepeatMode", @"ThisRepeatMode", @"AllRepeatMode"
    };
//    [self.shuffleButton setTitle:NSLocalizedString(shuffleArray[self.musicPlayer.shuffleMode], nil)];
//    [self.repeatButton setTitle:NSLocalizedString(repeatArray[self.musicPlayer.repeatMode], nil)];
}

/*
 Sets the shuffle or repeat status of the music. See MPMusicShuffleMode and MPMusicRepeatMode.
 */
- (void)clickedButton:(LMButton *)button {
    if(button == self.shuffleButton){
        self.shuffleMode++;
        if(self.shuffleMode > MPMusicShuffleModeAlbums){
            self.shuffleMode = 1;
        }
        [self.musicPlayer setShuffleMode:self.shuffleMode];
    }
    else if(button == self.dynamicPlaylistButton){
        //LMPebbleSettingsView *settingsView = [[LMPebbleSettingsView alloc]initWithStyle:UITableViewStyleGrouped];
		UINavigationController *settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"AllahuAkbar"];
		self.rootSettingsViewController = [settingsController.viewControllers firstObject];
		self.rootSettingsViewController.messageQueue = self.messageQueue;
		[self showDetailViewController:settingsController sender:self];
	}
    else{
        self.repeatMode++;
        if(self.repeatMode > MPMusicRepeatModeAll){
            self.repeatMode = 1;
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
    if(!self.watch){
        return;
    }
    
    if(self.watchModel == WATCH_INFO_MODEL_UNKNOWN || self.watchModel == WATCH_INFO_MODEL_MAX){
        self.watchModel = WATCH_INFO_MODEL_PEBBLE_ORIGINAL;
    }
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
	
    [NSTimer scheduledTimerWithTimeInterval:0.25
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

- (void)handleVolumeChanged:(id)sender{
	NSLog(@"%s - %f", __PRETTY_FUNCTION__, self.volumeViewSlider.value);
}

- (void)changeState:(NowPlayingState)state {
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
			/*
            [volumeViewSlider setValue:self.musicPlayer.volume + 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			 */
			[self.volumeViewSlider setValue:self.volumeViewSlider.value + 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            //[self.musicPlayer setVolume:[self.musicPlayer volume] + 0.0625];
            break;
        case NowPlayingStateVolumeDown:
			[self.volumeViewSlider setValue:self.volumeViewSlider.value - 0.0625 animated:YES];
			[self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			/*
            [volumeViewSlider setValue:self.musicPlayer.volume - 0.0625 animated:YES];
            [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
			 */
            //[self.musicPlayer setVolume:[self.musicPlayer volume] - 0.0625];
            break;
    }
    [self pushCurrentStateToWatch];
}

- (BOOL)watchIsRoundScreen {
    switch(self.watchModel){
        case WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_14:
        case WATCH_INFO_MODEL_PEBBLE_TIME_ROUND_20:
            return true;
        default:
            return false;
    }
}

- (BOOL)watchIsBlackAndWhite {
    switch(self.watchModel){
        case WATCH_INFO_MODEL_PEBBLE_ORIGINAL:
        case WATCH_INFO_MODEL_PEBBLE_STEEL:
            return true;
        default:
            return false;
    }
}

- (CGSize)albumArtSize {
    if([self watchIsRoundScreen]){
        return CGSizeMake(180, 180);
    }
    return CGSizeMake(144, 144);
}

- (void)sendAlbumArtImage {
    if(self.imageParts == 0){
        NSLog(@"Setting to 1");
        self.imageParts = 1;
    }
    
    CGSize imageSize = [self albumArtSize];
	MPMediaItemArtwork *currentArtwork = [self.musicPlayer.nowPlayingItem artwork];
    UIImage *albumArtImage = [currentArtwork imageWithSize:imageSize];
	
	//NSLog(@"%d, %d, %d", self.musicPlayer.nowPlayingItem.albumPersistentID == self.lastAlbumArtImage, self.requestType, self.firstPebbleAppOpen);
	
	if(self.musicPlayer.nowPlayingItem.albumPersistentID == self.lastAlbumArtImage && self.requestType != NowPlayingRequestTypeOnlyTrackInfo && !self.firstPebbleAppOpen){
        NSLog(@"The album art is literally samezies...");
        return;
    }
	else if(self.requestType == NowPlayingRequestTypeOnlyTrackInfo){
		NSLog(@"Only track info, rejecting");
		return;
	}
    self.lastAlbumArtImage = self.musicPlayer.nowPlayingItem.albumPersistentID;
    self.requestType = NowPlayingRequestTypeOnlyTrackInfo;
	self.firstPebbleAppOpen = NO;
    
    for(uint8_t index = 0; index < self.imageParts; index++){
        
        NSString *imageString = [LMPebbleImage ditherImage:albumArtImage
                                           withSize:imageSize
                                      forTotalParts:self.imageParts
                                    withCurrentPart:index
                                    isBlackAndWhite:[self watchIsBlackAndWhite]
                                       isRoundWatch:[self watchIsRoundScreen]];
        
        if(self.watch){
            if(!albumArtImage) {
                NSLog(@"No image!");
                [self sendMessageToPebble:@{MessageKeyAlbumArtLength:[NSNumber numberWithUint16:1], MessageKeyImagePart:[NSNumber numberWithUint8:index]}];
            }
            else {
                NSData *bitmap = [NSData dataWithContentsOfFile:imageString];
                NSLog(@"Got data file %@ with bitmap length %lu", imageString, (unsigned long)[bitmap length]);
                
                size_t length = [bitmap length];
                
                NSDictionary *sizeDict = @{MessageKeyAlbumArtLength: [NSNumber numberWithUint16:length], MessageKeyImagePart:[NSNumber numberWithUint8:index]};
                NSLog(@"Album art size message: %@", sizeDict);
                
                [self sendMessageToPebble:sizeDict];
                
                uint8_t j = 0;
                for(size_t i = 0; i < length; i += self.appMessageSize-1) {
                    NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:self.appMessageSize];
                    
                    NSRange rangeOfBytes = NSMakeRange(i, MIN(self.appMessageSize-1, length - i));
                    [outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
                    
                    NSDictionary *dict = @{MessageKeyAlbumArt: outgoing, MessageKeyAlbumArtIndex:[NSNumber numberWithUint16:j], MessageKeyImagePart:[NSNumber numberWithUint8:index]};
                    NSLog(@"Sending index %d", j);
                    [self sendMessageToPebble:dict];
                    j++;
                }
            }
        }
    }
}

- (void)sendHeaderIconImage:(UIImage*)albumArtImage {
    NSLog(@"sending image %@", albumArtImage);
    CGSize imageSize = CGSizeMake(36, 36);

    NSString *imageString = [LMPebbleImage ditherImage:albumArtImage
                                              withSize:imageSize
                                         forTotalParts:1
                                       withCurrentPart:0
                                       isBlackAndWhite:[self watchIsBlackAndWhite]
                                          isRoundWatch:NO];
    
    if(!albumArtImage) {
        NSLog(@"No image!");
        [self sendMessageToPebble:@{MessageKeyHeaderIconLength:[NSNumber numberWithUint8:1]}];
    }
    else {
        NSData *bitmap = [NSData dataWithContentsOfFile:imageString];
        
        size_t length = [bitmap length];
        NSDictionary *sizeDict = @{MessageKeyHeaderIconLength: [NSNumber numberWithUint16:[bitmap length]]};
        NSLog(@"Album art size message: %@", sizeDict);
        [self sendMessageToPebble:sizeDict];
        
        uint8_t j = 0;
        for(size_t i = 0; i < length; i += self.appMessageSize-1) {
            NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:self.appMessageSize];
            
            NSRange rangeOfBytes = NSMakeRange(i, MIN(self.appMessageSize-1, length - i));
            [outgoing appendBytes:[[bitmap subdataWithRange:rangeOfBytes] bytes] length:rangeOfBytes.length];
            
            NSDictionary *dict = @{MessageKeyHeaderIcon: outgoing, MessageKeyHeaderIconIndex:[NSNumber numberWithUint16:j]};
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
            [self playTrackFromMessage:update withTrackPlayMode:[update[MessageKeyTrackPlayMode] uint8Value]];
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
            self.requestType = [update[MessageKeyNowPlaying] uint8Value];
            self.watchModel = [update[MessageKeyWatchModel] uint8Value];
            self.imageParts = [update[MessageKeyImagePart] uint8Value];
            self.appMessageSize = [update[MessageKeyAppMessageSize] uint16Value];
			if(update[MessageKeyFirstOpen]){
				NSLog(@"\nIs first app open!\n");
				self.firstPebbleAppOpen = YES;
			}
            NSLog(@"Got request type %d, watch model %d, message size %d and image parts: %d", self.requestType, self.watchModel, self.appMessageSize, self.imageParts);
            
            [self pushNowPlayingItemToWatch];
        }
        else if(update[MessageKeyChangeState]) {
            [self changeState:(NowPlayingState)[update[MessageKeyChangeState] integerValue]];
        }
		else if(update[MessageKeyConnectionTest]){
			[self.messageQueue enqueue:@{ MessageKeyConnectionTest:[NSNumber numberWithInt8:1] }];
		}
        return YES;
    }];
	
	if(self.rootSettingsViewController){
		self.rootSettingsViewController.messageQueue = self.messageQueue;
		[self.rootSettingsViewController.tableView reloadData];
	}
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    NSLog(@"Lost watch %@", self.watch);
    if (self.watch == watch) {
        self.watch = nil;
    }
	
	if(self.rootSettingsViewController){
		self.rootSettingsViewController.messageQueue = nil;
		[self.rootSettingsViewController.tableView reloadData];
	}
}

- (void)playTrackFromMessage:(NSDictionary *)message withTrackPlayMode:(TrackPlayMode)trackPlayMode {
    MPMediaItemCollection *queue = [self getCollectionFromMessage:message][0];
	MPMediaItem *track = [queue items][[[message[MessageKeyPlayTrack] int16Value] < 0 ? 0 : message[MessageKeyPlayTrack] int16Value]];
    NSLog(@"Got index %d", [message[MessageKeyPlayTrack] int16Value]);
    for(int i = 0; i < [[queue items] count]; i++){
        NSLog(@"Got item %@: %d", [[[queue items] objectAtIndex:i]valueForProperty:MPMediaItemPropertyTitle], i);
    }
    NSLog(@"track %@", [track valueForProperty:MPMediaItemPropertyTitle]);
    [self.musicPlayer stop];
    self.currentlyPlayingQueue = queue;
    [self.musicPlayer setQueueWithItemCollection:queue];
    if(trackPlayMode == TrackPlayModeShuffleAll){
        self.musicPlayer.shuffleMode = MPMusicShuffleModeSongs;
    }
    else{
		self.musicPlayer.shuffleMode = MPMusicShuffleModeOff;
		
		MPMusicRepeatMode newRepeatMode = (trackPlayMode-TrackPlayModeRepeatModeNone)+1;
		if(newRepeatMode == MPMusicRepeatModeNone){
			self.musicPlayer.repeatMode = MPMusicRepeatModeNone;
			[self.musicPlayer setNowPlayingItem:track];
		}
		else{
			[self.musicPlayer setNowPlayingItem:track];
			self.musicPlayer.repeatMode = newRepeatMode;
		}
		self.repeatMode = self.musicPlayer.repeatMode;
		
        NSLog(@"Setting repeat mdoe as %ld", (long)self.musicPlayer.repeatMode);
    }
    [self.musicPlayer play];
	if(![self.refreshTimer isValid]){
		[self fireRefreshTimer];
	}
    //[self.musicPlayer setCurrentPlaybackTime:0];
    NSLog(@"Now playing %@", [self.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyTitle]);
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
    MPMediaItem *representativeItem;
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
                         [LMNowPlayingViewController durationStringTotalPlaybackTime:[trackLength longValue]],
                         artistName];
            }
            else{
                value = [NSString stringWithFormat:@"%@",
                         [LMNowPlayingViewController durationStringTotalPlaybackTime:[trackLength longValue]]];
            }
        }
        else if(type == MPMediaGroupingAlbumArtist){
            value = [[item representativeItem] valueForProperty:MPMediaItemPropertyArtist];
        }
        else {
            representativeItem = [item representativeItem];
            value = [[item representativeItem] valueForProperty:[MPMediaItem titlePropertyForGroupingType:type]];
        }
        if([value length] > MAX_LABEL_LENGTH) {
            value = [value substringToIndex:MAX_LABEL_LENGTH];
        }
        NSData *value_data = [value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        uint8_t length = [value_data length];
        if(([result length] + length) > self.appMessageSize){
            NSLog(@"Cutting off length at %lu", (unsigned long)[result length]);
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
        if(![self watchIsBlackAndWhite]){
            [self sendHeaderIconImage:[[representativeItem artwork] imageWithSize:CGSizeMake(36, 36)]];
        }
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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.songTitleLabel.fadeLength = 10;
    self.songTitleLabel.leadingBuffer = 6;
    self.songArtistLabel.fadeLength = 10;
    self.songArtistLabel.leadingBuffer = 6;
    self.songAlbumLabel.fadeLength = 10;
    self.songAlbumLabel.leadingBuffer = 6;
    
    self.songDurationSlider.tintColor = [UIColor redColor];
    [self.songDurationSlider addTarget:self action:@selector(setTimelinePosition:) forControlEvents:UIControlEventValueChanged];
    [self.songDurationSlider addTarget:self action:@selector(fireRefreshTimer) forControlEvents:UIControlEventTouchDragExit];
	
	NSLog(@"Cluck");
    [self.albumArtView setupWithAlbumImage:[UIImage imageNamed:@"no_album.png"]];
	
//	[self.shuffleButton setupWithImageMultiplier:0.5];
//	[self.shuffleButton setTitle:NSLocalizedString(@"Shuffle", nil)];
//	[self.shuffleButton setImage:[UIImage imageNamed:@"shuffle_black.png"]];
//	[self.shuffleButton setColour:[UIColor whiteColor]];
//    self.shuffleButton.delegate = self;
//	[self.repeatButton setupWithImageMultiplier:0.5];
//	[self.repeatButton setTitle:NSLocalizedString(@"Repeat", nil)];
//	[self.repeatButton setImage:[UIImage imageNamed:@"repeat_black.png"]];
//	[self.repeatButton setColour:[UIColor whiteColor]];
//    self.repeatButton.delegate = self;
//	[self.dynamicPlaylistButton setupWithImageMultiplier:0.5];
//	[self.dynamicPlaylistButton setTitle:NSLocalizedString(@"Settings", nil)];
//	[self.dynamicPlaylistButton setImage:[UIImage imageNamed:@"settings.png"]];
//	[self.dynamicPlaylistButton setColour:[UIColor whiteColor]];
//    self.dynamicPlaylistButton.delegate = self;
	
    self.shadingView = [[UIView alloc]init];
    self.shadingView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
    self.shadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundImageView addSubview:self.shadingView];
	
	[self.shadingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.backgroundImageView];
	[self.shadingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundImageView];
	[self.shadingView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.shadingView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
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
	
	if(self.musicPlayer.shuffleMode == MPMusicShuffleModeDefault){
		self.shuffleMode = MPMusicShuffleModeSongs;
	}
	else{
		self.shuffleMode = self.musicPlayer.shuffleMode;
	}
	if(self.musicPlayer.repeatMode == MPMusicRepeatModeDefault){
		self.repeatMode = MPMusicRepeatModeNone;
	}
	else{
		self.repeatMode = self.musicPlayer.repeatMode;
	}
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
    [self.contentContainerView addGestureRecognizer:panRecognizer];
    
    self.loadedSubviews = YES;
    
    //NSLog(@"Starting test image...");
    //[self sendTestImage];
	
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if(![defaults objectForKey:@"shitty_tutorial"]){
		UIAlertController * alert = [UIAlertController
									 alertControllerWithTitle:NSLocalizedString(@"HowToUse", nil)
									 message:NSLocalizedString(@"HowToUseDescription", nil)
									 preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* yesButton = [UIAlertAction
									actionWithTitle:NSLocalizedString(@"OkThanks", nil)
									style:UIAlertActionStyleDefault
									handler:^(UIAlertAction * action) {
										[defaults setBool:YES forKey:@"shitty_tutorial"];
									}];
		
		[alert addAction:yesButton];
		
		NSArray *viewArray = [[[[[[[[[[[[alert view] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews];
		UILabel *alertMessage = viewArray[1];
		alertMessage.textAlignment = NSTextAlignmentLeft;
		
		//[self presentViewController:alert animated:YES completion:nil];
		
	}
	
    if([defaults objectForKey:@"pebble_coldstart"]){
        [self.central run];
    }
    else{
        UIAlertController * alert = [UIAlertController
									 alertControllerWithTitle:NSLocalizedString(@"PebbleConnectionRequestTitle", nil)
                                     message:NSLocalizedString(@"PebbleConnectionRequestDescription", nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
									actionWithTitle:NSLocalizedString(@"Okay", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [self.central run];
                                        [defaults setBool:YES forKey:@"pebble_coldstart"];
                                    }];
        
        [alert addAction:yesButton];
        
        // [self presentViewController:alert animated:YES completion:nil];
        
    }

    /*
    UIImage *image = [UIImage imageWithContentsOfFile:[LMPebbleImage ditherImage:[self.musicPlayer.nowPlayingItem.artwork imageWithSize:CGSizeMake(28, 28)]
                                                                        withSize:CGSizeMake(36, 36)
                                                                   forTotalParts:1
                                                                 withCurrentPart:0
                                                                 isBlackAndWhite:NO
                                                                    isRoundWatch:NO]];
    UIImageView *view = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    view.image = image;
    [self.view addSubview:view];
     */
	
	self.volumeView = [[MPVolumeView alloc] init];
	self.volumeView.showsRouteButton = NO;
	self.volumeView.showsVolumeSlider = NO;
	[self.view addSubview:self.volumeView];
	
	//find the volumeSlider
	self.volumeViewSlider = nil;
	for (UIView *view in [self.volumeView subviews]){
		if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
			self.volumeViewSlider = (UISlider*)view;
			break;
		}
	}
	
	[self.volumeViewSlider addTarget:self action:@selector(handleVolumeChanged:) forControlEvents:UIControlEventValueChanged];
	
	NSLog(@"Hey");
	[self nowPlayingItemChanged:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSLog(@"Loaded view");
    
    self.central = [PBPebbleCentral defaultCentral];
    self.central.delegate = self;
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"edf76057-f3ef-4de6-b841-cb9532a81a5a"];
    
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
	
	//[self nowPlayingItemChanged:self];
    
    NSLog(@"View did load");
}

- (void)viewDidDisappear:(BOOL)animated {
	NSLog(@"View disappeared");
	
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

- (void)viewDidUnload:(BOOL)animated {
    NSLog(@"View did unload");
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
