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
			[self.favouriteImage setImage:musicTrackInfo.isFavourite ? [UIImage imageNamed:@"icon_favourite_red.png"] : [UIImage imageNamed:@"icon_favourite_outlined_white.png"]];
		}
	});
}

- (void)albumArtDidChange:(UIImage*)albumArt {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.albumArtImage setImage:albumArt];
	});
}

- (void)updateProgressBar {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.progressSliderInfo setPercentage:((CGFloat)self.companionBridge.nowPlayingInfo.currentPlaybackTime/(CGFloat)self.companionBridge.nowPlayingInfo.playbackDuration)
								  animated:YES];
	});
}

- (void)nowPlayingInfoDidChange:(LMWNowPlayingInfo *)nowPlayingInfo {
//	[self debug:[NSString stringWithFormat:@"%d/%d", (int)nowPlayingInfo.currentPlaybackTime, (int)nowPlayingInfo.playbackDuration]];
	
	[self updateProgressBar];
	
	if(nowPlayingInfo.playing){
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self.progressBarUpdateTimer){
				[self.progressBarUpdateTimer invalidate];
			}
			
			self.progressBarUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.00
																		  repeats:YES
																			block:
												^(NSTimer * _Nonnull timer) {
													self.companionBridge.nowPlayingInfo.currentPlaybackTime++;
													[self updateProgressBar];
												}];
			
			UIImage *newRepeatImage = nil;
			switch(nowPlayingInfo.repeatMode){
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
			
			[self.shuffleImage setImageNamed:@"icon_shuffle_white.png"];
			[self.nextTrackImage setImageNamed:@"next_track.png"];
			[self.previousTrackImage setImageNamed:@"previous_track.png"];
//			[self.volumeUpImage setImageNamed:@"icon_plus_white.png"];
//			[self.volumeDownImage setImageNamed:@"icon_minus.png"];
			
			[self.volumeProgressInfo setPercentage:nowPlayingInfo.volume animated:YES];
			
//			[self.titleLabel setText:[NSString stringWithFormat:@"%.02f", nowPlayingInfo.volume]];
			
			[self animateWithDuration:0.4 animations:^{
				[self.repeatButtonGroup setBackgroundColor:(nowPlayingInfo.repeatMode != LMMusicRepeatModeNone) ? [UIColor redColor] : [UIColor blackColor]];
				
				[self.shuffleButtonGroup setBackgroundColor:(nowPlayingInfo.shuffleMode) ? [UIColor redColor] : [UIColor blackColor]];
			}];
		});
	}
	else{
		[self.progressBarUpdateTimer invalidate];
		self.progressBarUpdateTimer = nil;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.playPauseImage setImageNamed:nowPlayingInfo.playing ? @"icon_pause.png" : @"icon_play.png"];
	});
}

- (void)displayAsUpdating {
	[self.titleLabel setText:NSLocalizedString(@"Updating", nil)];
	[self.subtitleLabel setText:nil];
}


- (void)progressSliderWithInfo:(LMWProgressSliderInfo*)progressSliderInfo slidToNewPositionWithPercentage:(CGFloat)percentage {
	if(progressSliderInfo == self.progressSliderInfo){
		NSInteger newPlaybackTime = (NSInteger)((CGFloat)self.companionBridge.nowPlayingInfo.playbackDuration * percentage);
		
		self.companionBridge.nowPlayingInfo.currentPlaybackTime = newPlaybackTime;

		[self.companionBridge setCurrentPlaybackTime:newPlaybackTime];
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

- (IBAction)favouriteButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.favouriteImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyFavouriteUnfavourite];
}

- (IBAction)shuffleButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.shuffleImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyInvertShuffleMode];
}

- (IBAction)repeatButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.repeatImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextRepeatMode];
}

- (IBAction)browseLibraryButtonSelector:(id)sender {
	NSLog(@"Browse library");
}

- (IBAction)nextTrackButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.nextTrackImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextTrack];
}

- (IBAction)previousTrackButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.previousTrackImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPreviousTrack];
}

- (IBAction)playPauseButtonSelector:(id)sender {
	[self showLoadingIconOnInterfaceImage:self.playPauseImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPlayPause];
}

- (IBAction)volumeDownButtonSelector:(id)sender {
//	[self showLoadingIconOnInterfaceImage:self.volumeDownImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeDown];
}

- (IBAction)volumeUpButtonSelector:(id)sender {
//	[self showLoadingIconOnInterfaceImage:self.volumeUpImage];
	
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyVolumeUp];
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
	
	
	[self configureTableWithData:@[]];
}

- (void)willActivate {
    [super willActivate];
	
	[self.progressBarUpdateTimer invalidate];
	self.progressBarUpdateTimer = nil;
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.companionBridge askCompanionForNowPlayingTrackInfo];
//		[NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
//			[self displayAsUpdating];
//		}];
	}];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end



