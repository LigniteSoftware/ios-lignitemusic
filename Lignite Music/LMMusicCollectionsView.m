//
//  LMMusicCollectionsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMMusicCollectionsView.h"
#import "LMTiledAlbumCoverView.h"
#import "LMCollectionViewCell.h"
#import "LMBigListEntry.h"
#import "LMColour.h"

@interface LMMusicCollectionsView()<UICollectionViewDelegate, UICollectionViewDataSource, LMBigListEntryDelegate, LMCollectionInfoViewDelegate>

/**
 The big list entries that are used in the compact view.
 */
@property NSMutableArray<LMBigListEntry*> *bigListEntries;

@end

@implementation LMMusicCollectionsView

- (LMMusicTrackCollection*)musicTrackCollectionForBigListEntry:(LMBigListEntry*)bigListEntry {
	return [self.trackCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self musicTrackCollectionForBigListEntry:bigListEntry];
	
	if(bigListEntry.contentView){
		LMTiledAlbumCoverView *tiledAlbumCover = bigListEntry.contentView;
		tiledAlbumCover.musicCollection = collection;
		return tiledAlbumCover;
	}
	else{
		LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
		tiledAlbumCover.musicCollection = collection;
		return tiledAlbumCover;
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
	
	LMMusicTrackCollection *collection = [self.trackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	return collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = [self.trackCollections objectAtIndex:bigListEntry.collectionIndex];
	
//	switch(self.musicType){
//		case LMMusicTypeComposers:
//		case LMMusicTypeArtists: {
//			BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
//												  && self.musicType != LMMusicTypeCompilations
//												  && self.musicType != LMMusicTypeAlbums);
//			
//			if(usingSpecificTrackCollections){
//				//Fixes for compilations
//				NSUInteger albums = [self.musicPlayer collectionsForRepresentativeTrack:collection.representativeItem
//																		   forMusicType:self.musicType].count;
//				return [NSString stringWithFormat:@"%lu %@", (unsigned long)albums, NSLocalizedString(albums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
//			}
//			else{
//				return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
//			}
//		}
//		case LMMusicTypeGenres:
//		case LMMusicTypePlaylists:
//		{
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
//		}
//		case LMMusicTypeCompilations:
//		case LMMusicTypeAlbums: {
//			if(collection.variousArtists){
//				return NSLocalizedString(@"Various", nil);
//			}
//			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
//		}
//		default: {
//			return nil;
//		}
//	}
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Big list tapped %@", bigListEntry);
	
	[self.delegate musicCollectionTappedAtIndex:bigListEntry.collectionIndex forMusicCollectionsView:self];
}

- (void)contentViewDoubleTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Big list double tapped %@", bigListEntry);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	NSInteger shit = self.trackCollections.count;
	if(shit < 1){
		NSLog(@"Wwiait whatt");
	}
	return self.trackCollections.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	LMCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"musicCollectionsViewIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor clearColor];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	if(cell.contentView.subviews.count == 0){
		LMBigListEntry *bigListEntry = [self.bigListEntries objectAtIndex:indexPath.row];
		
		[cell.contentView addSubview:bigListEntry];
		[bigListEntry autoPinEdgesToSuperviewEdges];
		[bigListEntry reloadData];
	}
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	//	NSLog(@"Path %@", indexPath);
	NSInteger factor = [LMLayoutManager amountOfCollectionViewItemsPerRow] - 1;
	if(factor < 2){
		factor = 2;
	}
	
	CGFloat sideLength = self.frame.size.width/factor;
	
	sideLength -= 50;
	
	CGFloat spacing = (self.frame.size.width-(sideLength*factor))/(factor+1);
	
	NSLog(@"Fuck %@", NSStringFromCGRect(self.frame));
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
	flowLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
	flowLayout.minimumLineSpacing = spacing;
	
	return CGSizeMake(sideLength, sideLength * (2.8/2.0));
}


- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.scrollDirection = UICollectionViewScrollDirectionVertical;
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
		[self.collectionView registerClass:[LMCollectionViewCell class] forCellWithReuseIdentifier:@"musicCollectionsViewIdentifier"];
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
		
		self.collectionView.backgroundColor = [LMColour superLightGrayColour];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
		
		NSLog(@"The main man %@", NSStringFromCGRect(self.frame));
		
		[NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self.collectionView reloadData];
		}];
	}
	
	[super layoutSubviews];
}

@end
