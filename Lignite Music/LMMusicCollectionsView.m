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
#import "NSTimer+Blocks.h"
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
		tiledAlbumCover.layer.masksToBounds = YES;
		tiledAlbumCover.layer.cornerRadius = 6.0f;
		return tiledAlbumCover;
	}
}

- (CGFloat)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
//	CGRect frame = [[self.collectionView.visibleCells firstObject] frame];
//	
//	if(frame.size.width == 0){
//		CGSize initialSize = [self collectionView:self.collectionView
//										   layout:self.collectionView.collectionViewLayout
//						   sizeForItemAtIndexPath:[NSIndexPath indexPathWithIndex:bigListEntry.collectionIndex]];
//		frame = CGRectMake(0, 0, initialSize.width, initialSize.height);
//	}
	
	return height ? 0.1 : ([LMLayoutManager isExtraSmall] ? 0.9 : 1.0);
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(CGFloat)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
	//	NSLog(@"%@ changed large", bigListEntry);
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	LMBigListEntry *bigListEntry = infoView.associatedBigListEntry;
	
	LMMusicTrackCollection *collection = [self.trackCollections objectAtIndex:bigListEntry.collectionIndex];
	
	NSString *fixedTitle = collection.representativeItem.albumTitle ? collection.representativeItem.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
	
	bigListEntry.isAccessibilityElement = YES;
	bigListEntry.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", fixedTitle, [self leftTextForInfoView:infoView]];
	bigListEntry.accessibilityHint = NSLocalizedString(@"VoiceOverHint_TapCompactViewEntry", nil);
	
	return fixedTitle;
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

- (UIImage*)centreImageForInfoView:(LMCollectionInfoView*)infoView {
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
	NSLog(@"count is %d", (int)self.trackCollections.count);
	return self.trackCollections.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	LMCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"musicCollectionsViewIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [LMColour superLightGreyColour];
	
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

- (CGSize)normalItemSize {	
	CGFloat scaleFactor = ((self.adjustForFloatingControls ? 6.5 : 7.0)/8.0);
	
	CGSize scaledSize = CGSizeMake(self.flowLayout.normalItemSize.width * scaleFactor,
								   self.flowLayout.normalItemSize.height * scaleFactor * (self.adjustForFloatingControls ? 1.05 : 1.0)); //Adjust for small height difference in the text size because of Mr. Picky :)
	
	return scaledSize;
}

- (CGFloat)spacing {
	NSInteger factor = [LMLayoutManager amountOfCollectionViewItemsPerRow];
	
	CGSize itemSize = [self normalItemSize];
	
	CGFloat sideLength = itemSize.width;
	
	CGFloat spacing = (WINDOW_FRAME.size.width - (self.adjustForFloatingControls ? 53 : 0) - (sideLength * factor))
					/ (factor + 1);
	
	if([LMLayoutManager isLandscape]){
		spacing = spacing * (1.0/2.0);
	}
	
	return spacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
	
	CGSize itemSize = [self normalItemSize];
	
	CGFloat spacing = [self spacing];
	
	CGFloat contentInsets = spacing*2;
	
	if(itemSize.width > (self.collectionView.frame.size.width-contentInsets)){
		flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
		return CGSizeMake(0, 0);
	}
	
	flowLayout.sectionInset = UIEdgeInsetsMake(spacing, //Top
											   [LMLayoutManager isLandscape] ? (spacing * 1.5) : spacing, //Left
											   spacing, //Bottom
											   [LMLayoutManager isLandscape] ? (spacing * 1.5) : spacing); //Right
	flowLayout.minimumLineSpacing = spacing;
	
	NSLog(@"Returning size of %@ with a section inset %@ compared to %@ and spacing of %f", NSStringFromCGSize(itemSize), NSStringFromUIEdgeInsets(flowLayout.sectionInset), NSStringFromCGRect(self.collectionView.frame), spacing);
	
//	itemSize.width = itemSize.width-(spacing*2);
	
	return itemSize;
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
		
		NSLog(@"Collections %p flow %p", self.collectionView, fuck);
		
		self.bigListEntries = [NSMutableArray new];
		
		for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			bigListEntry.collectionIndex = i;
//			[bigListEntry setup];
			
			[self.bigListEntries addObject:bigListEntry];
		}
		
		self.collectionView.backgroundColor = [LMColour superLightGreyColour];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
		
		NSLog(@"The main man %@", NSStringFromCGRect(self.frame));
		
		[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
			[self.collectionView reloadData];
			[self.collectionView.collectionViewLayout invalidateLayout];
		} repeats:NO];
	}
	
	if(self.adjustForFloatingControls){
		self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, self.collectionView.bounds.size.width - 10);
	}
		
	[super layoutSubviews];
}

@end
