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
		
		NSInteger padding = 24.0f;
		NSInteger landscapePadding = padding * 1.5;
		
//		NSArray *containerViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.containerView autoCentreInSuperview];
			[self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:self.isMiniPlayer ? 0.0f : -padding];
			[self.containerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:self.isMiniPlayer ? 0.0f : -padding];
//		}];
//		[LMLayoutManager addNewPortraitConstraints:containerViewPortraitConstraints];
		
//		if(self.isMiniPlayer){
//			NSArray *containerViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//				[self.containerView autoPinEdgesToSuperviewEdges];
////				[self.containerView autoCentreInSuperview];
////				[self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:self.isMiniPlayer ? 0.0f : -padding];
////				[self.containerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:self.isMiniPlayer ? 0.0f : -padding];
//			}];
//			[LMLayoutManager addNewLandscapeConstraints:containerViewLandscapeConstraints];
//		}
		
		
		self.previousTrackButton = [LMAccessibilityButton newAutoLayoutView];
		self.previousTrackButton.icon = [LMAppIcon imageForIcon:LMIconiOSBack];
		self.previousTrackButton.delegate = self;
		self.previousTrackButton.isMiniPlayer = self.isMiniPlayer;
		self.previousTrackButton.isAccessibilityElement = YES;
		self.previousTrackButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_PreviousTrack", nil);
		self.previousTrackButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_PreviousTrack", nil);
		[self.containerView addSubview:self.previousTrackButton];
		
		NSArray *previousTrackButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.previousTrackButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		}];
		[LMLayoutManager addNewPortraitConstraints:previousTrackButtonPortraitConstraints];
		
		NSArray *previousTrackButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.previousTrackButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.previousTrackButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.containerView];
		}];
		[LMLayoutManager addNewLandscapeConstraints:previousTrackButtonLandscapeConstraints];
		
		
		self.expandMinimizeButton = [LMAccessibilityButton newAutoLayoutView];
		self.expandMinimizeButton.icon = [LMAppIcon imageForIcon:self.isMiniPlayer ? LMIconMaximize : LMIconMinimize];
		self.expandMinimizeButton.delegate = self;
		self.expandMinimizeButton.isMiniPlayer = self.isMiniPlayer;
		self.expandMinimizeButton.isAccessibilityElement = YES;
		self.expandMinimizeButton.accessibilityLabel = NSLocalizedString(self.isMiniPlayer ? @"VoiceOverLabel_OpenNowPlaying" : @"VoiceOverLabel_CloseNowPlaying", nil);
		self.expandMinimizeButton.accessibilityHint = NSLocalizedString(self.isMiniPlayer ? @"VoiceOverHint_OpenNowPlaying" : @"VoiceOverHint_CloseNowPlaying", nil);
		[self.containerView addSubview:self.expandMinimizeButton];
		
		NSArray *expandMinimizeButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.expandMinimizeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		}];
		[LMLayoutManager addNewPortraitConstraints:expandMinimizeButtonPortraitConstraints];
		
		NSArray *expandMinimizeButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.expandMinimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.expandMinimizeButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.containerView];
		}];
		[LMLayoutManager addNewLandscapeConstraints:expandMinimizeButtonLandscapeConstraints];
		
		
		self.nextTrackButton = [LMAccessibilityButton newAutoLayoutView];
		self.nextTrackButton.icon = [LMAppIcon imageForIcon:LMIconForwardArrow inverted:YES];
		self.nextTrackButton.delegate = self;
		self.nextTrackButton.isMiniPlayer = self.isMiniPlayer;
		self.nextTrackButton.isAccessibilityElement = YES;
		self.nextTrackButton.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_NextTrack", nil);
		self.nextTrackButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_NextTrack", nil);
		[self.containerView addSubview:self.nextTrackButton];
		
		NSArray *nextTrackButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.nextTrackButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.expandMinimizeButton withOffset:-(padding/2.0)];
			[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.nextTrackButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.containerView];
		}];
		[LMLayoutManager addNewPortraitConstraints:nextTrackButtonPortraitConstraints];
		
		NSArray *nextTrackButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.nextTrackButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandMinimizeButton withOffset:(landscapePadding/2.0)];
			[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.nextTrackButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.nextTrackButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.containerView];
		}];
		[LMLayoutManager addNewLandscapeConstraints:nextTrackButtonLandscapeConstraints];
		
		
		self.playPauseButton = [LMAccessibilityButton newAutoLayoutView];
		self.playPauseButton.icon = [LMAppIcon imageForIcon:LMIconPlay];
		self.playPauseButton.delegate = self;
		self.playPauseButton.isMiniPlayer = self.isMiniPlayer;
		self.playPauseButton.isAccessibilityElement = YES;
		[self updatePlayPauseButton];
		[self.containerView addSubview:self.playPauseButton];
		
		NSArray *playPauseButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playPauseButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.previousTrackButton withOffset:(padding/2.0)];
			[self.playPauseButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.nextTrackButton withOffset:-(padding/2.0)];
			[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
		}];
		[LMLayoutManager addNewPortraitConstraints:playPauseButtonPortraitConstraints];
		
		NSArray *playPauseButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playPauseButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.previousTrackButton withOffset:-(landscapePadding/2.0)];
			[self.playPauseButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nextTrackButton withOffset:(landscapePadding/2.0)];
			[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		}];
		[LMLayoutManager addNewLandscapeConstraints:playPauseButtonLandscapeConstraints];
	}
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.isMiniPlayer = NO;
	}
	return self;
}

@end
