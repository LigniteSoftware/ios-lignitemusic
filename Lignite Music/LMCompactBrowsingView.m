//
//  LMCompactBrowsingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingDetailViewController.h"
#import "LMTiledAlbumCoverView.h"
#import "LMCompactBrowsingView.h"
#import "LMBigListEntry.h"
#import "LMAppIcon.h"

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>

/**
 The big list entries that are used in the compact view.
 */
@property NSMutableArray *bigListEntries;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The detail view controller for browsing in detail ;)
 */
@property LMBrowsingDetailViewController *browsingDetailViewController;

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

@end

@implementation LMCompactBrowsingView

- (void)reloadSourceSelectorInfo {
	NSString *titleString;
	NSString *singlularString;
	NSString *pluralString;
	
	NSLog(@"Yes %d", self.musicType);
	
	switch(self.musicType){
		case LMMusicTypePlaylists:{
			titleString = @"Playlists";
			singlularString = @"List";
			pluralString = @"Lists";
			break;
		}
		case LMMusicTypeAlbums:{
			titleString = @"Albums";
			singlularString = @"Album";
			pluralString = @"Albums";
			break;
		}
		case LMMusicTypeGenres:{
			titleString = @"Genres";
			singlularString = @"Genre";
			pluralString = @"Genres";
			break;
		}
		case LMMusicTypeArtists: {
			titleString = @"Artists";
			singlularString = @"Artist";
			pluralString = @"Artists";
			break;
		}
		case LMMusicTypeComposers: {
			titleString = @"Composers";
			singlularString = @"Composer";
			pluralString = @"Composers";
			break;
		}
		case LMMusicTypeCompilations: {
			titleString = @"Compilations";
			singlularString = @"Compilation";
			pluralString = @"Compilations";
			break;
		}
		default: {
			titleString = @"Unknowns";
			singlularString = @"Unknown";
			pluralString = @"Unknowns";
			break;
		}
	}
	
	NSString *collectionString = NSLocalizedString(self.musicTrackCollections.count == 1 ? singlularString : pluralString, nil);
	
	[self.musicPlayer setSourceTitle:NSLocalizedString(titleString, nil)];
	[self.musicPlayer setSourceSubtitle:[NSString stringWithFormat:@"%ld %@", (long)self.musicTrackCollections.count, collectionString]];
}

- (void)scrollViewToIndex:(NSUInteger)index {
	NSLog(@"Scroll to %ld", index);
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
	CGRect frame = [[self.collectionView.visibleCells firstObject] frame];
	
	if(frame.size.width == 0){
		CGSize initialSize = [self collectionView:self.collectionView
										   layout:self.collectionView.collectionViewLayout
						   sizeForItemAtIndexPath:[NSIndexPath indexPathWithIndex:bigListEntry.collectionIndex]];
		frame = CGRectMake(0, 0, initialSize.width, initialSize.height);
	}
	
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
	
	LMBrowsingDetailView *browsingDetailView = [LMBrowsingDetailView newAutoLayoutView];
	browsingDetailView.musicTrackCollection = [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
	browsingDetailView.musicType = self.musicType;
	browsingDetailView.rootViewController = self.rootViewController;
	
	NSLog(@"Got count %ld", browsingDetailView.musicTrackCollection.trackCount);
	
	self.browsingDetailViewController = [LMBrowsingDetailViewController new];
	self.browsingDetailViewController.browsingDetailView = browsingDetailView;
	
	self.rootViewController.currentDetailViewController = self.browsingDetailViewController;
	
	[self.rootViewController showViewController:self.browsingDetailViewController sender:self.rootViewController];
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
	return self.musicTrackCollections.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor whiteColor];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMBigListEntry *bigListEntry = [self.bigListEntries objectAtIndex:indexPath.row];
	
	[cell.contentView addSubview:bigListEntry];
	[bigListEntry autoPinEdgesToSuperviewEdges];
    [bigListEntry reloadData];
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	//	NSLog(@"Path %@", indexPath);
	NSInteger factor = 3;
	
	CGFloat sideLength = self.frame.size.width/factor;
	
	sideLength -= 15;
	
	CGFloat spacing = (self.frame.size.width-(sideLength*factor))/(factor+1);
	
//	NSLog(@"Fuck %f", spacing);
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
	flowLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
	flowLayout.minimumLineSpacing = spacing;
		
	return CGSizeMake(sideLength, sideLength * (2.8/2.0));
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
	CGFloat difference = fabs(scrollView.contentOffset.y-self.lastScrollingOffsetPoint.y);
	if(difference > WINDOW_FRAME.size.height/4){
		self.brokeScrollingThreshhold = YES;
		[self.rootViewController.buttonNavigationBar minimize];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(self.brokeScrollingThreshhold){
//		[self.rootViewController.buttonNavigationBar minimize];
	}
	self.brokeScrollingThreshhold = NO;
	self.lastScrollingOffsetPoint = scrollView.contentOffset;
}

- (void)changeBottomSpacing:(CGFloat)bottomSpacing {
    [UIView animateWithDuration:0.5 animations:^{
       self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, bottomSpacing, 0);
    }];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
//		self.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
//		self.musicType = LMMusicTypeAlbums;
		
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		
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
	}
}

@end
