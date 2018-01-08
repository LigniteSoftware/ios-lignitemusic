//
//  LMExpandableTrackListControlBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableTrackListControlBar.h"
#import "LMLayoutManager.h"
#import "LMListEntry.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMColour.h"

@interface LMExpandableTrackListControlBar()<LMControlBarViewDelegate, LMMusicPlayerDelegate, LMListEntryDelegate>

/**
 The background view for the close button.
 */
@property UIView *closeButtonBackgroundView;

/**
 The image view for the close button (X symbol).
 */
@property UIImageView *closeButtonImageView;

/**
 The background view for the back button.
 */
@property UIView *backButtonBackgroundView;

/**
 The image view for the back button (< symbol).
 */
@property UIImageView *backButtonImageView;

/**
 The system music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 A list entry for the specific album header since it already has the perfect layout for it.
 */
@property LMListEntry *specificAlbumHeader;

@end

@implementation LMExpandableTrackListControlBar

@synthesize mode = _mode;

BOOL expandableTrackListControlBarIsInAlbumDetail = NO;

- (void)tappedListEntry:(LMListEntry*)entry{
	//Do nothing
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [UIColor clearColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	return self.musicTrackCollection.representativeItem.albumTitle;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	return self.musicTrackCollection.representativeItem.artist;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return self.musicTrackCollection.representativeItem.albumArt;
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self.musicControlBar reloadHighlightedButtons];
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self.musicControlBar reloadHighlightedButtons];
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	[self.musicControlBar reloadHighlightedButtons];
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
		case 1: { //Repeat button
			if(wasJustTapped){
				(self.musicPlayer.repeatMode == LMMusicRepeatModeAll)
				? (self.musicPlayer.repeatMode = LMMusicRepeatModeNone)
				: (self.musicPlayer.repeatMode = LMMusicRepeatModeAll);
			}
			
			return (self.musicPlayer.repeatMode == LMMusicRepeatModeAll);
		}
		case 2: { //Shuffle button
			if(wasJustTapped){
				self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
				
				LMMusicTrackCollection *trackCollection = self.musicTrackCollection;
				if(trackCollection.trackCount > 0){
					self.musicPlayer.autoPlay = YES;
					[self.musicPlayer setNowPlayingCollection:trackCollection];
					
					[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
					[self.musicPlayer.navigationBar maximize:NO];
					
					isPlayingMusic = YES;
				}
			}
			
			return (self.musicPlayer.shuffleMode == LMMusicShuffleModeOn);
		}
//		case 1: //Repeat button
//			if(wasJustTapped){
//				(self.musicPlayer.repeatMode == LMMusicRepeatModeAll)
//				? (self.musicPlayer.repeatMode = LMMusicRepeatModeNone)
//				: (self.musicPlayer.repeatMode = LMMusicRepeatModeAll);
//			}
//			NSLog(@"Repeat mode is %d", self.musicPlayer.repeatMode);
//			return (self.musicPlayer.repeatMode == LMMusicRepeatModeAll);
//		case 2: //Shuffle button
//			if(wasJustTapped){
//				self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
//			}
//			NSLog(@"Shuffle mode is %d", self.musicPlayer.shuffleMode);
//			return (self.musicPlayer.shuffleMode == LMMusicShuffleModeOn);
	}
	return YES;
}


+ (CGFloat)recommendedHeight {
	if([LMLayoutManager isiPad]){
		return ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/8.1;
	}
	return (([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/6.0);
}


- (void)reloadConstraints {
	[NSLayoutConstraint deactivateConstraints:self.constraints];
	
	
	[self autoSetDimension:ALDimensionHeight toSize:[LMExpandableTrackListControlBar recommendedHeight]];
	
	[self.closeButtonBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.closeButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.closeButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	[self.closeButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
	
	[self.closeButtonImageView autoCentreInSuperview];
	[self.closeButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/3.0)];
	[self.closeButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/3.0)];
	
	[self.backButtonImageView autoCentreInSuperview];
	[self.backButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/2.5)];
	[self.backButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.closeButtonBackgroundView withMultiplier:(1.0/2.5)];
	

	if([LMLayoutManager isiPad]){
		switch(self.mode){
			case LMExpandableTrackListControlBarModeGeneralControl: {
				
				
				[self.specificAlbumHeader autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self];
				[self.specificAlbumHeader autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.specificAlbumHeader autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(4.0/10.0)];
				[self.specificAlbumHeader autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.backButtonBackgroundView];
				[self.specificAlbumHeader autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.backButtonBackgroundView];
				
				
				[self.backButtonBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self withOffset:-10];
				[self.backButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
				

				[self.musicControlBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.musicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.0/10.0)];
				[self.musicControlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(4.0/10.0)];
				[self.musicControlBar autoPinEdgeToSuperviewMargin:ALEdgeLeading].constant = 10;
				
				
				break;
			}
			case LMExpandableTrackListControlBarModeControlWithAlbumDetail: {

				
				[self.backButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[self.backButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
				
				
				[self.specificAlbumHeader autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.backButtonBackgroundView];
				[self.specificAlbumHeader autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.specificAlbumHeader autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.musicControlBar withOffset:5];
				[self.specificAlbumHeader autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.backButtonBackgroundView withOffset:10];
				[self.specificAlbumHeader autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.backButtonBackgroundView withOffset:-10];
				
				
				[self.musicControlBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.musicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.0/10.0)];
				[self.musicControlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(4.0/10.0)];
				[self.musicControlBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.closeButtonImageView withOffset:-10];
				
				
//				NSLog(@"What");
				break;
			}
		}
	}
	else{
		switch(self.mode){
			case LMExpandableTrackListControlBarModeGeneralControl: {
				
				
				[self.backButtonBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self withOffset:-10];
				[self.backButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
				
				
				[self.musicControlBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.musicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.0/10.0)];
				[self.musicControlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(4.0/10.0)];
				[self.musicControlBar autoPinEdgeToSuperviewMargin:ALEdgeLeading].constant = 10;
				
				
				break;
			}
			case LMExpandableTrackListControlBarModeControlWithAlbumDetail: {
		
				
				[self.backButtonBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
				[self.backButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
				[self.backButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
				
				
				[self.musicControlBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.backButtonBackgroundView];
				[self.musicControlBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.closeButtonBackgroundView];
				[self.musicControlBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.closeButtonBackgroundView];
				[self.musicControlBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.closeButtonBackgroundView];
				[self.musicControlBar autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
//				[self.musicControlBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.0/10.0)];
				
//				NSLog(@"What");
				break;
			}
		}
	}
}

- (LMExpandableTrackListControlBarMode)mode {
	return _mode;
}

- (void)setMode:(LMExpandableTrackListControlBarMode)mode {
	_mode = mode;
	
	expandableTrackListControlBarIsInAlbumDetail = (mode == LMExpandableTrackListControlBarModeControlWithAlbumDetail);
	
	if(self.didLayoutConstraints){
		[self layoutIfNeeded];
		
		[self reloadConstraints];
		
		[UIView animateWithDuration:0.25 animations:^{
			[self layoutIfNeeded];
		}];
	}
}

- (void)closeButtonTapped {
	NSLog(@"Close me");
	
	if([self.delegate respondsToSelector:@selector(closeButtonTappedForExpandableTrackListControlBar:)]){
		[self.delegate closeButtonTappedForExpandableTrackListControlBar:self];
	}
}

- (void)backButtonTapped {
	NSLog(@"Back me");
	
	self.mode = LMExpandableTrackListControlBarModeGeneralControl;
	
	if([self.delegate respondsToSelector:@selector(backButtonTappedForExpandableTrackListControlBar:)]){
		[self.delegate backButtonTappedForExpandableTrackListControlBar:self];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.backgroundColor = [LMColour controlBarGrayColour];
		
		
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
		
		
		self.backButtonBackgroundView = [UIView newAutoLayoutView];
		self.backButtonBackgroundView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.backButtonBackgroundView];
		
		UITapGestureRecognizer *backButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(backButtonTapped)];
		[self.backButtonBackgroundView addGestureRecognizer:backButtonTapGestureRecognizer];
		
		
		self.backButtonImageView = [UIImageView newAutoLayoutView];
		self.backButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backButtonImageView.backgroundColor = [UIColor clearColor];
		self.backButtonImageView.image = [LMAppIcon imageForIcon:LMIconiOSBack];
		[self.backButtonBackgroundView addSubview:self.backButtonImageView];
		
		
		self.specificAlbumHeader = [[LMListEntry alloc]initWithDelegate:self];
		self.specificAlbumHeader.collectionIndex = 0;
		self.specificAlbumHeader.iPromiseIWillHaveAnIconForYouSoon = YES;
		self.specificAlbumHeader.alignIconToLeft = YES;
		self.specificAlbumHeader.stretchAcrossWidth = YES;
		[self addSubview:self.specificAlbumHeader];
		
		
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
		
		expandableTrackListControlBarIsInAlbumDetail = NO;
	}
	return self;
}

@end
