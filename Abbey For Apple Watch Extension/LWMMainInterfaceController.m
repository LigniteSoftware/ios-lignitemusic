//
//  InterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "LWMMainInterfaceController.h"
#import "LMWProgressSliderInfo.h"
#import "LMWCompanionBridge.h"
#import "LWMMusicTrackInfoRowController.h"

@interface LWMMainInterfaceController ()<LMWProgressSliderDelegate, LMWCompanionBridgeDelegate>

/**
 The info object for the progress slider.
 */
@property LMWProgressSliderInfo *progressSliderInfo;

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


@implementation LWMMainInterfaceController


- (void)debug:(NSString*)debugMessage {
	[self.titleLabel setText:debugMessage];
}

- (void)companionDebug:(NSString *)debug {
	[self debug:debug];
}


- (void)musicTrackDidChange:(LMWMusicTrackInfo *)musicTrackInfo {
	if(musicTrackInfo == nil){
		[self.titleLabel setText:NSLocalizedString(@"NothingPlaying", nil)];
		[self.subtitleLabel setText:nil];
		[self.albumArtImage setImage:[UIImage imageNamed:@"watch_no_cover_art.png"]];
		[self.favouriteImage setImage:[UIImage imageNamed:@"icon_unfavourite_white.png"]];
		[self.progressSliderInfo setPercentage:0.0 animated:YES];
	}
	else{
		[self.titleLabel setText:musicTrackInfo.title];
		[self.subtitleLabel setText:musicTrackInfo.subtitle];
		[self.albumArtImage setImage:musicTrackInfo.albumArt];
		[self.favouriteImage setImage:musicTrackInfo.isFavourite ? [UIImage imageNamed:@"icon_favourite_red.png"] : [UIImage imageNamed:@"icon_favourite_outlined_white.png"]];
	}
}

- (void)albumArtDidChange:(UIImage*)albumArt {
	[self.albumArtImage setImage:albumArt];
}

- (void)updateProgressBar {
	[self.progressSliderInfo setPercentage:((CGFloat)self.companionBridge.nowPlayingInfo.currentPlaybackTime/(CGFloat)self.companionBridge.nowPlayingInfo.playbackDuration)
								  animated:YES];
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
}

- (void)displayAsLoading {
	[self.titleLabel setText:NSLocalizedString(@"Loading", nil)];
	[self.subtitleLabel setText:nil];
}


- (void)progressSliderWithInfo:(LMWProgressSliderInfo *)progressSliderInfo slidToNewPositionWithPercentage:(CGFloat)percentage {
	
	NSInteger newPlaybackTime = (NSInteger)((CGFloat)self.companionBridge.nowPlayingInfo.playbackDuration * percentage);
	
	self.companionBridge.nowPlayingInfo.currentPlaybackTime = newPlaybackTime;

	[self.companionBridge setCurrentPlaybackTime:newPlaybackTime];
}

- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer {
	if(!self.companionBridge.nowPlayingInfo.nowPlayingTrack){
		return;
	}
	
	[self.progressSliderInfo handleProgressPanGesture:panGestureRecognizer];
}

- (IBAction)playPauseTapGestureRecognizerTapped:(WKTapGestureRecognizer*)tapGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPlayPause];
}

- (IBAction)favouriteButtonSelector:(id)sender {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyFavouriteUnfavourite];
}

- (IBAction)shuffleButtonSelector:(id)sender {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyInvertShuffleMode];
}

- (IBAction)repeatButtonSelector:(id)sender {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextRepeatMode];
}

- (IBAction)browseLibraryButtonSelector:(id)sender {
	NSLog(@"Browse library");
}

- (IBAction)nextSongGestureSwiped:(WKSwipeGestureRecognizer*)swipeGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextTrack];
}

- (IBAction)previousSongGestureSwiped:(WKSwipeGestureRecognizer*)swipeGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPreviousTrack];
}


- (void)nowPlayingUpNextDidChange:(NSArray<LMWMusicTrackInfo*>*)upNextTracks {
	self.alreadyTappedUpNextEntry = NO;
	
	[self configureTableWithData:upNextTracks];
}


- (void)configureTableWithData:(NSArray<LMWMusicTrackInfo*>*)musicTrackInfoObjects {
	[self.upNextLabel setText:NSLocalizedString((musicTrackInfoObjects.count == 0) ? @"NothingUpNext" : @"UpNext", nil)];
	
	[self.queueTable setNumberOfRows:[musicTrackInfoObjects count] withRowType:@"QueueTrackRow"];
	for (NSInteger i = 0; i < self.queueTable.numberOfRows; i++) {
		LWMMusicTrackInfoRowController *row = [self.queueTable rowControllerAtIndex:i];

		LMWMusicTrackInfo *trackInfo = [musicTrackInfoObjects objectAtIndex:i];
		
		[row.number setText:[NSString stringWithFormat:@"%d", (int)(i+1)]];
		
		[row.titleLabel setText:trackInfo.title];
		[row.subtitleLabel setText:trackInfo.subtitle];
	}
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	if(self.alreadyTappedUpNextEntry){
		return;
	}
	
	LWMMusicTrackInfoRowController *row = [self.queueTable rowControllerAtIndex:rowIndex];
	
	if(rowIndex < self.companionBridge.nowPlayingInfo.nextUpTracksArray.count){
		self.alreadyTappedUpNextEntry = YES;
		
		LMWMusicTrackInfo *musicTrackInfo = [self.companionBridge.nowPlayingInfo.nextUpTracksArray objectAtIndex:rowIndex];
		
		[row.subtitleLabel setText:NSLocalizedString(@"HangOn", nil)];
		
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
	
	
	self.companionBridge = [LMWCompanionBridge sharedCompanionBridge];
	[self.companionBridge addDelegate:self];
	
	
	[self configureTableWithData:@[]];
}

- (void)willActivate {
    [super willActivate];
	
	[self.progressBarUpdateTimer invalidate];
	self.progressBarUpdateTimer = nil;
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.companionBridge askCompanionForNowPlayingTrackInfo];
		[self displayAsLoading];
	}];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end



