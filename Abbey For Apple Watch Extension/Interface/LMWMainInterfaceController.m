//
//  InterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "LMWMainInterfaceController.h"
#import "LMWProgressSliderInfo.h"
#import "LMWCompanionBridge.h"
#import "LMWMusicTrackInfoRowController.h"

@interface LMWMainInterfaceController ()<LMWProgressSliderDelegate, LMWCompanionBridgeDelegate>

/**
 The info object for the progress slider.
 */
@property LMWProgressSliderInfo *progressSliderInfo;

/**
 The info object for the volume progress bar.
 */
@property LMWProgressSliderInfo *volumeProgressInfo;

/**
 The bridge for the companion.
 */
@property LMWCompanionBridge *companionBridge;

/**
 The timer for updating the progress bar.
 */
@property NSTimer *progressBarUpdateTimer;

/**
 User has tapped an up next entry, and the watch is waiting for a reply from the phone. Prevents multiple sending of the same message because of an impatient user.
 */
@property BOOL alreadyTappedUpNextEntry;

@end


@implementation LMWMainInterfaceController


- (void)debug:(NSString*)debugMessage {
	[self.titleLabel setText:debugMessage];
}

- (void)companionDebug:(NSString *)debug {
	[self debug:debug];
}


- (void)musicTrackDidChange:(LMWMusicTrackInfo *)musicTrackInfo {
	if(![self.companionBridge onboardingComplete]){
		return;
	}
	
	//Track info is already set within the companion
	dispatch_async(dispatch_get_main_queue(), ^{
		if(musicTrackInfo == nil){
			[self.titleLabel setText:NSLocalizedString(@"NothingPlaying", nil)];
			[self.subtitleLabel setText:nil];
			[self.albumArtImage setImage:[UIImage imageNamed:@"watch_no_cover_art.png"]];
			[self.favouriteImage setImage:[UIImage imageNamed:@"icon_unfavourite_white.png"]];
			[self.progressSliderInfo setPercentage:0.0 animated:YES];
			[self configureTableWithData:@[]];
		}
		else{
			[self.titleLabel setText:musicTrackInfo.title];
			[self.subtitleLabel setText:musicTrackInfo.subtitle];
			[self.albumArtImage setImage:musicTrackInfo.albumArt];
			[self reloadFavouriteButton];
		}
		
		[self setNothingPlaying:musicTrackInfo == nil];
		
		[self reloadThemedElements];
	});
}

- (void)albumArtDidChange:(UIImage*)albumArt {
	[self.albumArtImage setImage:albumArt];
}

- (void)reloadTrackProgressBar {
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self.companionBridge.nowPlayingInfo.nowPlayingTrack.playbackDuration == 0){
			[self.progressSliderInfo setPercentage:0
										  animated:YES];
		}
		else{
			[self.progressSliderInfo setPercentage:((CGFloat)self.companionBridge.nowPlayingInfo.currentPlaybackTime/(CGFloat)self.companionBridge.nowPlayingInfo.nowPlayingTrack.playbackDuration)
								  animated:YES];
		}
	});
	
	if(self.companionBridge.nowPlayingInfo.playing){
		if(self.progressBarUpdateTimer){
			[self.progressBarUpdateTimer invalidate];
		}
		
		self.progressBarUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.00
																	  repeats:YES
																		block:
									   ^(NSTimer * _Nonnull timer) {
										   self.companionBridge.nowPlayingInfo.currentPlaybackTime++;
										   [self reloadTrackProgressBar];
									   }];
	}
	else{
		[self.progressBarUpdateTimer invalidate];
		self.progressBarUpdateTimer = nil;
	}
}

- (void)reloadShuffleButton {
	[self animateWithDuration:0.4 animations:^{
		[self.shuffleButtonGroup setBackgroundColor:self.companionBridge.nowPlayingInfo.shuffleMode ? self.companionBridge.phoneThemeMainColour : [UIColor blackColor]];
	}];
	
	[self.shuffleImage setImageNamed:@"icon_shuffle_white.png"];
}

- (void)reloadFavouriteButton {
	[self.favouriteImage setImage:self.companionBridge.nowPlayingInfo.nowPlayingTrack.isFavourite ? [UIImage imageNamed:@"icon_favourite_red.png"] : [UIImage imageNamed:@"icon_favourite_outlined_white.png"]];
}

- (void)reloadRepeatButton {
	UIImage *newRepeatImage = nil;
	switch(self.companionBridge.nowPlayingInfo.repeatMode){
		case LMMusicRepeatModeDefault:
		case LMMusicRepeatModeNone:
		case LMMusicRepeatModeAll:
			newRepeatImage = [UIImage imageNamed:@"icon_repeat_general_white.png"];
			break;
		case LMMusicRepeatModeOne:
			newRepeatImage = [UIImage imageNamed:@"icon_repeat_one_white.png"];
			break;
			
	}
	[self.repeatImage setImage:newRepeatImage];
	
	[self animateWithDuration:0.4 animations:^{
		[self.repeatButtonGroup setBackgroundColor:(self.companionBridge.nowPlayingInfo.repeatMode != LMMusicRepeatModeNone) ? self.companionBridge.phoneThemeMainColour : [UIColor blackColor]];
	}];
}

- (void)reloadPlayPauseButton {
	[self.playPauseImage setImageNamed:self.companionBridge.nowPlayingInfo.playing ? @"icon_pause.png" : @"icon_play.png"];
}

- (void)reloadVolumeProgressBar {
	[self.volumeProgressInfo setPercentage:self.companionBridge.nowPlayingInfo.volume animated:YES];
}

- (void)reloadThemedElements {
	[self.browseButtonBackgroundGroup setBackgroundColor:self.companionBridge.phoneThemeMainColour];
	[self.nothingPlayingBrowseButtonBackgroundGroup setBackgroundColor:self.companionBridge.phoneThemeMainColour];
	
	[self.volumeBarGroup setBackgroundColor:self.companionBridge.phoneThemeMainColour];
	[self.progressBarGroup setBackgroundColor:self.companionBridge.phoneThemeMainColour];
	
	[self reloadShuffleButton];
	[self reloadRepeatButton];
}

- (void)nowPlayingInfoDidChange:(LMWNowPlayingInfo *)nowPlayingInfo {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reloadTrackProgressBar];
		
//		[self reloadShuffleButton];
//		[self reloadRepeatButton];
		
		[self reloadThemedElements];
		
		[self reloadVolumeProgressBar];
		
		[self.nextTrackImage setImageNamed:@"next_track.png"];
		[self.previousTrackImage setImageNamed:@"previous_track.png"];
		
		[self reloadPlayPauseButton];
	});
}

- (void)nowPlayingTrackUpdate:(LMWMusicTrackInfo *)nowPlayingTrack forKey:(NSString*)key {
	if([key isEqualToString:LMAppleWatchMusicTrackInfoKeyIsFavourite]){
		[self reloadFavouriteButton];
	}
}

- (void)nowPlayingInfoUpdate:(LMWNowPlayingInfo *)nowPlayingInfo forKey:(NSString*)key {
	if([key isEqualToString:LMAppleWatchNowPlayingInfoKeyIsPlaying]){
		[self reloadPlayPauseButton];
		[self reloadTrackProgressBar];
	}
	else if([key isEqualToString:LMAppleWatchNowPlayingInfoKeyCurrentPlaybackTime]){
		[self reloadTrackProgressBar];
	}
	else if([key isEqualToString:LMAppleWatchNowPlayingInfoKeyVolume]){
		[self reloadVolumeProgressBar];
	}
	else if([key isEqualToString:LMAppleWatchNowPlayingInfoKeyShuffleMode]){
		[self reloadShuffleButton];
		[self reloadRepeatButton];
	}
	else if([key isEqualToString:LMAppleWatchNowPlayingInfoKeyTheme]){
		[self reloadThemedElements];
	}
}

- (void)displayAsUpdating {
	[self.subtitleLabel setText:NSLocalizedString(@"Updating", nil)];
//	[self.subtitleLabel setText:nil];
}


- (void)progressSliderWithInfo:(LMWProgressSliderInfo*)progressSliderInfo slidToNewPositionWithPercentage:(CGFloat)percentage {
	if(progressSliderInfo == self.progressSliderInfo){
		NSInteger newPlaybackTime = (NSInteger)((CGFloat)self.companionBridge.nowPlayingInfo.nowPlayingTrack.playbackDuration * percentage);
		
		self.companionBridge.nowPlayingInfo.currentPlaybackTime = newPlaybackTime;

		__weak id weakSelf = self;
		
		[self.companionBridge setCurrentPlaybackTime:newPlaybackTime
									  successHandler:^(NSDictionary *response) {
										  
									  } errorHandler:^(NSError *error) {
										  id strongSelf = weakSelf;
										  
										  if (!strongSelf) {
											  return;
										  }
										  
										  [strongSelf handleConnectionError:error withHandler:nil];
									  }];
	}
	else{
		[self debug:[NSString stringWithFormat:@"%.02f", percentage]];
	}
}

- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer {
	if(!self.companionBridge.nowPlayingInfo.nowPlayingTrack){
		return;
	}
	
	[self.progressSliderInfo handleProgressPanGesture:panGestureRecognizer];
}

- (void)showLoadingIconOnInterfaceImage:(WKInterfaceImage*)interfaceImage {
	dispatch_async(dispatch_get_main_queue(), ^{
		[interfaceImage setImageNamed:@"Activity"];
		[interfaceImage startAnimatingWithImagesInRange:NSMakeRange(0, 30)
													duration:1.0
												 repeatCount:0];
	});
}

- (void)presentPhoneNotRespondingControllerWithHandler:(WKAlertActionHandler)handler {
	WKAlertAction *okayAction = [WKAlertAction actionWithTitle:NSLocalizedString(@"DarnOkay", nil)
														 style:WKAlertActionStyleDefault
													   handler:handler];
	
	[self presentAlertControllerWithTitle:NSLocalizedString(@"OhBoy", nil)
								  message:NSLocalizedString(@"PhoneDidNotReplyToCommandError", nil)
						   preferredStyle:WKAlertControllerStyleAlert actions:@[ okayAction ]];
}

- (void)presentUnknownErrorControllerWithError:(NSError*)error handler:(WKAlertActionHandler)handler {
	WKAlertAction *okayAction = [WKAlertAction actionWithTitle:NSLocalizedString(@"DarnOkay", nil)
														 style:WKAlertActionStyleDefault
													   handler:handler];
	
	NSString *localizedAlertString = [NSString stringWithFormat:NSLocalizedString(@"UnknownErrorAlert", nil), error.code, error.localizedDescription];
	
	[self presentAlertControllerWithTitle:NSLocalizedString(@"OhBoy", nil)
								  message:localizedAlertString
						   preferredStyle:WKAlertControllerStyleAlert actions:@[ okayAction ]];
}

- (void)presentUserTriedThatTooMuchControllerWithHandler:(WKAlertActionHandler)handler {
	WKAlertAction *okayAction = [WKAlertAction actionWithTitle:NSLocalizedString(@"DarnOkay", nil)
														 style:WKAlertActionStyleDefault
													   handler:handler];
	
	NSString *localizedAlertString = [NSString stringWithFormat:NSLocalizedString(@"TryingThatTooMuch", nil)];
	
	[self presentAlertControllerWithTitle:NSLocalizedString(@"OhBoy", nil)
								  message:localizedAlertString
						   preferredStyle:WKAlertControllerStyleAlert actions:@[ okayAction ]];
}

- (void)handleConnectionError:(NSError*)error withHandler:(WKAlertActionHandler)handler {
	if(error.code == 503 || error.code == 7017){
		[self presentPhoneNotRespondingControllerWithHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				if(handler){
					handler();
				}
			});
		}];
	}
	else if(error.code == 7007){ //User is trying too much and their watch wasn't able to detect reachability properly
		[self presentUserTriedThatTooMuchControllerWithHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				if(handler){
					handler();
				}
			});
		}];
	}
	else{
		[self presentUnknownErrorControllerWithError:error handler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				if(handler){
					handler();
				}
			});
		}];
	}
}

- (IBAction)favouriteButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.favouriteImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyFavouriteUnfavourite
												 successHandler:^(NSDictionary *response) {
													 BOOL isFavourite = [[response objectForKey:LMAppleWatchMusicTrackInfoKeyIsFavourite] boolValue];
													 
													 self.companionBridge.nowPlayingInfo.nowPlayingTrack.isFavourite = isFavourite;
													 
													 [self reloadFavouriteButton];
													 
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self reloadFavouriteButton];
													 }];
												 }];
	
//	WKInterfaceDevice.currentDevice().[play(.success)
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)shuffleButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.shuffleImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyInvertShuffleMode
												 successHandler:^(NSDictionary *response) {
													 BOOL isShuffling = [[response objectForKey:LMAppleWatchNowPlayingInfoKeyShuffleMode] boolValue];
													 
													 self.companionBridge.nowPlayingInfo.shuffleMode = isShuffling;
													 
													 [self reloadShuffleButton];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self reloadShuffleButton];
													 }];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)repeatButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.repeatImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextRepeatMode
												 successHandler:^(NSDictionary *response) {
													 LMMusicRepeatMode repeatMode = (LMMusicRepeatMode)[[response objectForKey:LMAppleWatchNowPlayingInfoKeyRepeatMode] integerValue];
													 
													 self.companionBridge.nowPlayingInfo.repeatMode = repeatMode;
													 
													 [self reloadRepeatButton];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self reloadRepeatButton];
													 }];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)browseLibraryButtonSelector:(id)sender {
	NSLog(@"Browse library");
}

- (IBAction)nextTrackButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.nextTrackImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextTrack
												 successHandler:^(NSDictionary *response) {
													 [self.nextTrackImage setImageNamed:@"next_track.png"];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self.nextTrackImage setImageNamed:@"next_track.png"];
													 }];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)previousTrackButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.previousTrackImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPreviousTrack
												 successHandler:^(NSDictionary *response) {
													 [self.previousTrackImage setImageNamed:@"previous_track.png"];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self.previousTrackImage setImageNamed:@"previous_track.png"];
													 }];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)playPauseButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.playPauseImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPlayPause
												 successHandler:^(NSDictionary *response) {
													 BOOL isPlaying = [[response objectForKey:LMAppleWatchNowPlayingInfoKeyIsPlaying] boolValue];
													 
													 self.companionBridge.nowPlayingInfo.playing = isPlaying;
													 
													 [self reloadPlayPauseButton];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:^{
														 [self reloadPlayPauseButton];
													 }];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
}

- (IBAction)volumeDownButtonSelector:(id)sender {
//	[self showLoadingIconOnInterfaceImage:self.volumeDownImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeDown
												 successHandler:^(NSDictionary *response) {
													 CGFloat newVolume = [[response objectForKey:LMAppleWatchNowPlayingInfoKeyVolume] floatValue];
													 
													 self.companionBridge.nowPlayingInfo.volume = newVolume;
													 
													 [self reloadVolumeProgressBar];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:nil];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
	
//	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeDown];
}

- (IBAction)volumeUpButtonSelector:(id)sender {
//	[self showLoadingIconOnInterfaceImage:self.volumeUpImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeUp
												 successHandler:^(NSDictionary *response) {
													 CGFloat newVolume = [[response objectForKey:LMAppleWatchNowPlayingInfoKeyVolume] floatValue];
													 
													 self.companionBridge.nowPlayingInfo.volume = newVolume;
													 
													 [self reloadVolumeProgressBar];
												 } errorHandler:^(NSError *error) {
													 [self handleConnectionError:error withHandler:nil];
												 }];
	
	[[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeClick];
	
//	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeUp];
}


- (void)nowPlayingUpNextDidChange:(NSArray<LMWMusicTrackInfo*>*)upNextTracks {
	self.alreadyTappedUpNextEntry = NO;
	
	[self configureTableWithData:upNextTracks];
}


- (void)configureTableWithData:(NSArray<LMWMusicTrackInfo*>*)musicTrackInfoObjects {
	if(musicTrackInfoObjects.count != 0){
		[self.upNextLabel setText:NSLocalizedString(@"Updating", nil)];
	}
//	[self.queueTable setNumberOfRows:0 withRowType:@"QueueTrackRow"];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.upNextLabel setText:NSLocalizedString((musicTrackInfoObjects.count == 0) ? @"NothingUpNext" : @"UpNext", nil)];
		
		[self.queueTable setNumberOfRows:[musicTrackInfoObjects count] withRowType:@"QueueTrackRow"];
		for (NSInteger i = 0; i < self.queueTable.numberOfRows; i++) {
			LMWMusicTrackInfoRowController *row = [self.queueTable rowControllerAtIndex:i];

			LMWMusicTrackInfo *trackInfo = [musicTrackInfoObjects objectAtIndex:i];
			
			[row.number setText:[NSString stringWithFormat:@"%d", (int)(i+1)]];
			
			[row.titleLabel setText:trackInfo.title];
			[row.subtitleLabel setText:trackInfo.subtitle];
		}
	});
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	if(self.alreadyTappedUpNextEntry){
		return;
	}
	
	LMWMusicTrackInfoRowController *row = [self.queueTable rowControllerAtIndex:rowIndex];
	
	if(rowIndex < self.companionBridge.nowPlayingInfo.nextUpTracksArray.count){
		self.alreadyTappedUpNextEntry = YES;
		
		LMWMusicTrackInfo *musicTrackInfo = [self.companionBridge.nowPlayingInfo.nextUpTracksArray objectAtIndex:rowIndex];
		
//		[self.upNextLabel setText:NSLocalizedString(@"Playing", nil)];
//		[self.queueTable setNumberOfRows:0 withRowType:@"QueueTrackRow"];
		
		[row.subtitleLabel setText:NSLocalizedString(@"Playing", nil)];
		
		[self.companionBridge setUpNextTrack:musicTrackInfo.indexInCollection];
	}
}

- (void)companionConnectionStatusChanged:(BOOL)connected {
	NSLog(@"Connection status changed %d", connected);
	if(connected){
		[self setError:nil];
	}
	else{
		if(self.companionBridge.requiresUnlock){
			[self setError:NSLocalizedString(@"UserMustUnlockiPhone", nil)];
		}
		else{
			[self setError:NSLocalizedString(@"WaitingForPhone", nil)];
		}
	}
}

- (void)onboardingCompleteStatusChanged:(BOOL)onboardingComplete {
	NSLog(@"Onboarding status changed %d", onboardingComplete);
	if(onboardingComplete){
		[self setError:nil];
	}
	else{
		[self setError:NSLocalizedString(@"WaitingForOnboarding", nil)];
	}
}

- (void)setError:(NSString*)error {
	if(![self.companionBridge onboardingComplete]){
		error = NSLocalizedString(@"WaitingForOnboarding", nil);
	}
	
	BOOL hideContents = error ? YES : NO;
	
	[self.nowPlayingGroup setHidden:hideContents];
	[self.extraControlsGroup setHidden:hideContents];
	
	if(error){
		[self.nothingPlayingGroup setHidden:YES];
	}
	else{
		[self setNothingPlaying:(self.companionBridge.nowPlayingInfo.nowPlayingTrack ? NO : YES )];
	}
	
	[self.errorGroup setHidden:!hideContents];
	
	if(error){
		[self.errorLabel setText:error];
	}
}

- (void)setNothingPlaying:(BOOL)nothingPlaying {
	if(![self.companionBridge onboardingComplete]){
		[self setError:NSLocalizedString(@"WaitingForOnboarding", nil)];
		return;
	}
	
	[self.nothingPlayingGroup setHidden:!nothingPlaying];
	[self.nothingPlayingLabel setHidden:!nothingPlaying];
	
	[self.errorGroup setHidden:YES];
	[self.nowPlayingGroup setHidden:nothingPlaying];
	[self.extraControlsGroup setHidden:nothingPlaying];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
	[self setTitle:@"Abbey"];
	
	self.progressSliderInfo = [[LMWProgressSliderInfo alloc] initWithProgressBarGroup:self.progressBarGroup
																		  inContainer:self.progressBarContainer
																onInterfaceController:self];
	self.progressSliderInfo.delegate = self;
	
	
	self.volumeProgressInfo = [[LMWProgressSliderInfo alloc] initWithProgressBarGroup:self.volumeBarGroup
																		  inContainer:nil
																onInterfaceController:self];
	self.volumeProgressInfo.delegate = self;
	self.volumeProgressInfo.width = self.contentFrame.size.width * 0.33;
	
	
	self.companionBridge = [LMWCompanionBridge sharedCompanionBridge];
	[self.companionBridge addDelegate:self];
	
	
	[self displayAsUpdating];
	
	[self.nothingPlayingGroup setHidden:NO];
	[self.nothingPlayingLabel setText:NSLocalizedString(@"NothingPlayingFullText", nil)];
	
	[self companionConnectionStatusChanged:self.companionBridge.connected];
	
	[NSTimer scheduledTimerWithTimeInterval:2.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self companionConnectionStatusChanged:self.companionBridge.connected];
		
		[NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self companionConnectionStatusChanged:self.companionBridge.connected];
		}];
	}];
	
	[self.browseLibraryLabel setText:NSLocalizedString(@"BrowseLibrary", nil)];
	[self.nothingPlayingBrowseLibraryLabel setText:NSLocalizedString(@"BrowseLibrary", nil)];
	
	[self configureTableWithData:@[]];
	
	[self reloadThemedElements];
}

- (void)willActivate {
    [super willActivate];
	
	[self.progressBarUpdateTimer invalidate];
	self.progressBarUpdateTimer = nil;
	
	if(!self.companionBridge.connected){
		[self companionConnectionStatusChanged:self.companionBridge.connected];
		
		[self.companionBridge askCompanionForNowPlayingTrackInfo];
	}
	else if(!self.companionBridge.nowPlayingInfo.nowPlayingTrack){
		[self setNothingPlaying:YES];
	}
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.companionBridge askCompanionForNowPlayingTrackInfo];
		[self displayAsUpdating];
	}];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end



