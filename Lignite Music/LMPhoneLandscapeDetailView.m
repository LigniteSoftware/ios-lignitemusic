//
//  LMPhoneLandscapeDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMPhoneLandscapeDetailView.h"
#import "LMControlBarView.h"
#import "LMTriangleView.h"
#import "LMBigListEntry.h"
#import "LMDetailView.h"
#import "LMColour.h"

@interface LMPhoneLandscapeDetailView()<LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMControlBarViewDelegate>

/**
 The background view for the sidebar on the left which contains the control bar and collection info.
 */
@property UIView *sidebarBackgroundView;

/**
 The big list entry which shows info on the collection being displayed.
 */
@property LMBigListEntry *collectionInfoBigListEntry;

/**
 The background view for the control bar.
 */
@property UIView *controlBarBackgroundView;

/**
 The triangle for the control bar.
 */
@property LMTriangleView *controlBarTriangle;

/**
 The actual control bar.
 */
@property LMControlBarView *controlBar;

/**
 The actual detail view for displaying shit.
 */
@property LMDetailView *detailView;

@end

@implementation LMPhoneLandscapeDetailView

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView*)controlBar {
	return 3;
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar {
//	switch(index){
//		case 0:{
//			BOOL isPlaying = [self.musicPlayer nowPlayingCollectionIsEqualTo:self.musicTrackCollection] && self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying;
//			
//			return [LMAppIcon invertImage:[LMAppIcon imageForIcon:isPlaying ? LMIconPause : LMIconPlay]];
//		}
//		case 1:{
//			return [LMAppIcon imageForIcon:LMIconRepeat];
//		}
//		case 2:{
//			return [LMAppIcon imageForIcon:LMIconShuffle];
//		}
//	}
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView*)controlBar {
//	BOOL isPlayingMusic = (self.musicPlayer.playbackState == LMMusicPlaybackStatePlaying);
//	
//	switch(index) {
//		case 0:{ //Play button
//			LMMusicTrackCollection *trackCollection = self.musicTrackCollection;
//			if(wasJustTapped){
//				if(trackCollection.trackCount > 0){
//					if(![self.musicPlayer nowPlayingCollectionIsEqualTo:trackCollection]){
//						self.musicPlayer.autoPlay = YES;
//						[self.musicPlayer setNowPlayingCollection:trackCollection];
//						
//						[self.musicPlayer.navigationBar setSelectedTab:LMNavigationTabMiniplayer];
//						[self.musicPlayer.navigationBar maximize:NO];
//						
//						isPlayingMusic = YES;
//					}
//					else{
//						[self.musicPlayer invertPlaybackState];
//						isPlayingMusic = !isPlayingMusic;
//					}
//				}
//				return isPlayingMusic;
//			}
//			else{
//				return [self.musicPlayer nowPlayingCollectionIsEqualTo:trackCollection] && isPlayingMusic;
//			}
//		}
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
//	}
	return YES;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Size changed");
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	UIView *testview = [UIView newAutoLayoutView];
	testview.backgroundColor = [UIColor blueColor];
	return testview;
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return 1.0;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	return @"Title";
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"Left text";
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"Right test";
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Tapped");
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor orangeColor];
		
		
		self.sidebarBackgroundView = [UIView newAutoLayoutView];
		self.sidebarBackgroundView.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.sidebarBackgroundView];
		
		[self.sidebarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sidebarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sidebarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sidebarBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/4.75)];
		
		
		self.collectionInfoBigListEntry = [LMBigListEntry newAutoLayoutView];
		self.collectionInfoBigListEntry.infoDelegate = self;
		self.collectionInfoBigListEntry.entryDelegate = self;
		self.collectionInfoBigListEntry.collectionIndex = 0;
		self.collectionInfoBigListEntry.backgroundColor = [UIColor orangeColor];
		[self.sidebarBackgroundView addSubview:self.collectionInfoBigListEntry];
		
		[self.collectionInfoBigListEntry autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.collectionInfoBigListEntry autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.collectionInfoBigListEntry autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sidebarBackgroundView withMultiplier:(8.0/10.0)];
		[self.collectionInfoBigListEntry autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sidebarBackgroundView withMultiplier:(4.5/10.0)];
		
		[self.collectionInfoBigListEntry setup];
		
		
		self.controlBar = [LMControlBarView newAutoLayoutView];
		self.controlBar.delegate = self;
		self.controlBar.clipsToBounds = NO;
		[self.sidebarBackgroundView addSubview:self.controlBar];
		
		[self.controlBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.controlBar autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.controlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.collectionInfoBigListEntry];
		[self.controlBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoBigListEntry];
		
		
		self.controlBarTriangle = [LMTriangleView newAutoLayoutView];
		self.controlBarTriangle.maskDirection = LMTriangleMaskDirectionUpwards;
		self.controlBarTriangle.clipsToBounds = NO;
		[self.controlBar addSubview:self.controlBarTriangle];
		
		[self.controlBarTriangle autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.controlBarTriangle autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.controlBar];
		[self.controlBarTriangle autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.controlBar withMultiplier:(1.0/5.0)];
		[self.controlBarTriangle autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.controlBarTriangle withMultiplier:(3.0/4.0)];
		
		
		self.detailView = [[LMDetailView alloc] initWithMusicTrackCollection:self.musicTrackCollection musicType:self.musicType];
		self.detailView.backgroundColor = [UIColor blueColor];
		[self addSubview:self.detailView];
		
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
//		[self.detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
	}
}

@end
