//
//  LMPhoneLandscapeDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMVerticalControlBarInnerShadowView.h"
#import "LMFloatingDetailViewButton.h"
#import "LMPhoneLandscapeDetailView.h"
#import "LMTiledAlbumCoverView.h"
#import "YIInnerShadowView.h"
#import "LMControlBarView.h"
#import "LMTriangleView.h"
#import "LMBigListEntry.h"
#import "LMMusicPlayer.h"
#import "LMColour.h"

@interface LMPhoneLandscapeDetailView()<LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMControlBarViewDelegate, LMMusicPlayerDelegate, LMFloatingDetailViewButtonDelegate>

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
 The control bar's inner shadow view.
 */
@property LMVerticalControlBarInnerShadowView *controlBarInnerShadowView;

/**
 The actual control bar.
 */
@property LMControlBarView *controlBar;

/**
 The shuffle button.
 */
@property LMFloatingDetailViewButton *shuffleButton;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMPhoneLandscapeDetailView

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
	return YES;
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	[self.controlBar reloadHighlightedButtons];
}

- (void)musicTrackDidChange:(LMMusicTrack*)newTrack {
	[self.controlBar reloadHighlightedButtons];
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	[self.controlBar reloadHighlightedButtons];
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(CGFloat)newHeight forBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Size changed");
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = self.musicTrackCollection;
	
	if(bigListEntry.contentView){
		switch(self.musicType){
			case LMMusicTypePlaylists:{
				UIImageView *rootImageView = bigListEntry.contentView;
				
				LMTiledAlbumCoverView *tiledAlbumCover = nil;
				for(UIView *subview in [rootImageView subviews]){
//					NSLog(@"Subview %@", [subview class]);
					if([subview class] == [LMTiledAlbumCoverView class]){
						tiledAlbumCover = (LMTiledAlbumCoverView*)subview;
					}
				}
				
				tiledAlbumCover.hidden = self.playlist.image ? YES : NO;
				
				if(self.playlist.image || (self.playlist.trackCollection.count == 0)){
					rootImageView.image = rootImageView.image;
					if(!self.playlist.image){
						rootImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
					}
				}
				else{
					tiledAlbumCover.musicCollection = collection;
				}
				
				return bigListEntry.contentView;
			}
			default: {
				
			}
		}
		return bigListEntry.contentView;
	}
	else{
		switch(self.musicType){
			case LMMusicTypeComposers:
			case LMMusicTypeArtists: {
				UIImageView *imageView = [UIImageView newAutoLayoutView];
				//			imageView.image = [[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem artistImage];
				imageView.contentMode = UIViewContentModeScaleAspectFit;
				imageView.layer.shadowColor = [UIColor blackColor].CGColor;
				imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
				imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
				imageView.layer.shadowOpacity = 0.25f;
				UIImage *artistImage = [collection.representativeItem artistImage];
				imageView.image = artistImage;
				return imageView;
			}
			case LMMusicTypePlaylists: {
				UIImageView *imageView = [UIImageView newAutoLayoutView];
				imageView.contentMode = UIViewContentModeScaleAspectFit;
				imageView.image = self.playlist.image ? self.playlist.image : [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
				
				imageView.layer.cornerRadius = 6.0f;
				imageView.layer.masksToBounds = YES;
				
				LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
				
				tiledAlbumCover.musicCollection = self.playlist.trackCollection;
				
				[imageView addSubview:tiledAlbumCover];
				
				[tiledAlbumCover autoPinEdgesToSuperviewEdges];
				
				tiledAlbumCover.hidden = self.playlist.image ? YES : NO;
				
				NSLog(@"Hidden %d", tiledAlbumCover.hidden);
				
				return imageView;
			}
			case LMMusicTypeAlbums:
			case LMMusicTypeCompilations:
			case LMMusicTypeGenres:{
				//No need for prep since we're just gonna prep once
				LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
				tiledAlbumCover.musicCollection = collection;
				return tiledAlbumCover;
			}
			default: {
				NSLog(@"Windows fucking error!");
				return nil;
			}
		}
	}
}

- (CGFloat)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return height ? 0.1 : 1.0;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	LMMusicTrackCollection *collection = self.musicTrackCollection;
	
	switch(self.musicType){
		case LMMusicTypeGenres: {
			return collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
		}
		case LMMusicTypeCompilations:{
			return [collection titleForMusicType:LMMusicTypeCompilations];
		}
		case LMMusicTypePlaylists:{
			return self.playlist.title;
		}
		case LMMusicTypeAlbums: {
			return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
		}
		case LMMusicTypeArtists: {
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		case LMMusicTypeComposers: {
			return collection.representativeItem.composer ? collection.representativeItem.composer : NSLocalizedString(@"UnknownComposer", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	LMMusicTrackCollection *collection = self.musicTrackCollection;
	
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
												  && self.musicType != LMMusicTypeCompilations
												  && self.musicType != LMMusicTypeAlbums);
			
			if(usingSpecificTrackCollections){
				//Fixes for compilations
				NSUInteger albums = [self.musicPlayer collectionsForRepresentativeTrack:collection.representativeItem
																		   forMusicType:self.musicType].count;
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)albums, NSLocalizedString(albums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
			else{
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
		{
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			if(collection.variousArtists){
				return NSLocalizedString(@"Various", nil);
			}
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default: {
			return nil;
		}
	}
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centreImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Tapped");
	
//	self.alpha = 0;
//	self.userInteractionEnabled = NO;
}

- (void)reloadContent {
	[self.collectionInfoBigListEntry reloadData];
	
	self.detailView.musicType = self.musicType;
	self.detailView.musicTrackCollection = self.musicTrackCollection;
	[self.detailView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
	
	[self.detailView setNeedsLayout];
	[self.detailView layoutIfNeeded];
	
	[self.controlBar reloadHighlightedButtons];
}

- (void)floatingDetailViewButtonTapped:(LMFloatingDetailViewButton*)button {
	LMMusicTrackCollection *collectionToUse = nil;
	if(self.detailView.showingAlbumTileView){
		collectionToUse = self.detailView.musicTrackCollection;
	}
	else if(!self.detailView.showingAlbumTileView && self.detailView.musicTrackCollectionToUseForSpecificTrackCollection){
		collectionToUse = self.detailView.musicTrackCollectionToUseForSpecificTrackCollection;
	}
	else if(!self.detailView.musicTrackCollectionToUseForSpecificTrackCollection){
		collectionToUse = self.detailView.musicTrackCollection;
	}
	
	LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	[musicPlayer stop];
	[musicPlayer setShuffleMode:LMMusicShuffleModeOn];
	[musicPlayer setNowPlayingCollection:collectionToUse];
	[musicPlayer play];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor whiteColor];
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		
		UIView *topAndBottomCoverView = [UIView newAutoLayoutView]; //For the animation of the album tiles so it doesn't show on the top and bottom of sidebar background view
		topAndBottomCoverView.backgroundColor = [UIColor whiteColor];
		[self addSubview:topAndBottomCoverView];
		
		
		self.sidebarBackgroundView = [UIView newAutoLayoutView];
		self.sidebarBackgroundView.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.sidebarBackgroundView];
		
		[self.sidebarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sidebarBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.sidebarBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.5/10.0)];
		[self.sidebarBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:[LMLayoutManager isiPhoneX] ? (1.0/5.25) : (1.0/4.40)];
		
		
		[topAndBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[topAndBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[topAndBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[topAndBottomCoverView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
		
		
		self.collectionInfoBigListEntry = [LMBigListEntry newAutoLayoutView];
		self.collectionInfoBigListEntry.infoDelegate = self;
		self.collectionInfoBigListEntry.entryDelegate = self;
		self.collectionInfoBigListEntry.collectionIndex = 0;
		[self.sidebarBackgroundView addSubview:self.collectionInfoBigListEntry];
		
		[self.collectionInfoBigListEntry autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.collectionInfoBigListEntry autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.collectionInfoBigListEntry autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sidebarBackgroundView withMultiplier:(8.0/10.0)];
		[self.collectionInfoBigListEntry autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sidebarBackgroundView withMultiplier:(4.5/10.0)];
		
//		[self.collectionInfoBigListEntry setup];
		
		
		LMFloatingDetailViewButton *button = [LMFloatingDetailViewButton newAutoLayoutView];
		button.type = LMFloatingDetailViewControlButtonTypeShuffle;
		button.delegate = self;
		[self.sidebarBackgroundView addSubview:button];
		
		[button autoAlignAxis:ALAxisVertical toSameAxisOfView:self.collectionInfoBigListEntry];
		[button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sidebarBackgroundView withMultiplier:(5.0/10.0)];
		[button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:button];
		[button autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoBigListEntry withOffset:14];
		
		
//		self.controlBarTriangle = [LMTriangleView newAutoLayoutView];
//		self.controlBarTriangle.maskDirection = LMTriangleMaskDirectionUpwards;
//		self.controlBarTriangle.clipsToBounds = NO;
//		self.controlBarTriangle.triangleColour = [LMColour verticalControlBarGreyColour];
//		[self.sidebarBackgroundView addSubview:self.controlBarTriangle];
//
//		[self.controlBarTriangle autoAlignAxisToSuperviewAxis:ALAxisVertical];
//		[self.controlBarTriangle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoBigListEntry];
//		[self.controlBarTriangle autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.collectionInfoBigListEntry withMultiplier:(1.0/4.5)];
//		[self.controlBarTriangle autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.controlBarTriangle withMultiplier:(5.0/8.0)];
//
//
//		self.controlBar = [LMControlBarView newAutoLayoutView];
//		self.controlBar.delegate = self;
//		self.controlBar.clipsToBounds = NO;
//		self.controlBar.verticalMode = YES;
//		[self.sidebarBackgroundView addSubview:self.controlBar];
//
//		[self.controlBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[self.controlBar autoAlignAxisToSuperviewAxis:ALAxisVertical];
//		[self.controlBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.collectionInfoBigListEntry];
//		[self.controlBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.controlBarTriangle];
//
//
//		self.controlBarInnerShadowView = [LMVerticalControlBarInnerShadowView newAutoLayoutView];
//		self.controlBarInnerShadowView.userInteractionEnabled = NO;
//		[self addSubview:self.controlBarInnerShadowView];
//
//		[self.controlBarInnerShadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.controlBar];
//		[self.controlBarInnerShadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.controlBar];
//		[self.controlBarInnerShadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.controlBar];
//		[self.controlBarInnerShadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.controlBar];
//
		
		self.detailView = [[LMDetailView alloc] initWithMusicTrackCollection:self.musicTrackCollection musicType:self.musicType];
		self.detailView.backgroundColor = [UIColor blueColor];
		self.detailView.flowLayout = self.flowLayout;
		[self addSubview:self.detailView];
		
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
//		[self.detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
		
		
		[self insertSubview:topAndBottomCoverView aboveSubview:self.detailView];
		[self insertSubview:self.sidebarBackgroundView aboveSubview:topAndBottomCoverView];
		
		
		[self.musicPlayer addMusicDelegate:self];
	}
}

@end
