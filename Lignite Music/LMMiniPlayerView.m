//
//  LMMiniPlayerView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAccessibilityMusicControlBar.h"
#import "LMMiniPlayerView.h"
#import "LMTrackInfoView.h"
#import "LMTrackDurationView.h"
#import "LMCoreViewController.h"
#import "LMOperationQueue.h"
#import "LMNowPlayingView.h"
#import "LMProgressSlider.h"
#import "NSTimer+Blocks.h"

@interface  LMMiniPlayerView()<LMMusicPlayerDelegate, LMProgressSliderDelegate, LMAccessibilityMusicControlBarDelegate, LMLayoutChangeDelegate, LMMusicQueueDelegate>

@property LMView *miniPlayerBackgroundView;

@property LMView *trackInfoAndDurationBackgroundView;
@property LMTrackInfoView *trackInfoView;
@property LMProgressSlider *progressSlider;

@property LMView *albumArtImageBackgroundView;
@property UIImageView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMMusicPlayer *musicPlayer;

@property NSLayoutConstraint *playerHeightConstraint;
@property NSLayoutConstraint *playerWidthConstraint;
@property NSLayoutConstraint *accessibilityBottomConstraint;
@property NSLayoutConstraint *accessibilityLeadingConstraint;

@property BOOL showingAccessibilityControls;

/**
 The actual container view which contains the contents of the mini player. Used for spacing on all edges.
 */
@property UIView *containerView;

/**
 The background view for the actual player. If the user has VoiceOver enabled, this will contain everything except the accessibility controls.
 */
@property UIView *playerBackgroundView;

/**
 The background view for the accessibility controls, which will only display if VoiceOver is enabled.
 */
@property UIView *accessibilityBackgroundView;

/**
 The control bar for accessibility controls.
 */
@property LMAccessibilityMusicControlBar *accessibilityMusicControlBar;

/**
 The view which goes above the coverart to display a text saying "Paused", when the music is no longer playing.
 */
@property UIView *pausedBackgroundBlurView;

/**
 Checks to make sure that the pause background view doesn't display in a flash and is constant. Lost?
 */
@property NSTimer *pausedTimer;

@end

@implementation LMMiniPlayerView

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
	long totalPlaybackTime = self.musicPlayer.nowPlayingTrack.playbackDuration;
	
	long currentHours = (currentPlaybackTime / 3600);
	long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
	int currentSeconds = (currentPlaybackTime % 60);
	
	long totalHours = (totalPlaybackTime / 3600);
	
	if(totalHours > 0){
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"LongSongDurationOfDuration", nil),
										 (int)currentHours, (int)currentMinutes, currentSeconds,
										 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
	else{
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"ShortSongDurationOfDuration", nil),
										 (int)currentMinutes, currentSeconds,
										 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self.progressSlider reload];
}

//- (void)trackMovedInQueue:(LMMusicTrack *)trackMoved {
//	[NSTimer scheduledTimerWithTimeInterval:0.3 block:^{
//		LMMiniPlayerCoreView *coreMiniPlayerView = (LMMiniPlayerCoreView*)self.coreMiniPlayerView;
//		[coreNowPlayingView musicTrackDidChange:nil];
//	} repeats:NO];
//}

- (void)reloadSongNumberText {
	self.progressSlider.leftText =
	[NSString stringWithFormat:NSLocalizedString(@"SongXofX", nil),
	 (int)self.musicPlayer.queue.displayIndexOfNowPlayingTrack,
	 (int)self.musicPlayer.queue.count];
}

- (void)reload {	
//	NSLog(@"ID is %@: %lld", self.musicPlayer.nowPlayingTrack.title, self.musicPlayer.nowPlayingTrack.persistentID);
	
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *titlesIcon = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
		UIImage *albumImage = noTrackPlaying ? titlesIcon : self.musicPlayer.nowPlayingTrack.albumArt;
		if(!albumImage){
			albumImage = titlesIcon;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.albumArtImageView.image = albumImage;
			
			operation = nil;
		});
	}];
	
	[self.queue addOperation:operation];
	
	if(noTrackPlaying){
		self.trackInfoView.titleText = NSLocalizedString(@"NoMusic", nil);
		self.trackInfoView.artistText = NSLocalizedString([LMLayoutManager isiPad] ? @"NoMusicDescriptionTablet" : @"NoMusicDescriptionPhone", nil);
		self.trackInfoView.albumText = @"";
		self.progressSlider.rightText = NSLocalizedString(@"BlankDuration", nil);
		self.progressSlider.leftText = NSLocalizedString(@"NoMusic", nil);
		return;
	}
	
	
	self.trackInfoView.titleText = self.musicPlayer.nowPlayingTrack.title ? self.musicPlayer.nowPlayingTrack.title : NSLocalizedString(@"UnknownTitle", nil);
	self.trackInfoView.artistText = self.musicPlayer.nowPlayingTrack.artist ? self.musicPlayer.nowPlayingTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
	self.trackInfoView.albumText = self.musicPlayer.nowPlayingTrack.albumTitle ? self.musicPlayer.nowPlayingTrack.albumTitle : NSLocalizedString(@"UnknownAlbumTitle", nil);
	
	[self reloadSongNumberText];

	self.progressSlider.rightText = [LMNowPlayingView durationStringTotalPlaybackTime:self.musicPlayer.nowPlayingTrack.playbackDuration];
	[self updateSongDurationLabelWithPlaybackTime:0];
	[self.progressSlider resetToZero];
	
	self.pausedTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
	} repeats:NO];
}

- (void)queueChangedToShuffleMode:(LMMusicShuffleMode)shuffleMode {
	[self reloadSongNumberText];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	if(self.pausedTimer){
		[self.pausedTimer invalidate];
	}
	
	[UIView animateWithDuration:0.4 animations:^{
		CGFloat alphaToUse = (newState == LMMusicPlaybackStatePlaying) ? 0.0 : 1.0;
		
		if(!self.musicPlayer.nowPlayingTrack){
			alphaToUse = 0.0; //Hide it if there's no track playing
		}
		
		self.pausedBackgroundBlurView.alpha = alphaToUse;
	}];
}

- (void)progressSliderValueChanged:(CGFloat)newValue isFinal:(BOOL)isFinal {
	//NSLog(@"New value %f", newValue);
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	if(isFinal){
		[self.musicPlayer setCurrentPlaybackTime:newValue];
	}
	else{
		[self updateSongDurationLabelWithPlaybackTime:newValue];
	}
}

- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime userModified:(BOOL)userModified {
	if(self.progressSlider.userIsInteracting){
		return;
	}
	
	[self updateSongDurationLabelWithPlaybackTime:newPlaybackTime];
	
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.value = newPlaybackTime;
}

- (void)tappedMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer invertPlaybackState];
}

- (void)accessibilityControlBarButtonTapped:(LMAccessibilityControlButtonType)controlButtonType {
	switch(controlButtonType){
		case LMAccessibilityControlButtonTypeToggleNowPlaying: {
			LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
			[coreViewController launchNowPlayingFromTap];
			NSLog(@"Big boi");
			break;
		}
	}
}

- (void)setShowingAccessibilityControls:(BOOL)showingAccessibilityControls animated:(BOOL)animated {
	self.showingAccessibilityControls = showingAccessibilityControls;
	
	if(!self.accessibilityMusicControlBar){
		self.accessibilityMusicControlBar = [LMAccessibilityMusicControlBar newAutoLayoutView];
		self.accessibilityMusicControlBar.delegate = self;
		self.accessibilityMusicControlBar.isMiniPlayer = YES;
		[self.accessibilityBackgroundView addSubview:self.accessibilityMusicControlBar];
		
		NSArray *accessibilityMusicControlBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.accessibilityMusicControlBar autoCentreInSuperview];
			[self.accessibilityMusicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.accessibilityBackgroundView withMultiplier:(10.0/10.0)];
			[self.accessibilityMusicControlBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView];
			[self.accessibilityMusicControlBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.progressSlider];
		}];
		[LMLayoutManager addNewPortraitConstraints:accessibilityMusicControlBarPortraitConstraints];
		
		NSArray *accessibilityMusicControlBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.accessibilityMusicControlBar autoCentreInSuperview];
			[self.accessibilityMusicControlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.accessibilityBackgroundView withMultiplier:(10.0/10.0)];
			[self.accessibilityMusicControlBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.albumArtImageView];
			[self.accessibilityMusicControlBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.progressSlider];
		}];
		[LMLayoutManager addNewLandscapeConstraints:accessibilityMusicControlBarLandscapeConstraints];
		
		[self setShowingAccessibilityControls:showingAccessibilityControls animated:YES]; //Animate in the controls
	}
	else{
		[UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
			self.accessibilityMusicControlBar.alpha = showingAccessibilityControls ? 1.0 : 0.0;
		}];
	}
	
	[self reloadContainerSizes];
}

- (void)voiceOverStatusChanged:(BOOL)voiceOverEnabled {
	[self setShowingAccessibilityControls:voiceOverEnabled animated:YES];
}

- (void)reloadContainerSizes {
	if([LMLayoutManager isLandscape]){
		self.playerWidthConstraint.constant = self.containerView.frame.size.width * (self.showingAccessibilityControls ? (3.0/4.0) : (4.0/4.0));
		self.playerHeightConstraint.constant = self.containerView.frame.size.height;
	}
	else{
		self.playerHeightConstraint.constant = self.containerView.frame.size.height * (self.showingAccessibilityControls ? (2.0/3.0) : (4.0/4.0));
		self.playerWidthConstraint.constant = self.containerView.frame.size.width;
	}
	
	self.accessibilityBottomConstraint.constant = self.showingAccessibilityControls ? 12.0f : 0.0f;
	self.accessibilityLeadingConstraint.constant = self.showingAccessibilityControls ? -18.0f : 0.0f;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self.containerView layoutIfNeeded];
	}];
//	[self.containerView layoutIfNeeded];
//	[self layoutIfNeeded];
	
	[self.trackInfoView reload];
	[self.progressSlider reload];
	
//	NSLog(@"Layout %@ %@ %@", NSStringFromCGRect(self.containerView.frame), self.playerHeightConstraint, self.playerWidthConstraint);
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self reloadContainerSizes];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self reloadContainerSizes];
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;

		self.containerView = [UIView newAutoLayoutView];
	//	self.containerView.backgroundColor = [UIColor blueColor];
		[self addSubview:self.containerView];
		
		[[LMLayoutManager sharedLayoutManager] addDelegate:self];
		
		[self.musicPlayer.queue addDelegate:self];
		
		NSInteger padding = 24.0f;
		NSInteger landscapePadding = padding * 1.5;
		
		NSArray *containerViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.containerView autoCentreInSuperview];
			[self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-padding];
			[self.containerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:-padding];
		}];
		[LMLayoutManager addNewPortraitConstraints:containerViewPortraitConstraints];
		
		NSArray *containerViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.containerView autoCentreInSuperview];
			[self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-landscapePadding];
			[self.containerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withOffset:-landscapePadding];
		}];
		[LMLayoutManager addNewLandscapeConstraints:containerViewLandscapeConstraints];
		
		
		self.playerBackgroundView = [UIView newAutoLayoutView];
	//	self.playerBackgroundView.backgroundColor = [UIColor magentaColor];
		[self.containerView addSubview:self.playerBackgroundView];
		
		NSArray *playerBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playerBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.playerBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		}];
		[LMLayoutManager addNewPortraitConstraints:playerBackgroundViewPortraitConstraints];
		
		NSArray *playerBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playerBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.playerBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		}];
		[LMLayoutManager addNewLandscapeConstraints:playerBackgroundViewLandscapeConstraints];
		
		self.playerHeightConstraint = [self.playerBackgroundView autoSetDimension:ALDimensionHeight toSize:300];
		self.playerWidthConstraint = [self.playerBackgroundView autoSetDimension:ALDimensionWidth toSize:400];
		
	//	NSLog(@"Fuck %@", NSStringFromCGRect(self.frame));
		
	//	[self.playerBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView];
	//	[self.playerBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.containerView withMultiplier:(2.0/3.0)];
	//
	//	[self.playerBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:(3.0/4.0)];
		
		
		self.accessibilityBackgroundView = [UIView newAutoLayoutView];
		self.accessibilityBackgroundView.backgroundColor = [UIColor clearColor];
		[self.containerView addSubview:self.accessibilityBackgroundView];

		NSArray *accessibilityBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			self.accessibilityBottomConstraint = [self.accessibilityBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.playerBackgroundView withOffset:(padding / 2.0)];
		}];
		[LMLayoutManager addNewPortraitConstraints:accessibilityBackgroundViewPortraitConstraints];
		
		NSArray *accessibilityBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.accessibilityBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			self.accessibilityLeadingConstraint = [self.accessibilityBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.playerBackgroundView withOffset:-(landscapePadding / 2.0)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:accessibilityBackgroundViewLandscapeConstraints];
		
		
		
		
		
		
		self.albumArtImageBackgroundView = [LMView newAutoLayoutView];
	//	self.albumArtImageBackgroundView.backgroundColor = [UIColor purpleColor];
		[self.playerBackgroundView addSubview:self.albumArtImageBackgroundView];
		
		NSArray *albumArtImageBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.playerBackgroundView];
			[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.playerBackgroundView];
		}];
		[LMLayoutManager addNewPortraitConstraints:albumArtImageBackgroundViewPortraitConstraints];
		
		NSArray *albumArtImageBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.playerBackgroundView];
		}];
		[LMLayoutManager addNewLandscapeConstraints:albumArtImageBackgroundViewLandscapeConstraints];
		
		
		
		
		self.albumArtImageView = [UIImageView newAutoLayoutView];
		self.albumArtImageView.layer.masksToBounds = YES;
		self.albumArtImageView.layer.cornerRadius = 6.0f;
		self.albumArtImageView.isAccessibilityElement = YES;
		self.albumArtImageView.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_AlbumArt", nil);
		[self.albumArtImageBackgroundView addSubview:self.albumArtImageView];
		
		[self.albumArtImageView autoPinEdgesToSuperviewEdges];
		
		
		
		self.pausedBackgroundBlurView = [UIView newAutoLayoutView];
		self.pausedBackgroundBlurView.userInteractionEnabled = NO;
		self.pausedBackgroundBlurView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
		self.pausedBackgroundBlurView.alpha = 0.0;
		[self.albumArtImageView addSubview:self.pausedBackgroundBlurView];
		
		[self.pausedBackgroundBlurView autoPinEdgesToSuperviewEdges];
		
		UILabel *pausedLabel = [UILabel newAutoLayoutView];
		pausedLabel.text = NSLocalizedString(@"Paused", nil);
		pausedLabel.textColor = [UIColor whiteColor];
		pausedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
		pausedLabel.textAlignment = NSTextAlignmentCenter;
		pausedLabel.numberOfLines = 0;
		pausedLabel.isAccessibilityElement = NO;
		[self.pausedBackgroundBlurView addSubview:pausedLabel];
		
		[pausedLabel autoPinEdgesToSuperviewMargins];
		
		
		
		self.trackInfoAndDurationBackgroundView = [LMView newAutoLayoutView];
	//	self.trackInfoAndDurationBackgroundView.backgroundColor = [UIColor cyanColor];
		[self.playerBackgroundView addSubview:self.trackInfoAndDurationBackgroundView];
		
		NSArray *trackInfoAndDurationBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumArtImageBackgroundView withOffset:(padding / 2.0)];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.albumArtImageView];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.playerBackgroundView withOffset:-15];
		}];
		[LMLayoutManager addNewPortraitConstraints:trackInfoAndDurationBackgroundViewPortraitConstraints];
		
		NSArray *trackInfoAndDurationBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtImageView];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtImageBackgroundView withOffset:(landscapePadding / 2.0)];
			[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.playerBackgroundView];
		}];
		[LMLayoutManager addNewLandscapeConstraints:trackInfoAndDurationBackgroundViewLandscapeConstraints];
		
		
		
		self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
		self.trackInfoView.textAlignment = NSTextAlignmentLeft;
		self.trackInfoView.miniplayer = YES;
		[self.trackInfoAndDurationBackgroundView addSubview:self.trackInfoView];
		
		[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:1];
		[self.trackInfoView autoMatchDimension:ALDimensionHeight
								   toDimension:ALDimensionHeight
										ofView:self.trackInfoAndDurationBackgroundView
								withMultiplier:(6.5/10.0)];
		
		
		self.progressSlider = [LMProgressSlider newAutoLayoutView];
		self.progressSlider.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:0.25];
		self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
		self.progressSlider.delegate = self;
		self.progressSlider.value = self.musicPlayer.currentPlaybackTime;
		self.progressSlider.lightTheme = YES;
		[self.trackInfoAndDurationBackgroundView addSubview:self.progressSlider];
		
		
		NSArray *progressSliderPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView];
			[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView];
			[self.progressSlider autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
			[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.playerBackgroundView withMultiplier:(1.0/4.20)];
		}];
		[LMLayoutManager addNewPortraitConstraints:progressSliderPortraitConstraints];
		
		NSArray *progressSliderLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView];
			[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView];
			[self.progressSlider autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.playerBackgroundView];
			[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.playerBackgroundView withMultiplier:(1.0/13.0)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:progressSliderLandscapeConstraints];
		
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedMiniPlayer)];
		[self addGestureRecognizer:tapGesture];
		
		[self.musicPlayer addMusicDelegate:self];
		
		[self setShowingAccessibilityControls:UIAccessibilityIsVoiceOverRunning() animated:NO];
		
	//	NSLog(@"Setup miniplayer");
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			[self.progressSlider setValue:self.musicPlayer.currentPlaybackTime];
			[self progressSliderValueChanged:self.musicPlayer.currentPlaybackTime isFinal:NO];
			
			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
			
			[self reload];
		} repeats:NO];
	}
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Error creating mini player view!");
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
