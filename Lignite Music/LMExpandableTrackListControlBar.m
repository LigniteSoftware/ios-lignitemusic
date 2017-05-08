//
//  LMExpandableTrackListControlBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableTrackListControlBar.h"
#import "LMControlBarView.h"
#import "LMLayoutManager.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMColour.h"

@interface LMExpandableTrackListControlBar()<LMControlBarViewDelegate, LMMusicPlayerDelegate>

/**
 The music control bar.
 */
@property LMControlBarView *musicControlBar;

/**
 The background view for the close button.
 */
@property UIView *closeButtonBackgroundView;

/**
 The image view for the close button (X symbol).
 */
@property UIImageView *closeButtonImageView;

/**
 The system music player.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMExpandableTrackListControlBar

@synthesize mode = _mode;


- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self.musicControlBar reloadHighlightedButtons];
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self.musicControlBar reloadHighlightedButtons];
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	[self.musicControlBar reloadHighlightedButtons];
}

- (void)musicLibraryDidChange {
//	[self closeButtonTapped];
}


- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView*)controlBar {
	return 3;
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar {
	switch(index){
		case 0:{
			BOOL isPlaying = [self.musicPlayer nowPlayingCollectionIsEqualTo:self.musicTrackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:isPlaying ? LMIconPause : LMIconPlay]];
		}
		case 1:{
			return [LMAppIcon imageForIcon:LMIconRepeat];
		}
		case 2:{
			return [LMAppIcon imageForIcon:LMIconShuffle];
		}
	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView*)controlBar {
	BOOL isPlayingMusic = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
	
	switch(index) {
		case 0:{ //Play button
			LMMusicTrackCollection *trackCollection = self.musicTrackCollection;
			if(wasJustTapped){
				if(trackCollection.trackCount > 0){
					if(![self.musicPlayer nowPlayingCollectionIsEqualTo:trackCollection]){
						self.musicPlayer.autoPlay = YES;
						[self.musicPlayer setNowPlayingCollection:trackCollection];
						
						[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
						[self.musicPlayer.navigationBar maximize:NO];
						
						isPlayingMusic = YES;
					}
					else{
						[self.musicPlayer invertPlaybackState];
						isPlayingMusic = !isPlayingMusic;
					}
				}
				return isPlayingMusic;
			}
			else{
				return [self.musicPlayer nowPlayingCollectionIsEqualTo:trackCollection] && isPlayingMusic;
			}
		}
		case 1: //Repeat button
			if(wasJustTapped){
				(self.musicPlayer.repeatMode == LMMusicRepeatModeAll)
				? (self.musicPlayer.repeatMode = LMMusicRepeatModeNone)
				: (self.musicPlayer.repeatMode = LMMusicRepeatModeAll);
			}
			NSLog(@"Repeat mode is %d", self.musicPlayer.repeatMode);
			return (self.musicPlayer.repeatMode == LMMusicRepeatModeAll);
		case 2: //Shuffle button
			if(wasJustTapped){
				self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
			}
			NSLog(@"Shuffle mode is %d", self.musicPlayer.shuffleMode);
			return (self.musicPlayer.shuffleMode == LMMusicShuffleModeOn);
	}
	return YES;
}


+ (CGFloat)recommendedHeight {
	if([LMLayoutManager isiPad]){
		return ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/8.0;
	}
	return ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/6.0;
}


- (void)reloadConstraints {
	[NSLayoutConstraint deactivateConstraints:self.constraints];
	
	
	[self autoSetDimension:ALDimensionHeight toSize:[LMExpandableTrackListControlBar recommendedHeight]];
	
	
	[self.closeButtonImageView autoCenterInSuperview];
	[self.closeButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/3.0)];
	[self.closeButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/3.0)];
	
	
	[self.closeButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.closeButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	[self.closeButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
	
	
	[self.musicControlBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.musicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(7.5/10.0)];
	[self.musicControlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(3.5/10.0)];

	
	switch(self.mode){
		case LMExpandableTrackListControlBarModeGeneralControl: {

			
			[self.closeButtonBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
			
			
			[self.musicControlBar autoPinEdgeToSuperviewMargin:ALEdgeLeading].constant = 10;
			
			
			break;
		}
		case LMExpandableTrackListControlBarModeControlWithAlbumDetail: {
			
			
			[self.musicControlBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.closeButtonImageView withOffset:0];
			
			
			NSLog(@"What");
			break;
		}
	}
}

- (LMExpandableTrackListControlBarMode)mode {
	return _mode;
}

- (void)setMode:(LMExpandableTrackListControlBarMode)mode {
	_mode = mode;
	
	if(self.didLayoutConstraints){
		[UIView animateWithDuration:0.5 animations:^{
			[self reloadConstraints];
		}];
	}
}

- (void)closeButtonTapped {
	NSLog(@"Close me");
	
	if([self.delegate respondsToSelector:@selector(closeButtonTappedForExpandableTrackListControlBar:)]){
		[self.delegate closeButtonTappedForExpandableTrackListControlBar:self];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.backgroundColor = [LMColour lightGrayBackgroundColour];
		
		
		self.closeButtonBackgroundView = [UIView newAutoLayoutView];
		self.closeButtonBackgroundView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.closeButtonBackgroundView];
		
		UITapGestureRecognizer *closeButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeButtonTapped)];
		[self.closeButtonBackgroundView addGestureRecognizer:closeButtonTapGestureRecognizer];
		
		
		self.closeButtonImageView = [UIImageView newAutoLayoutView];
		self.closeButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.closeButtonImageView.backgroundColor = [UIColor clearColor];
		self.closeButtonImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconXCross]];
		[self.closeButtonBackgroundView addSubview:self.closeButtonImageView];
		
		
		self.musicControlBar = [LMControlBarView newAutoLayoutView];
		self.musicControlBar.delegate = self;
		[self addSubview:self.musicControlBar];
		
		
		[self.musicPlayer addMusicDelegate:self];
		
		
		[self reloadConstraints];
	}
	
	[super layoutSubviews];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.mode = LMExpandableTrackListControlBarModeGeneralControl;
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	return self;
}

@end
