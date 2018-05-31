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
#import "LMTriangleView.h"
#import "LMBigListEntry.h"
#import "LMMusicPlayer.h"
#import "LMColour.h"

@interface LMPhoneLandscapeDetailView()<LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMFloatingDetailViewButtonDelegate>

/**
 The background view for the sidebar on the left which contains the control bar and collection info.
 */
@property UIView *sidebarBackgroundView;

/**
 The big list entry which shows info on the collection being displayed.
 */
@property LMBigListEntry *collectionInfoBigListEntry;

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
				
				tiledAlbumCover.hidden = (self.playlist.image || (self.playlist.trackCollection.count == 0)) ? YES : NO;
				
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
				
				imageView.contentMode = UIViewContentModeScaleAspectFit;
				imageView.layer.shadowColor = [UIColor blackColor].CGColor;
				imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
				imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
				imageView.layer.shadowOpacity = 0.25f;
				
				imageView.layer.masksToBounds = YES;
				imageView.layer.cornerRadius = 6.0f;
				
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
				
				tiledAlbumCover.hidden = (self.playlist.image || (self.playlist.trackCollection.count == 0)) ? YES : NO;
				
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
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = self.musicTrackCollection;
	
	NSString *titleString = @"";
	
	self.collectionInfoBigListEntry.isAccessibilityElement = YES;
	
	switch(self.musicType){
		case LMMusicTypeGenres: {
			titleString = collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
			break;
		}
		case LMMusicTypeCompilations:{
			titleString = [collection titleForMusicType:LMMusicTypeCompilations];
			break;
		}
		case LMMusicTypePlaylists:{
			titleString = self.playlist.title;
			break;
		}
		case LMMusicTypeAlbums: {
			titleString = collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
			break;
		}
		case LMMusicTypeArtists: {
			titleString = collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
			break;
		}
		case LMMusicTypeComposers: {
			titleString = collection.representativeItem.composer ? collection.representativeItem.composer : NSLocalizedString(@"UnknownComposer", nil);
			break;
		}
		default: {
			return nil;
		}
	}
	
	bigListEntry.isAccessibilityElement = YES;
	bigListEntry.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", titleString, [self leftTextForInfoView:infoView]];
//	bigListEntry.accessibilityHint = NSLocalizedString(@"VoiceOverHint_TapCompactViewEntry", nil);
	
	return titleString;
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
	if(self.musicTrackCollection.count > 0){
		[self.detailView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
	}
	
	[self.detailView setNeedsLayout];
	[self.detailView layoutIfNeeded];	
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
	[musicPlayer.queue setQueue:collectionToUse autoPlay:YES];
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
		[self.collectionInfoBigListEntry autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sidebarBackgroundView withMultiplier:(4.8/10.0)];
		
//		[self.collectionInfoBigListEntry setup];
		
		
		LMFloatingDetailViewButton *button = [LMFloatingDetailViewButton newAutoLayoutView];
		button.type = LMFloatingDetailViewControlButtonTypeShuffle;
		button.delegate = self;
		button.isAccessibilityElement = YES;
		button.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_DetailViewButtonShuffle", nil);
		button.accessibilityHint = NSLocalizedString(@"VoiceOverHint_DetailViewButtonShuffle", nil);
		[self.sidebarBackgroundView addSubview:button];
		
		[button autoAlignAxis:ALAxisVertical toSameAxisOfView:self.collectionInfoBigListEntry];
		[button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sidebarBackgroundView withMultiplier:(5.0/10.0)];
		[button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:button];
		[button autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoBigListEntry withOffset:14];

		
		self.detailView = [[LMDetailView alloc] initWithMusicTrackCollection:self.musicTrackCollection musicType:self.musicType];
//		self.detailView.backgroundColor = [UIColor blueColor];
		self.detailView.flowLayout = self.flowLayout;
		[self addSubview:self.detailView];
		
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sidebarBackgroundView];
		
		
		[self insertSubview:topAndBottomCoverView aboveSubview:self.detailView];
		[self insertSubview:self.sidebarBackgroundView aboveSubview:topAndBottomCoverView];
	}
}

@end
