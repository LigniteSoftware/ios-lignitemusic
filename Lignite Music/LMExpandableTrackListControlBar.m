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

@interface LMExpandableTrackListControlBar()<LMControlBarViewDelegate>

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

@end

@implementation LMExpandableTrackListControlBar

@synthesize mode = _mode;


- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView*)controlBar {
	return 3;
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar {
	switch(index){
		case 0:{
			BOOL isPlaying = YES; //[self.musicPlayer nowPlayingCollectionIsEqualTo:self.musicTrackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
			
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
	return NO;
}


+ (CGFloat)recommendedHeight {
	if([LMLayoutManager isiPad]){
		return ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/8.0;
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
		self.closeButtonImageView.image = [LMAppIcon imageForIcon:LMIconXCross];
		[self.closeButtonBackgroundView addSubview:self.closeButtonImageView];
		
		
		self.musicControlBar = [LMControlBarView newAutoLayoutView];
		self.musicControlBar.delegate = self;
		self.musicControlBar.backgroundColor = [UIColor blueColor];
		[self addSubview:self.musicControlBar];
		
		
		
		[self reloadConstraints];
	}
	
	[super layoutSubviews];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.mode = LMExpandableTrackListControlBarModeGeneralControl;
	}
	return self;
}

@end
