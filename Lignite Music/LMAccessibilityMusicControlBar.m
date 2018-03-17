//
//  LMAccessibilityMusicControlBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/16/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAccessibilityMusicControlBar.h"
#import "LMAccessibilityButton.h"
#import "LMMusicPlayer.h"
#import "LMAppIcon.h"


@interface LMAccessibilityMusicControlBar()<LMAccessibilityButtonDelegate, LMMusicPlayerDelegate>

/**
 The container which provides padding from the edge of the control bar.
 */
@property UIView *containerView;

/**
 The button for going to the previous track.
 */
@property LMAccessibilityButton *previousTrackButton;

/**
 The button for playing/pausing music.
 */
@property LMAccessibilityButton *playPauseButton;

/**
 The button for going to the next track.
 */
@property LMAccessibilityButton *nextTrackButton;

/**
 The button for expanding/minimizing the now playing view.
 */
@property LMAccessibilityButton *expandMinimizeButton;

/**
 The music player for actual music control.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMAccessibilityMusicControlBar

- (void)updatePlayPauseButton {
	BOOL playing = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
	
	self.playPauseButton.icon = [LMAppIcon imageForIcon:playing ? LMIconPause : LMIconPlay];
	
	self.playPauseButton.accessibilityLabel = NSLocalizedString(playing ? @"VoiceOverLabel_PauseTrack" : @"VoiceOverLabel_PlayTrack", nil);
	self.playPauseButton.accessibilityHint = NSLocalizedString(playing ? @"VoiceOverHint_PauseTrack" : @"VoiceOverHint_PlayTrack", nil);
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self updatePlayPauseButton];
}

- (void)accessibilityButtonTapped:(LMAccessibilityButton*)accessibilityButton {
	if(accessibilityButton == self.expandMinimizeButton && self.delegate){
		[self.delegate accessibilityControlBarButtonTapped:LMAccessibilityControlButtonTypeToggleNowPlaying];
	}
	else if(accessibilityButton == self.playPauseButton){
		[self.musicPlayer invertPlaybackState];
	}
	else if(accessibilityButton == self.previousTrackButton){
		[self.musicPlayer skipToPreviousTrack];
	}
	else if(accessibilityButton == self.nextTrackButton){
		[self.musicPlayer skipToNextTrack];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.isAccessibilityElement = NO;
		self.userInteractionEnabled = YES;
		self.backgroundColor = [UIColor clearColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		
		
		self.containerView = [UIView newAutoLayoutView];
		self.containerView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.containerView];
		
		NSInteger padding = 20;
		
		[self.containerView autoCentreInSuperview];
		[self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-padding];
		[self.containerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:-padding];
		
		
		self.previousTrackButton = [LMAccessibilityButton newAutoLayoutView];
		self.previousTrackButton.icon = [LMAppIcon imageForIcon:LMIconiOSBack];
		self.previousTrackButton.delegate = self;
		self.previousTrackButton.isAccessibilityElement = YES;
		self.previousTrackButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_PreviousTrack", nil);
		self.previousTrackButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_PreviousTrack", nil);
		[self.containerView addSubview:self.previousTrackButton];
		
		[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.previousTrackButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		
		
		self.expandMinimizeButton = [LMAccessibilityButton newAutoLayoutView];
		self.expandMinimizeButton.icon = [LMAppIcon imageForIcon:LMIconMinimize];
		self.expandMinimizeButton.delegate = self;
		self.expandMinimizeButton.isAccessibilityElement = YES;
		self.expandMinimizeButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_CloseNowPlaying", nil);
		self.expandMinimizeButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_CloseNowPlaying", nil);
		[self.containerView addSubview:self.expandMinimizeButton];
		
		[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.expandMinimizeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		
		
		self.nextTrackButton = [LMAccessibilityButton newAutoLayoutView];
		self.nextTrackButton.icon = [LMAppIcon imageForIcon:LMIconForwardArrow inverted:YES];
		self.nextTrackButton.delegate = self;
		self.nextTrackButton.isAccessibilityElement = YES;
		self.nextTrackButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_NextTrack", nil);
		self.nextTrackButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_NextTrack", nil);
		[self.containerView addSubview:self.nextTrackButton];
		
		[self.nextTrackButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.expandMinimizeButton withOffset:-(padding/2.0)];
		[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.nextTrackButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		
		
		self.playPauseButton = [LMAccessibilityButton newAutoLayoutView];
		self.playPauseButton.icon = [LMAppIcon imageForIcon:LMIconPlay];
		self.playPauseButton.delegate = self;
		self.playPauseButton.isAccessibilityElement = YES;
		[self updatePlayPauseButton];
		[self.containerView addSubview:self.playPauseButton];
		
		[self.playPauseButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.previousTrackButton withOffset:(padding/2.0)];
		[self.playPauseButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.nextTrackButton withOffset:-(padding/2.0)];
		[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}
}

@end
