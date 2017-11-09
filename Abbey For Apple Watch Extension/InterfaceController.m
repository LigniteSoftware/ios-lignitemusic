//
//  InterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "InterfaceController.h"
#import "LMWProgressSliderInfo.h"
#import "LMWCompanionBridge.h"

@interface InterfaceController ()<LMWProgressSliderDelegate, LMWCompanionBridgeDelegate>

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

@end


@implementation InterfaceController


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

- (IBAction)favouritesImageTapGestureRecognizerTapped:(WKTapGestureRecognizer*)tapGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyFavouriteUnfavourite];
}

- (IBAction)nextSongGestureSwiped:(WKSwipeGestureRecognizer*)swipeGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyNextTrack];
}

- (IBAction)previousSongGestureSwiped:(WKSwipeGestureRecognizer*)swipeGestureRecognizer {
	[self.companionBridge sendMusicControlMessageToPhoneWithKey:LMAppleWatchControlKeyPreviousTrack];
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



