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
#import "APIdleManager.h"
#import "LMAppIcon.h"
#import "LMCollectionViewFlowLayout.h"
#import "LMCollectionViewCell.h"
#import "LMEmbeddedDetailView.h"
#import "LMPhoneLandscapeDetailView.h"

#import "NSTimer+Blocks.h"
#import "LMColour.h"

#import "LMPlaylistManager.h"

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMLayoutChangeDelegate>

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
 The index of the currently open detail view for transitioning between landscape and portrait on iPhone.
 */
@property NSInteger indexOfCurrentlyOpenDetailView;

/**
 The playlist manager.
 */
@property LMPlaylistManager *playlistManager;

/**
 The view containing the playlist modification and creation buttons.
 */
@property UIView *playlistModificationButtonView;

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
 Whether or not the compact view is currently in playlist editing mode.
 */
@property BOOL editing;

@end

@implementation LMCompactBrowsingView

@synthesize musicType = _musicType;

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

- (void)scrollToItemWithPersistentID:(LMMusicTrackPersistentID)persistentID {
	NSInteger index = -1;
	
	for(NSUInteger i = 0; i < self.musicTrackCollections.count; i++){
		LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:i];
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
	
	if(index == -1){
		NSLog(@"index not found :( (per. id %llu)", persistentID);
		index = 0;
	}
	
//	[self.bigListEntryTableView focusBigListEntryAtIndex:index];
	
	[self scrollViewToIndex:index];
}

- (LMMusicTrackCollection*)musicTrackCollectionForBigListEntry:(LMBigListEntry*)bigListEntry {
	return [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self musicTrackCollectionForBigListEntry:bigListEntry];
	
    if(bigListEntry.contentView){
        switch(self.musicType){
            case LMMusicTypeComposers:
            case LMMusicTypeArtists: {
                UIImageView *imageView = bigListEntry.contentView;
                UIImage *artistImage = [collection.representativeItem artistImage];
                imageView.image = artistImage;
                return imageView;
            }
            case LMMusicTypeAlbums:
            case LMMusicTypeCompilations:
            case LMMusicTypeGenres:
            case LMMusicTypePlaylists: {
                //No need for prep since we're just gonna prep once
                LMTiledAlbumCoverView *tiledAlbumCover = bigListEntry.contentView;
                tiledAlbumCover.musicCollection = collection;
//				tiledAlbumCover.layer.cornerRadius = 6.0f;
//				tiledAlbumCover.layer.masksToBounds = YES;
                return tiledAlbumCover;
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
                UIImageView *imageView = [UIImageView newAutoLayoutView];
                //			imageView.image = [[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem artistImage];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView.layer.shadowColor = [UIColor blackColor].CGColor;
                imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
                imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
                imageView.layer.shadowOpacity = 0.25f;
                UIImage *artistImage = [collection.representativeItem artistImage];
                imageView.image = artistImage;
				
				imageView.layer.cornerRadius = 6.0f;
				imageView.layer.masksToBounds = YES;
                return imageView;
            }
            case LMMusicTypeAlbums:
            case LMMusicTypeCompilations:
            case LMMusicTypeGenres:
            case LMMusicTypePlaylists: {
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

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return height ? 0.1 : 1.0;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
//	NSLog(@"%@ changed large", bigListEntry);
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	switch(self.musicType){
		case LMMusicTypeGenres: {
			return collection.representativeItem.genre ? collection.representativeItem.genre : NSLocalizedString(@"UnknownGenre", nil);
		}
		case LMMusicTypeCompilations:{
			return [collection titleForMusicType:LMMusicTypeCompilations];
		}
		case LMMusicTypePlaylists:{
			return [collection titleForMusicType:LMMusicTypePlaylists];
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
	
	LMMusicTrackCollection *collection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	
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

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Tapped %ld", bigListEntry.collectionIndex);
	
//	LMBrowsingDetailView *browsingDetailView = [LMBrowsingDetailView newAutoLayoutView];
//	browsingDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
//	browsingDetailView.musicType = self.musicType;
//	browsingDetailView.rootViewController = self.rootViewController;
//	
//	NSLog(@"Got count %ld", browsingDetailView.musicTrackCollection.trackCount);
//	
//	self.browsingDetailViewController = [LMBrowsingDetailViewController new];
//	self.browsingDetailViewController.browsingDetailView = browsingDetailView;
//	
//	self.rootViewController.currentDetailViewController = self.browsingDetailViewController;
//	
//	[self.rootViewController showViewController:self.browsingDetailViewController sender:self.rootViewController];
	
//	[self tappedBigListEntryAtIndex:bigListEntry.collectionIndex];
	
	NSLog(@"Frame inside %@", NSStringFromCGRect(bigListEntry.superview.superview.frame));
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	BOOL shouldOpenNewDetailView = (bigListEntry.collectionIndex != flowLayout.indexOfItemDisplayingDetailView);
	BOOL detailViewNotCurrentlyOpen = (flowLayout.indexOfItemDisplayingDetailView == LMNoDetailViewSelected);
	
	flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
	
	if(shouldOpenNewDetailView){
		[NSTimer scheduledTimerWithTimeInterval:detailViewNotCurrentlyOpen ? 0.0 : 0.4 block:^{
			[UIView animateWithDuration:0.15 animations:^{
				self.collectionView.contentOffset = CGPointMake(0, bigListEntry.superview.superview.frame.origin.y - 10);
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
	if(section == 1){
		return self.musicTrackCollections.count;
	}
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)collectionView.collectionViewLayout;
	return flowLayout.isDisplayingDetailView ? (self.musicTrackCollections.count+flowLayout.amountOfOverflowingCellsForDetailView+1) : self.musicTrackCollections.count;
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
			LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:flowLayout.indexOfItemDisplayingDetailView];
			
			flowLayout.amountOfItemsInDetailView = trackCollection.count;
			
			LMEmbeddedDetailView *detailView = flowLayout.detailView;
			[cell.contentView addSubview:detailView];
			
			[detailView autoPinEdgesToSuperviewEdges];
			
			
			NSLog(@"Shitttt dawg %@ %d %@ %@ %@", detailView.musicTrackCollection, (int)flowLayout.indexOfItemDisplayingDetailView, NSStringFromCGRect(self.frame), NSStringFromCGRect(cell.frame), NSStringFromCGRect(cell.contentView.frame));
		
			
			
			[self.rootViewController.buttonNavigationBar minimize:YES];
		}
		else if(indexPath.row >= [self collectionView:self.collectionView numberOfItemsInSection:1] && flowLayout.isDisplayingDetailView){
			cell.backgroundColor = [UIColor clearColor];
		}
		else{
			LMBigListEntry *bigListEntry = [self.bigListEntries objectAtIndex:indexPath.row];
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
	if(self.musicType == LMMusicTypePlaylists){
		if((scrollView.contentOffset.y > WINDOW_FRAME.size.height/12.0) && self.playlistModificationButtonViewHeightConstraint.constant >= 0){
			NSLog(@"negative %f", self.playlistModificationButtonViewHeightConstraint.constant);
			[self layoutIfNeeded];
			self.playlistModificationButtonViewHeightConstraint.constant = -(self.playlistModificationButtonView.frame.size.height/2.5);
			[UIView animateWithDuration:0.3 animations:^{
				[self layoutIfNeeded];
			}];
		}
		else if((scrollView.contentOffset.y < WINDOW_FRAME.size.height/12.0) && self.playlistModificationButtonViewHeightConstraint.constant < 0){
			NSLog(@"positive %f", self.playlistModificationButtonViewHeightConstraint.constant);
			[self layoutIfNeeded]; 
			self.playlistModificationButtonViewHeightConstraint.constant = 0;
			[UIView animateWithDuration:0.3 animations:^{
				[self layoutIfNeeded];
			}];
		}
	}
	
    if(self.didJustScrollByLetter){
        self.didJustScrollByLetter = NO;
        return;
    }
	
	CGFloat maxContentOffset = scrollView.contentSize.height - (scrollView.frame.size.height*1.5);
	if(scrollView.contentOffset.y > maxContentOffset){
		return; //Don't scroll at the end to prevent weird scrolling behaviour with resize of required button bar height
	}
	
	CGFloat difference = fabs(scrollView.contentOffset.y-self.lastScrollingOffsetPoint.y);
	if(difference > WINDOW_FRAME.size.height/4){
		self.brokeScrollingThreshhold = YES;
		[self.rootViewController.buttonNavigationBar minimize:YES];
	}
	
	[[APIdleManager sharedInstance] didReceiveInput];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(self.brokeScrollingThreshhold){
//		[self.rootViewController.buttonNavigationBar minimize];
	}
	self.brokeScrollingThreshhold = NO;
	self.lastScrollingOffsetPoint = scrollView.contentOffset;
}

- (void)changeBottomSpacing:(CGFloat)bottomSpacing {
	NSLog(@"Setting bottom spacing %f", bottomSpacing);
    [UIView animateWithDuration:0.5 animations:^{
       self.collectionView.contentInset = UIEdgeInsetsMake(self.musicType == LMMusicTypePlaylists ? 100 : 0, 0, bottomSpacing, 0);
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
	
	if(displaying){
		self.indexOfCurrentlyOpenDetailView = index;
		
		self.phoneLandscapeDetailView.index = index;
		self.phoneLandscapeDetailView.musicType = self.musicType;
		self.phoneLandscapeDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:index];
		
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
	
	self.rootViewController.landscapeNavigationBar.mode = displaying ? LMLandscapeNavigationBarModeWithBackButton : LMLandscapeNavigationBarModeOnlyLogo;
	
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
	if(![self.playlistManager userUnderstandsPlaylistManagement]){
		[self.playlistManager launchPlaylistManagementWarningOnView:self.rootViewController.navigationController.view withCompletionHandler:^{
			[self addPlaylistButtonTapped];
		}];
	}
	else{
		NSLog(@"New playlist");
	}
}

- (void)editPlaylistButtonTapped {
	if(![self.playlistManager userUnderstandsPlaylistManagement]){
		[self.playlistManager launchPlaylistManagementWarningOnView:self.rootViewController.navigationController.view withCompletionHandler:^{
			[self editPlaylistButtonTapped];
		}];
	}
	else{
		NSLog(@"Edit playlist");
		
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
	}
}

- (UIView *)roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(float)radius {
	
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

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		self.playlistManager = [LMPlaylistManager sharedPlaylistManager];
		
		LMCollectionViewFlowLayout *fuck = [LMCollectionViewFlowLayout new];
		fuck.musicTrackCollections = self.musicTrackCollections;
		fuck.musicType = self.musicType;
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
//		self.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
//		self.musicType = LMMusicTypeAlbums;
		
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.contentInset = UIEdgeInsetsMake(self.musicType == LMMusicTypePlaylists ? 100 : 0, 0, 100, 0);
		[self.collectionView registerClass:[LMCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		NSLog(@"Compact collection view %p", self.collectionView);
		
		
		self.bigListEntries = [NSMutableArray new];
		
		for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			bigListEntry.collectionIndex = i;
			[bigListEntry setup];
			
			[self.bigListEntries addObject:bigListEntry];
		}
		
		
		self.backgroundColor = [UIColor whiteColor];
		self.collectionView.backgroundColor = [UIColor whiteColor];
		[self.collectionView autoPinEdgesToSuperviewEdges];
		
		
		
		
		self.playlistModificationButtonView = [UIView newAutoLayoutView];
		self.playlistModificationButtonView.backgroundColor = [UIColor whiteColor];
		self.playlistModificationButtonView.userInteractionEnabled = YES;
		self.playlistModificationButtonView.layer.masksToBounds = YES;
		self.playlistModificationButtonView.layer.cornerRadius = 8.0f;
		self.playlistModificationButtonView.hidden = !(self.musicType == LMMusicTypePlaylists);
		[self addSubview:self.playlistModificationButtonView];

		[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
		[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
		[self.playlistModificationButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
		self.playlistModificationButtonViewHeightConstraint = [self.playlistModificationButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.125];


		self.playlistButtonLeft = [UIView newAutoLayoutView];
		self.playlistButtonLeft.backgroundColor = [LMColour ligniteRedColour];
		[self.playlistModificationButtonView addSubview:self.playlistButtonLeft];

		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.playlistButtonLeft autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.playlistButtonLeft autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistModificationButtonView withMultiplier:(1.0/2.0)].constant = -1;
		
		
		self.playlistButtonRight = [UIView newAutoLayoutView];
		self.playlistButtonRight.backgroundColor = [LMColour ligniteRedColour];
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
			
			[backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:view withMultiplier:(1.0/3.5)];
			[backgroundView autoCenterInSuperview];
			
			
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
			labelView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
			labelView.textColor = [UIColor whiteColor];
			[backgroundView addSubview:labelView];
			
			[labelView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:iconView withOffset:10.0f];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[labelView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		}
	}
}

- (void)tappedBigListEntryAtIndex:(NSInteger)i {
	if([LMLayoutManager isLandscape]){
		[self setPhoneLandscapeViewDisplaying:YES forIndex:i];
		return;
	}
	
	LMCollectionViewFlowLayout *layout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;

	BOOL displayNothing = (i == layout.indexOfItemDisplayingDetailView);
	
	if(!displayNothing){
		LMMusicTrackCollection *trackCollection = [self.musicTrackCollections objectAtIndex:i];
		layout.amountOfItemsInDetailView = trackCollection.count;
	}
	layout.indexOfItemDisplayingDetailView = displayNothing ? LMNoDetailViewSelected : i;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
	}
	return self;
}

@end
