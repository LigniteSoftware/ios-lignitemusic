//
//  LMCompactBrowsingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTiledAlbumCoverView.h"
#import "LMCompactBrowsingView.h"
#import "LMLayoutManager.h"
#import "LMBigListEntry.h"
#import "LMAppIcon.h"
#import "LMCollectionViewFlowLayout.h"
#import "LMCollectionViewCell.h"
#import "LMEmbeddedDetailView.h"
#import "LMPhoneLandscapeDetailView.h"
#import "LMRestorableNavigationController.h"
#import "LMThemeEngine.h"
#import "LMCoreViewController.h"

#import "NSTimer+Blocks.h"
#import "LMColour.h"

#import "LMPlaylistManager.h"

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate> //LMEnhancedPlaylistEditorDelegate and LMPlaylistEditorDelegate are defined in the associated .h file.

/**
 The big list entries that are used in the compact view.
 */
@property NSMutableArray *bigListEntries;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The last point in scrolling where the user stopped scrolling.
 */
@property CGPoint lastScrollingOffsetPoint;

/**
 Whether or not the scrolling that the user did broke the treshhold for minimizing the bottom button bar.
 */
@property BOOL brokeScrollingThreshhold;

/**
 If YES, the user just scrolled through the letter tabs. Scroll delegate should then be ignored and this flag should be reset to NO.
 */
@property BOOL didJustScrollByLetter;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The phone's landscape detail view (I hate this issue).
 */
@property LMPhoneLandscapeDetailView *phoneLandscapeDetailView;

/**
 The playlist manager.
 */
@property LMPlaylistManager *playlistManager;

/**
 The view containing the playlist modification and creation buttons.
 */
@property UIView *playlistModificationButtonView;

//The playlist background view is defined in the h file

/**
 The height constraint for the playlist modification button.
 */
@property NSLayoutConstraint *playlistModificationButtonViewHeightConstraint;

/**
 The button that goes on the left of the two buttons for playlist creation and modification.
 */
@property UIView *playlistButtonLeft;

/**
 The button that goes on the right of the two buttons for playlist creation and modification.
 */
@property UIView *playlistButtonRight;

/**
 The core view controller.
 */
@property (readonly) LMCoreViewController *coreViewController;

/**
 For when there's no entries.
 */
@property UILabel *noObjectsLabel;


/**
 The constraints for hotswapping the landscape/portrait collection view top constraints on iPhone since for some reason the layout manager throws EXC_BAD_ACCESS.
 */
@property NSLayoutConstraint *collectionViewTopPortraitConstraint;
@property NSLayoutConstraint *collectionViewTopLandscapeConstraint;

@end

@implementation LMCompactBrowsingView

@synthesize musicType = _musicType;
@synthesize coreViewController = _coreViewController;

- (LMCoreViewController*)coreViewController {
	return (LMCoreViewController*)self.rootViewController;
}

- (void)reloadDataAndInvalidateLayouts {
	[self.collectionView reloadData];
	[self.collectionView.collectionViewLayout invalidateLayout];
}

- (LMMusicType)musicType {
	return _musicType;
}

- (void)setMusicType:(LMMusicType)musicType {
	_musicType = musicType;
	
	if(!self.collectionView || !self.collectionView.collectionViewLayout){
		NSLog(@"Wait");
	}
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	flowLayout.musicType = musicType;
}

- (void)scrollViewToIndex:(NSUInteger)index {
    self.didJustScrollByLetter = YES;
	[self layoutIfNeeded];
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}

- (NSInteger)scrollToItemWithPersistentID:(LMMusicTrackPersistentID)persistentID {
	NSInteger index = -1;
	
	if(self.musicType == LMMusicTypePlaylists){
		LMPlaylistManager *playlistManager = [LMPlaylistManager sharedPlaylistManager];
		
		NSArray<LMPlaylist*> *playlists = playlistManager.playlists;
		
		for(NSInteger i = 0; i < playlists.count; i++){
			LMPlaylist *playlist = [playlists objectAtIndex:i];
			if(playlist.persistentID == persistentID){
				index = i;
				break;
			}
		}
	}
	else{
		for(NSUInteger i = 0; i < self.musicTrackCollections.count; i++){
			LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:i];
			if(self.musicType == LMMusicTypePlaylists){
				trackCollection = [self.playlistManager.playlists objectAtIndex:i].trackCollection;
			}
			LMMusicTrack *representativeTrack = [trackCollection representativeItem];
			
			switch(self.musicType) {
				case LMMusicTypeAlbums:
					if(persistentID == representativeTrack.albumPersistentID){
						index = i;
					}
					break;
				case LMMusicTypeArtists:
					if(persistentID == representativeTrack.artistPersistentID){
						index = i;
					}
					break;
				case LMMusicTypeComposers:
					if(persistentID == representativeTrack.composerPersistentID){
						index = i;
					}
					break;
				case LMMusicTypeGenres:
					if(persistentID == representativeTrack.genrePersistentID){
						index = i;
					}
					break;
				case LMMusicTypePlaylists:
					if(persistentID == trackCollection.persistentID){
						index = i;
					}
					break;
				case LMMusicTypeCompilations:
					if(persistentID == trackCollection.persistentID){
						index = i;
					}
					break;
				default:
					NSLog(@"Unsupported search result in browsing view.");
					break;
			}
			
			if(index != -1){
				break;
			}
		}
	}
	
	if(index == -1){
		NSLog(@"index not found :( (per. id %llu)", persistentID);
		index = 0;
	}
	
//	[self.bigListEntryTableView focusBigListEntryAtIndex:index];
	
	[self scrollViewToIndex:index];
	
	return index;
}

- (LMMusicTrackCollection*)musicTrackCollectionForBigListEntry:(LMBigListEntry*)bigListEntry {
	if(self.musicType == LMMusicTypePlaylists){
		LMPlaylist *playlist = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex];
		return playlist.trackCollection;
	}
	return [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = nil;
	
//	NSLog(@"biglist %d deview %d", (int)bigListEntry.collectionIndex, (int)self.indexOfCurrentlyOpenDetailView);
	
	LMPlaylist *playlist = nil;
	if(self.musicType == LMMusicTypePlaylists){
		playlist = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex];
		collection = playlist.trackCollection;
	}
	else {
		collection = [self musicTrackCollectionForBigListEntry:bigListEntry];
	}
	
    if(bigListEntry.contentView){
        switch(self.musicType){
            case LMMusicTypeComposers:
            case LMMusicTypeArtists: {
				UIView *shadowBackgroundView = bigListEntry.contentView;
				
				UIImageView *imageView = shadowBackgroundView.subviews.firstObject;
				
                UIImage *artistImage = [collection.representativeItem artistImage];
                imageView.image = artistImage;

				return shadowBackgroundView;
            }
			case LMMusicTypePlaylists:{
				UIImageView *rootImageView = [bigListEntry.contentView subviews].firstObject;
				
				LMTiledAlbumCoverView *tiledAlbumCover = nil;
				for(UIView *subview in [rootImageView subviews]){
//					NSLog(@"Subview %@", [subview class]);
					if([subview class] == [LMTiledAlbumCoverView class]){
						tiledAlbumCover = (LMTiledAlbumCoverView*)subview;
					}
				}
				
				tiledAlbumCover.hidden = (playlist.image || (playlist.trackCollection.count == 0)) ? YES : NO;
				
				if(playlist.image || (playlist.trackCollection.count == 0)){
					rootImageView.image = playlist.image;
					if(!playlist.image){
						rootImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
					}
				}
				else{
					tiledAlbumCover.musicCollection = collection;
				}
				
				return bigListEntry.contentView;
			}
            case LMMusicTypeAlbums:
            case LMMusicTypeCompilations:
            case LMMusicTypeGenres:{
                //No need for prep since we're just gonna prep once
				UIView *shadowView = bigListEntry.contentView;
				
                LMTiledAlbumCoverView *tiledAlbumCover = [shadowView subviews].firstObject;
                tiledAlbumCover.musicCollection = collection;
				
//				for(UIView *subview in shadowView.subviews){
//					NSLog(@"Subview %@", subview);
//				}
				
                return shadowView;
            }
            default: {
                NSLog(@"Windows fucking error!");
                return nil;
            }
        }
    }
    else{
        switch(self.musicType){
            case LMMusicTypeComposers:
            case LMMusicTypeArtists: {
				UIView *shadowBackgroundView = [UIView newAutoLayoutView];
				shadowBackgroundView.backgroundColor = [UIColor clearColor];
				shadowBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
				shadowBackgroundView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
				shadowBackgroundView.layer.shadowOffset = CGSizeMake(0, shadowBackgroundView.layer.shadowRadius/2);
				shadowBackgroundView.layer.shadowOpacity = 0.25f;
				
                UIImageView *imageView = [UIImageView newAutoLayoutView];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
				imageView.layer.cornerRadius = 6.0f;
				imageView.layer.masksToBounds = YES;
				imageView.image = [collection.representativeItem artistImage];
				
				[shadowBackgroundView addSubview:imageView];
				[imageView autoPinEdgesToSuperviewEdges];
				
                return shadowBackgroundView;
            }
			case LMMusicTypePlaylists: {
				UIView *shadowBackgroundView = [UIView newAutoLayoutView];
				shadowBackgroundView.backgroundColor = [UIColor clearColor];
				shadowBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
				shadowBackgroundView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
				shadowBackgroundView.layer.shadowOffset = CGSizeMake(0, shadowBackgroundView.layer.shadowRadius/2);
				shadowBackgroundView.layer.shadowOpacity = 0.25f;
				
				UIImageView *imageView = [UIImageView newAutoLayoutView];
				imageView.contentMode = UIViewContentModeScaleAspectFit;
				imageView.image = playlist.image ? playlist.image : [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
				
				imageView.layer.cornerRadius = 6.0f;
				imageView.layer.masksToBounds = YES;
				
				[shadowBackgroundView addSubview:imageView];
				[imageView autoPinEdgesToSuperviewEdges];
				
				LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
				
				[imageView addSubview:tiledAlbumCover];
				
				[tiledAlbumCover autoPinEdgesToSuperviewEdges];
				
				tiledAlbumCover.hidden = (playlist.image || (playlist.trackCollection.count == 0)) ? YES : NO;
				if(!tiledAlbumCover.hidden){
					tiledAlbumCover.musicCollection = playlist.trackCollection;
				}
				
				return shadowBackgroundView;
			}
            case LMMusicTypeAlbums:
            case LMMusicTypeCompilations:
            case LMMusicTypeGenres:{
				UIView *shadowBackgroundView = [UIView newAutoLayoutView];
				shadowBackgroundView.backgroundColor = [UIColor clearColor];
				shadowBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
				shadowBackgroundView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
				shadowBackgroundView.layer.shadowOffset = CGSizeMake(0, shadowBackgroundView.layer.shadowRadius/2);
				shadowBackgroundView.layer.shadowOpacity = 0.25f;
				
				//No need for prep since we're just gonna prep once
				LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView new];
				tiledAlbumCover.musicCollection = collection;
				
				[shadowBackgroundView addSubview:tiledAlbumCover];
				[tiledAlbumCover autoPinEdgesToSuperviewEdges];
				
                return shadowBackgroundView;
            }
            default: {
                NSLog(@"Windows fucking error!");
                return nil;
            }
        }
    }
}

- (CGFloat)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return height ? 0.1 : ([LMLayoutManager isExtraSmall] ? 0.9 : 1.0);
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(CGFloat)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
//	NSLog(@"%@ changed large", bigListEntry);
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = nil;
	
	if(self.musicType == LMMusicTypePlaylists){
		collection = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex].trackCollection;
	}
	else{
		collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	}
	
	switch(self.musicType){
		case LMMusicTypeGenres: {
			return collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
		}
		case LMMusicTypeCompilations:{
			return [collection titleForMusicType:LMMusicTypeCompilations];
		}
		case LMMusicTypePlaylists:{
			return [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex].title;
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
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = nil;
	
	if(self.musicType == LMMusicTypePlaylists){
		collection = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex].trackCollection;
	}
	else{
		collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	}
	
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
	NSLog(@"Tapped %ld", bigListEntry.collectionIndex);
	
//	LMBrowsingDetailView *browsingDetailView = [LMBrowsingDetailView newAutoLayoutView];
//	browsingDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
//	browsingDetailView.musicType = self.musicType;
//	browsingDetailView.coreViewController = self.coreViewController;
//	
//	NSLog(@"Got count %ld", browsingDetailView.musicTrackCollection.trackCount);
//	
//	self.browsingDetailViewController = [LMBrowsingDetailViewController new];
//	self.browsingDetailViewController.browsingDetailView = browsingDetailView;
//	
//	self.coreViewController.currentDetailViewController = self.browsingDetailViewController;
//	
//	[self.coreViewController showViewController:self.browsingDetailViewController sender:self.coreViewController];
	
//	[self tappedBigListEntryAtIndex:bigListEntry.collectionIndex];
	
	NSLog(@"Frame inside %@", NSStringFromCGRect(bigListEntry.superview.superview.frame));
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	BOOL shouldOpenNewDetailView = (bigListEntry.collectionIndex != flowLayout.indexOfItemDisplayingDetailView);
	BOOL detailViewNotCurrentlyOpen = (flowLayout.indexOfItemDisplayingDetailView == LMNoDetailViewSelected);
	
	flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
	
	if(shouldOpenNewDetailView){
		[NSTimer scheduledTimerWithTimeInterval:detailViewNotCurrentlyOpen ? 0.0 : 0.4 block:^{
			[UIView animateWithDuration:0.15 animations:^{
				CGFloat contentOffsetY = bigListEntry.superview.superview.frame.origin.y - 20;
				
				self.collectionView.contentOffset = CGPointMake(0, contentOffsetY);
				[self layoutIfNeeded];
			} completion:^(BOOL finished) {
				[self tappedBigListEntryAtIndex:bigListEntry.collectionIndex];
			}];
		} repeats:NO];
	}
}

- (void)contentViewDoubleTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	[self.musicPlayer stop];
	[self.musicPlayer setNowPlayingCollection:[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex]];
	[self.musicPlayer play];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//	return MIN(self.musicTrackCollections.count, 20);
	
	NSInteger fixedCount = self.musicType == LMMusicTypePlaylists ? self.playlistManager.playlists.count : self.musicTrackCollections.count;
	if(section == 1){ //When the section == 1, the amount of overflowing cells ie being checked so the raw amount of items in the compact view (before detail view) should be returned.
		return fixedCount;
	}

	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)collectionView.collectionViewLayout;
//	NSLog(@"isDisplayingDetailView: %d/fixedCount: %d/amountOfOverflowingCellsForDetailView: %d", flowLayout.isDisplayingDetailView, (int)fixedCount, (int)flowLayout.amountOfOverflowingCellsForDetailView);
	return flowLayout.isDisplayingDetailView ? (fixedCount + flowLayout.amountOfOverflowingCellsForDetailView + 1) : fixedCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	LMCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)collectionView.collectionViewLayout;
	
	cell.backgroundColor = [UIColor clearColor];

//	if(flowLayout.isDisplayingDetailView){
		for(UIView *subview in cell.contentView.subviews){
			[subview removeFromSuperview];
		}
//	}
	

	if(cell.contentView.subviews.count == 0){
		if(indexPath.row == flowLayout.indexOfDetailView){
			LMMusicTrackCollection *trackCollection = nil;
			if(self.musicType == LMMusicTypePlaylists){
				trackCollection = [self.playlistManager.playlists objectAtIndex:flowLayout.indexOfItemDisplayingDetailView].trackCollection;
			}
			else{
				trackCollection = [self.musicTrackCollections objectAtIndex:flowLayout.indexOfItemDisplayingDetailView];
			}
			
			flowLayout.amountOfItemsInDetailView = trackCollection.count;
			
			LMEmbeddedDetailView *detailView = flowLayout.detailView;
			[cell.contentView addSubview:detailView];
			
			[detailView autoPinEdgesToSuperviewEdges];
			
			
			NSLog(@"Shitttt dawg %@ %d %@ %@ %@", detailView.musicTrackCollection, (int)flowLayout.indexOfItemDisplayingDetailView, NSStringFromCGRect(self.frame), NSStringFromCGRect(cell.frame), NSStringFromCGRect(cell.contentView.frame));
		
			
			
//			[self.coreViewController.buttonNavigationBar minimize:YES];
		}
		else if(indexPath.row > [self collectionView:self.collectionView numberOfItemsInSection:1] && flowLayout.isDisplayingDetailView){
			cell.backgroundColor = [UIColor redColor];
			
			UILabel *pleaseReport = [UILabel newAutoLayoutView];
			pleaseReport.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f];
			pleaseReport.textColor = [UIColor whiteColor];
			pleaseReport.text = NSLocalizedString(@"InternalErrorOccurred_Long", nil);
			pleaseReport.numberOfLines = 0;
			[cell.contentView addSubview:pleaseReport];
			
			[pleaseReport autoPinEdgesToSuperviewMargins];
		}
		else{
			BOOL isBelowDetailViewRow = (indexPath.row > flowLayout.indexOfDetailView) && (flowLayout.indexOfDetailView > -1);
			
			LMBigListEntry *bigListEntry = [self.bigListEntries objectAtIndex:indexPath.row - isBelowDetailViewRow];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			[cell.contentView addSubview:bigListEntry];
			[bigListEntry autoPinEdgesToSuperviewEdges];
			[bigListEntry reloadData];
		}
	}
	
	return cell;
}

- (void)reloadContents {
	[self.collectionView removeFromSuperview];
	self.collectionView = nil;
	
	for(UIView *subview in self.bigListEntries){
		[subview removeFromSuperview];
	}
	
	self.didLayoutConstraints = NO;
	
	[self layoutIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if(self.didJustScrollByLetter){
		self.didJustScrollByLetter = NO;
		return;
	}
	
	self.coreViewController.buttonNavigationBar.currentlyScrolling = YES;
	
	CGFloat difference = fabs(scrollView.contentOffset.y-self.lastScrollingOffsetPoint.y);
	
	CGFloat maxContentOffset = scrollView.contentSize.height - (scrollView.frame.size.height*1.5);
	if(scrollView.contentOffset.y > maxContentOffset){
		return; //Don't scroll at the end to prevent weird scrolling behaviour with resize of required button bar height
	}
	
	if(difference > WINDOW_FRAME.size.height/4){
		self.brokeScrollingThreshhold = YES;
		if(!self.coreViewController.buttonNavigationBar.userMaximizedDuringScrollDeceleration){
			[self.coreViewController.buttonNavigationBar minimize:YES];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(self.brokeScrollingThreshhold){
		//[self.coreViewController.buttonNavigationBar minimize];
	}
	self.brokeScrollingThreshhold = NO;
	self.lastScrollingOffsetPoint = scrollView.contentOffset;
	
	NSLog(@"Finished dragging");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSLog(@"Ended decelerating");
	
	self.coreViewController.buttonNavigationBar.currentlyScrolling = NO;
	self.coreViewController.buttonNavigationBar.userMaximizedDuringScrollDeceleration = NO;
}

- (void)changeBottomSpacing:(CGFloat)bottomSpacing {
	NSLog(@"Setting bottom spacing %f", bottomSpacing);
    [UIView animateWithDuration:0.5 animations:^{
//		BOOL isPlaylists = self.musicType == LMMusicTypePlaylists;
//		NSInteger topInset = (isPlaylists && !self.layoutManager.isLandscape) ? 60 : (self.layoutManager.isLandscape ? 0 : 20);
//		if([LMLayoutManager isiPad] && isPlaylists){
//			topInset = 100;
//		}
//		else if([LMLayoutManager isiPhoneX] && isPlaylists){
//			topInset = self.layoutManager.isLandscape ? 0 : 80;
//		}
//       self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 100, 0);
    }];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	
	CGRect visibleRect = (CGRect){.origin = self.collectionView.contentOffset, .size = self.collectionView.bounds.size};
	CGPoint visiblePoint = CGPointMake(visibleRect.size.width/4.0, CGRectGetMidY(visibleRect));
	__strong NSIndexPath *visibleIndexPath = [self.collectionView indexPathForItemAtPoint:visiblePoint];
//	LMCollectionViewCell *topCell = visibleCells.count > 0 ? [visibleCells firstObject] : nil;
	
//	CGPoint offset = self.collectionView.contentOffset;
//	CGFloat height = self.collectionView.bounds.size.width;
//	
//	NSInteger index = round(offset.y / height);
//	index = index/2;
//	CGPoint newOffset = CGPointMake(0, index * size.height);
//	
//	[self.collectionView setContentOffset:newOffset animated:NO];
	
	__block BOOL transitioningFromLandscapeToPortrait = NO;
	__block BOOL transitioningFromPortraitToLandscape = NO;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		[self.collectionView scrollToItemAtIndexPath:visibleIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
		[self reloadDataAndInvalidateLayouts];
//		[self.collectionView setContentOffset:newOffset animated:NO];
		
		if(![LMLayoutManager isiPad]){
			LMCollectionViewFlowLayout *layout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
			
			if([self phoneLandscapeViewIsDisplaying] && !willBeLandscape){
				[self setPhoneLandscapeViewDisplaying:NO forIndex:-1];
				transitioningFromLandscapeToPortrait = YES;
			}
			else if(![self phoneLandscapeViewIsDisplaying] && willBeLandscape && ![LMLayoutManager isiPad] && layout.indexOfItemDisplayingDetailView > LMNoDetailViewSelected){
				[self setPhoneLandscapeViewDisplaying:YES forIndex:layout.indexOfItemDisplayingDetailView];
				self.indexOfCurrentlyOpenDetailView = layout.indexOfItemDisplayingDetailView;
				
				transitioningFromPortraitToLandscape = YES;
			}
		}
		
		BOOL isPlaylists = self.musicType == LMMusicTypePlaylists;
		
		self.collectionViewTopPortraitConstraint.active
		= (LMLayoutManager.isiPad
		   || (!LMLayoutManager.isLandscape && (self.musicType == LMMusicTypePlaylists)));
		
		self.collectionViewTopLandscapeConstraint.active = !self.collectionViewTopPortraitConstraint.active;
		
		self.playlistModificationButtonView.hidden = (isPlaylists && willBeLandscape) || !isPlaylists;
		if([LMLayoutManager isiPad] && isPlaylists){
			self.playlistModificationButtonView.hidden = NO;
		}
		self.playlistModificationButtonBackgroundView.hidden = self.playlistModificationButtonView.hidden;
//		NSInteger topInset = (isPlaylists && !self.layoutManager.isLandscape) ? 60 : (self.layoutManager.isLandscape ? 0 : 20);
//		if([LMLayoutManager isiPad] && isPlaylists){
//			topInset = 100;
//		}
//		else if([LMLayoutManager isiPhoneX] && isPlaylists){
//			topInset = self.layoutManager.isLandscape ? 0 : 80;
//		}
//		self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 100, 0);
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[UIView animateWithDuration:0.25 animations:^{
			
			NSLog(@"Scrolling to %@", visibleIndexPath);
			
			if(![LMLayoutManager isiPad]){
				LMCollectionViewFlowLayout *layout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
			
				if(transitioningFromPortraitToLandscape){
					layout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
				}
				else if(transitioningFromLandscapeToPortrait){
					[self tappedBigListEntryAtIndex:self.indexOfCurrentlyOpenDetailView];
				}
				else{
					[self reloadDataAndInvalidateLayouts];
					[self.collectionView scrollToItemAtIndexPath:visibleIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
				}
			}
//			[self.collectionView setContentOffset:CGPointMake(0, topCell.frame.origin.y - (COMPACT_VIEW_SPACING_BETWEEN_ITEMS/2)) animated:YES];
		}];
	}];
}

- (BOOL)phoneLandscapeViewIsDisplaying {
	return self.phoneLandscapeDetailView ? YES : NO;
}

- (void)setPhoneLandscapeViewDisplaying:(BOOL)displaying forIndex:(NSInteger)index {
	if([LMLayoutManager isiPad] || (!displaying && !self.phoneLandscapeDetailView)){
		return;
	}
	if(!self.phoneLandscapeDetailView){
		self.phoneLandscapeDetailView = [LMPhoneLandscapeDetailView newAutoLayoutView];
		self.phoneLandscapeDetailView.alpha = 0;
		[self addSubview:self.phoneLandscapeDetailView];
		
		[self.phoneLandscapeDetailView autoPinEdgesToSuperviewEdges];
	}
	
	self.phoneLandscapeDetailView.flowLayout = self.collectionView.collectionViewLayout;
	
	self.coreViewController.buttonNavigationBar.browsingBar.showingLetterTabs = !displaying;
	
	if(displaying){
		self.indexOfCurrentlyOpenDetailView = index;
		
		self.phoneLandscapeDetailView.index = index;
		self.phoneLandscapeDetailView.musicType = self.musicType;
		if(self.musicType == LMMusicTypePlaylists){
			LMPlaylist *playlist = [self.playlistManager.playlists objectAtIndex:index];
			self.phoneLandscapeDetailView.musicTrackCollection = playlist.trackCollection;
			self.phoneLandscapeDetailView.playlist = playlist;
		}
		else{
			self.phoneLandscapeDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:index];
		}
		
		[self.phoneLandscapeDetailView.detailView setShowingSpecificTrackCollection:NO animated:NO];
	}
	
	[UIView animateWithDuration:0.25 animations:^{
		self.phoneLandscapeDetailView.alpha = displaying;
		self.phoneLandscapeDetailView.userInteractionEnabled = displaying;
	} completion:^(BOOL finished) {
		if(!displaying){
			self.phoneLandscapeDetailView = nil;
		}
	}];
	
	self.coreViewController.landscapeNavigationBar.mode = displaying
	? LMLandscapeNavigationBarModeWithBackButton
	: (self.musicType == LMMusicTypePlaylists ? LMLandscapeNavigationBarModePlaylistView : LMLandscapeNavigationBarModeOnlyLogo);
	
	[self.phoneLandscapeDetailView reloadContent];
	
	NSLog(@"Displaying %d", displaying);
}

- (void)backButtonPressed {
	if(!self.phoneLandscapeDetailView.detailView.showingAlbumTileView && (self.musicType == LMMusicTypeArtists || self.musicType == LMMusicTypeGenres)){
		[self.phoneLandscapeDetailView.detailView setShowingSpecificTrackCollection:NO animated:YES];
	}
	else{
		[self setPhoneLandscapeViewDisplaying:NO forIndex:-1];
		
		self.indexOfCurrentlyOpenDetailView = -1;
	}
}

- (void)addPlaylistButtonTapped {	
	if(!self.playlistManager.userUnderstandsPlaylistCreation){
		[self.playlistManager launchPlaylistManagementWarningWithCompletionHandler:^{
			[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
				[self addPlaylistButtonTapped];
			} repeats:NO];
		}];
	}
	else{
		NSLog(@"New playlist");
		
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"WhichTypeOfPlaylist", nil)
																	   message:nil
																preferredStyle:UIAlertControllerStyleActionSheet];

		alert.popoverPresentationController.sourceView = self.playlistButtonLeft;
		alert.popoverPresentationController.sourceRect = self.playlistButtonLeft.frame;

		UIAlertAction* enhancedPlaylistAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"EnhancedPlaylist", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			NSLog(@"Enhanced playlist create");

			LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
			enhancedPlaylistViewController.delegate = self;
			
			LMRestorableNavigationController *navigation = [[LMRestorableNavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
			
			[self.coreViewController presentViewController:navigation animated:YES completion:^{
				NSLog(@"Launched enhanced creator");
			}];
		}];

		UIAlertAction* regularPlaylistAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"RegularPlaylist", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			NSLog(@"Regular playlist create");

			LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
			playlistViewController.delegate = self;
			
			LMRestorableNavigationController *navigation = [[LMRestorableNavigationController alloc] initWithRootViewController:playlistViewController];
			
			NSLog(@"Created %@", navigation);
			[self.coreViewController.navigationController presentViewController:navigation animated:YES completion:^{
				NSLog(@"Launched creator %@/%@/%@", self.coreViewController.navigationController.viewControllers, self.coreViewController.childViewControllers, self.coreViewController.presentedViewController);
				NSLog(@"Sweet");
			}];
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];

		[alert addAction:enhancedPlaylistAction];
		[alert addAction:regularPlaylistAction];
		[alert addAction:cancelAction];

		[self.coreViewController presentViewController:alert animated:YES completion:nil];
		
//		LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
//		playlistViewController.delegate = self;
//		UINavigationController *navigation = [[UINavigationController alloc] initWithcoreViewController:playlistViewController];
//		[self.coreViewController presentViewController:navigation animated:YES completion:^{
//			NSLog(@"Launched creator");
//		}];
	}
}

- (void)playlistEditorViewController:(LMPlaylistEditorViewController *)editorViewController didSaveWithPlaylist:(LMPlaylist *)playlist {
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	BOOL isNewPlaylist = flowLayout.musicTrackCollections.count != self.playlistManager.playlistTrackCollections.count;
	
	flowLayout.musicTrackCollections = self.playlistManager.playlistTrackCollections;
	
	if(isNewPlaylist){
		LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
		bigListEntry.infoDelegate = self;
		bigListEntry.entryDelegate = self;
		bigListEntry.collectionIndex = self.bigListEntries.count;
		
		[self.bigListEntries addObject:bigListEntry];
	}
	
	for(LMBigListEntry *bigListEntry in self.bigListEntries){
		[bigListEntry reloadData];
	}
	
	[self.collectionView reloadData];
}

- (void)enhancedPlaylistEditorViewController:(LMEnhancedPlaylistEditorViewController*)enhancedEditorViewController didSaveWithPlaylist:(LMPlaylist*)playlist {
	
	NSLog(@"Saved playlist");
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	BOOL isNewPlaylist = flowLayout.musicTrackCollections.count != self.playlistManager.playlistTrackCollections.count;
	
	flowLayout.musicTrackCollections = self.playlistManager.playlistTrackCollections;
	
	if(isNewPlaylist){
		LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
		bigListEntry.infoDelegate = self;
		bigListEntry.entryDelegate = self;
		bigListEntry.collectionIndex = self.bigListEntries.count;
		
		[self.bigListEntries addObject:bigListEntry];
	}
	
	for(LMBigListEntry *bigListEntry in self.bigListEntries){
		[bigListEntry reloadData];
	}
	
	[self.collectionView reloadData];
}

- (void)enhancedPlaylistEditorViewControllerDidCancel:(LMEnhancedPlaylistEditorViewController*)enhancedEditorViewController {
	NSLog(@"Cancelled enhanced");
}

- (void)editTappedForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMPlaylist *playlist = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex];
	
	if(playlist.systemPersistentID > 0){
		playlist.userPortedToLignitePlaylist = YES;
	}
	
	if(playlist.enhanced){
		LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
		enhancedPlaylistViewController.playlist = playlist;
		enhancedPlaylistViewController.delegate = self;
		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
		[self.coreViewController presentViewController:navigation animated:YES completion:^{
			NSLog(@"Launched enhanced editor");
		}];
	}
	else{
		LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
		playlistViewController.playlist = playlist;
		playlistViewController.delegate = self;
		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:playlistViewController];
		[self.coreViewController presentViewController:navigation animated:YES completion:^{
			NSLog(@"Launched editor");
		}];
	}
}

- (void)deleteTappedForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMPlaylist *playlist = [self.playlistManager.playlists objectAtIndex:bigListEntry.collectionIndex];
	
	UIAlertController *alert = [UIAlertController
								alertControllerWithTitle:NSLocalizedString(@"DeletePlaylistTitle", nil)
								message:[NSString stringWithFormat:NSLocalizedString(@"DeletePlaylistDescription", nil), playlist.title]
								preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *yesButton = [UIAlertAction
								actionWithTitle:NSLocalizedString(@"Delete", nil)
								style:UIAlertActionStyleDestructive
								handler:^(UIAlertAction *action) {
									[self.playlistManager deletePlaylist:playlist];
									
									LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
									
									flowLayout.musicTrackCollections = self.playlistManager.playlistTrackCollections;
									
									[self.bigListEntries removeLastObject];
									
									[self.collectionView reloadData];
								}];
	
	UIAlertAction *nopeButton = [UIAlertAction
								 actionWithTitle:NSLocalizedString(@"Cancel", nil)
								 style:UIAlertActionStyleCancel
								 handler:^(UIAlertAction *action) {
									 //Dismissed
								 }];
	
	[alert addAction:yesButton];
	[alert addAction:nopeButton];
	
	[self.coreViewController presentViewController:alert animated:YES completion:nil];
}

- (void)editPlaylistButtonTapped {
	if(!self.playlistManager.userUnderstandsPlaylistEditing){
		[self.playlistManager launchPlaylistEditingWarningWithCompletionHandler:^{
													[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
														[self editPlaylistButtonTapped];
													} repeats:NO];
												}];
		
		return;
	}
	
	NSLog(@"Edit playlist");
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
	
	for(LMBigListEntry *bigListEntry in self.bigListEntries){
		bigListEntry.editing = !bigListEntry.editing;
	}
	self.editing = !self.editing;
	
	[self.playlistModificationButtonView layoutIfNeeded];
	
	for(NSLayoutConstraint *constraint in self.playlistModificationButtonView.constraints){
		if(constraint.firstItem == self.playlistButtonRight){
			[self.playlistModificationButtonView removeConstraint:constraint];
		}
	}
	if(self.editing){
		[self.playlistButtonRight autoPinEdgesToSuperviewEdges];
	}
	else{
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.playlistButtonRight autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistModificationButtonView withMultiplier:(1.0/2.0)].constant = -1;
	}
	
	UIImageView *iconView = nil;
	UILabel *label = nil;
	UIView *backgroundView = [self.playlistButtonRight.subviews firstObject]; //The background view contains the icon and label
	
	for(id subview in backgroundView.subviews){
		if([subview class] == [UIImageView class]){
			iconView = subview;
		}
		else{
			label = subview;
		}
	}
	
	iconView.image = [LMAppIcon imageForIcon:self.editing ? LMIconWhiteCheckmark : LMIconEdit];
	label.text = NSLocalizedString(self.editing ? @"Done" : @"Edit", nil);
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.playlistModificationButtonView layoutIfNeeded];
	}];
	
	
	[self.coreViewController.landscapeNavigationBar setEditing:self.editing];
}

- (UIView *)roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(CGFloat)radius {
	
	if (tl || tr || bl || br) {
		UIRectCorner corner = 0;
		if (tl) {corner = corner | UIRectCornerTopLeft;}
		if (tr) {corner = corner | UIRectCornerTopRight;}
		if (bl) {corner = corner | UIRectCornerBottomLeft;}
		if (br) {corner = corner | UIRectCornerBottomRight;}
		
		UIView *roundedView = view;
		UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:roundedView.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = roundedView.bounds;
		maskLayer.path = maskPath.CGPath;
		roundedView.layer.mask = maskLayer;
		return roundedView;
	}
	return view;
}

- (void)themeChanged:(LMTheme)theme {
	self.playlistButtonLeft.backgroundColor = [LMColour mainColour];
	self.playlistButtonRight.backgroundColor = [LMColour mainColour];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		self.playlistManager = [LMPlaylistManager sharedPlaylistManager];
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		LMCollectionViewFlowLayout *fuck = [LMCollectionViewFlowLayout new];
		fuck.musicTrackCollections = self.musicTrackCollections;
		if(self.musicType == LMMusicTypePlaylists){
			fuck.musicTrackCollections = self.playlistManager.playlistTrackCollections;
		}
		fuck.musicType = self.musicType;
		fuck.compactView = self;
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
//		self.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
//		self.musicType = LMMusicTypeAlbums;
		
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.scrollEnabled = YES;
		
		//Force scrolling
		self.collectionView.alwaysBounceVertical = YES;
		self.collectionView.bounces = YES;
		
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		BOOL isPlaylists = (self.musicType == LMMusicTypePlaylists);
//		NSInteger topInset = (isPlaylists && !self.layoutManager.isLandscape) ? 60 : (self.layoutManager.isLandscape ? 0 : 20);
//		if([LMLayoutManager isiPad] && isPlaylists){
//			topInset = 100;
//		}
//		else if([LMLayoutManager isiPhoneX] && isPlaylists){
//			topInset = self.layoutManager.isLandscape ? 0 : 80;
//		}
//		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 150, 0);
		[self.collectionView registerClass:[LMCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		NSLog(@"Compact collection view %p", self.collectionView);
		
		
		self.bigListEntries = [NSMutableArray new];
		
		CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
		
		NSInteger amountOfItems = [self collectionView:self.collectionView numberOfItemsInSection:0];
		for(int i = 0; i < amountOfItems; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			bigListEntry.collectionIndex = i;
//			[bigListEntry setup];
			
			[self.bigListEntries addObject:bigListEntry];
		}
		
		CFTimeInterval endTime = CFAbsoluteTimeGetCurrent();
		CFTimeInterval amountOfTimeInSeconds = (endTime-startTime);
		NSLog(@"Took %f seconds to load %d items (~%fms per item).", amountOfTimeInSeconds, (int)amountOfItems, ((amountOfTimeInSeconds/(CGFloat)amountOfItems) * 1000));
		
		
		
		self.playlistModificationButtonBackgroundView = [UIView newAutoLayoutView];
		self.playlistModificationButtonBackgroundView.backgroundColor = [UIColor whiteColor];
		self.playlistModificationButtonBackgroundView.hidden = !(self.musicType == LMMusicTypePlaylists && !self.layoutManager.isLandscape);
		[self addSubview:self.playlistModificationButtonBackgroundView];
		
		[self.playlistModificationButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.playlistModificationButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.playlistModificationButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		self.playlistModificationButtonView = [UIView newAutoLayoutView];
		self.playlistModificationButtonView.backgroundColor = [UIColor whiteColor];
		self.playlistModificationButtonView.userInteractionEnabled = YES;
		self.playlistModificationButtonView.layer.masksToBounds = YES;
		self.playlistModificationButtonView.layer.cornerRadius = 8.0f;
		self.playlistModificationButtonView.hidden = !(self.musicType == LMMusicTypePlaylists && !self.layoutManager.isLandscape);
		[self addSubview:self.playlistModificationButtonView];
		
		NSArray *playlistModificationButtonViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
			[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:34];
			[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:34];
		}];
		[LMLayoutManager addNewPortraitConstraints:playlistModificationButtonViewPortraitConstraints];
		
		NSArray *playlistModificationButtonViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
			[self.playlistModificationButtonView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.playlistModificationButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/2.0)];
		}];
		[LMLayoutManager addNewiPadConstraints:playlistModificationButtonViewiPadConstraints];
		
		
		self.playlistModificationButtonViewHeightConstraint = [self.playlistModificationButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.125/1.80];
		
		[self.playlistModificationButtonBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.playlistModificationButtonView withOffset:15];
		
		
		self.playlistButtonLeft = [UIView newAutoLayoutView];
		self.playlistButtonLeft.backgroundColor = [LMColour mainColour];
		[self.playlistModificationButtonView addSubview:self.playlistButtonLeft];
		
		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.playlistButtonLeft autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistModificationButtonView withMultiplier:(1.0/2.0)].constant = -1;
		
		
		self.playlistButtonRight = [UIView newAutoLayoutView];
		self.playlistButtonRight.backgroundColor = [LMColour mainColour];
		[self.playlistModificationButtonView addSubview:self.playlistButtonRight];
		
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.playlistButtonRight autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.playlistButtonRight autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistModificationButtonView withMultiplier:(1.0/2.0)].constant = -1;
		
		
		UITapGestureRecognizer *addPlaylistButtonTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addPlaylistButtonTapped)];
		[self.playlistButtonLeft addGestureRecognizer:addPlaylistButtonTapGesture];
		
		UITapGestureRecognizer *editPlaylistsButtonTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(editPlaylistButtonTapped)];
		[self.playlistButtonRight addGestureRecognizer:editPlaylistsButtonTapGesture];
		
		NSArray *views = @[ self.playlistButtonLeft, self.playlistButtonRight ];
		NSArray *texts = @[ @"Create", @"Edit" ];
		NSArray *icons = @[ [LMAppIcon imageForIcon:LMIconAdd], [LMAppIcon imageForIcon:LMIconEdit] ];
		for(NSInteger i = 0; i < views.count; i++){
			UIView *view = [views objectAtIndex:i];
			NSString *text = NSLocalizedString([texts objectAtIndex:i], nil);
			UIImage *icon = [icons objectAtIndex:i];
			
			
			UIView *backgroundView = [UIView newAutoLayoutView];
			[view addSubview:backgroundView];
			
			[backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:view withMultiplier:(1.6/3.5)];
			[backgroundView autoCentreInSuperview];
			
			
			UIImageView *iconView = [UIImageView newAutoLayoutView];
			iconView.image = icon;
			iconView.contentMode = UIViewContentModeScaleAspectFit;
			[backgroundView addSubview:iconView];
			
			[iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[iconView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[iconView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:backgroundView];
			
			UILabel *labelView = [UILabel newAutoLayoutView];
			labelView.text = text;
			labelView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 14.0f : 18.0f];
			labelView.textColor = [UIColor whiteColor];
			[backgroundView addSubview:labelView];
			
			[labelView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:iconView withOffset:10.0f];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-5];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-5];
		}
		
				
		
		self.backgroundColor = [UIColor whiteColor];
		self.collectionView.backgroundColor = [UIColor whiteColor];
		
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		self.collectionViewTopPortraitConstraint
				= [self.collectionView autoPinEdge:ALEdgeTop
											toEdge:isPlaylists ? ALEdgeBottom : ALEdgeTop
											ofView:isPlaylists ? self.playlistModificationButtonBackgroundView : self];
		
		self.collectionViewTopLandscapeConstraint = [self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];

		self.collectionViewTopPortraitConstraint.active
			= (LMLayoutManager.isiPad
				   || (!LMLayoutManager.isLandscape && (self.musicType == LMMusicTypePlaylists)));
		
		self.collectionViewTopLandscapeConstraint.active = !self.collectionViewTopPortraitConstraint.active;
		
//		NSArray *collectionViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//			[self.collectionView autoPinEdge:ALEdgeTop
//									  toEdge:isPlaylists ? ALEdgeBottom : ALEdgeTop
//									  ofView:isPlaylists ? self.playlistModificationButtonBackgroundView : self];
//		}];
//		[LMLayoutManager addNewPortraitConstraints:collectionViewPortraitConstraints];
//
//		NSArray *collectionViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//			[self.collectionView autoPinEdge:ALEdgeTop
//									  toEdge:ALEdgeTop
//									  ofView:self];
//		}];
//		[LMLayoutManager addNewLandscapeConstraints:collectionViewLandscapeConstraints];
		
		
		self.noObjectsLabel = [UILabel newAutoLayoutView];
		self.noObjectsLabel.numberOfLines = 0;
		self.noObjectsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 16.0f : 18.0f];
		self.noObjectsLabel.text = NSLocalizedString(isPlaylists ? @"NoPlaylists" : @"TheresNothingHere", nil);
		self.noObjectsLabel.textAlignment = NSTextAlignmentLeft;
		[self addSubview:self.noObjectsLabel];
		
		[self.noObjectsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:[LMLayoutManager isiPad] ? 100 : 20];
		[self.noObjectsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:[LMLayoutManager isiPad] ? 100 : 20];
		[self.noObjectsLabel autoPinEdge:ALEdgeTop
								  toEdge:isPlaylists ? ALEdgeBottom : ALEdgeTop
								  ofView:isPlaylists ? self.playlistModificationButtonBackgroundView : self
							  withOffset:isPlaylists ? 16 : 24];
		//	[self.noObjectsLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(3.0/4.0)];
		
		self.noObjectsLabel.hidden = (self.musicTrackCollections.count > 0);
	}
}

- (void)tappedBigListEntryAtIndex:(NSInteger)i {
	self.indexOfCurrentlyOpenDetailView = i;
	
	if([LMLayoutManager isLandscape]){
		[self setPhoneLandscapeViewDisplaying:YES forIndex:i];
		return;
	}
	
	LMCollectionViewFlowLayout *layout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;

	BOOL displayNothing = (i == layout.indexOfItemDisplayingDetailView);
	
	if(!displayNothing){
		LMMusicTrackCollection *trackCollection = nil;
		if(self.musicType == LMMusicTypePlaylists){
			trackCollection = [self.playlistManager.playlists objectAtIndex:i].trackCollection;
		}
		else{
			trackCollection = [self.musicTrackCollections objectAtIndex:i];
		}
		layout.amountOfItemsInDetailView = trackCollection.count;
	}
	else{
		self.indexOfCurrentlyOpenDetailView = LMNoDetailViewSelected;
	}
	layout.indexOfItemDisplayingDetailView = displayNothing ? LMNoDetailViewSelected : i;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		self.indexOfCurrentlyOpenDetailView = LMNoDetailViewSelected;
	}
	return self;
}

@end
