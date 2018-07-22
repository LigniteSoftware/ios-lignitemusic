//
//  LMCollectionViewFlowLayout.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMCollectionViewFlowLayout.h"
#import "LMExtras.h"
#import "NSTimer+Blocks.h"
#import "LMCompactBrowsingView.h"
#import "LMCoreViewController.h"

@interface LMCollectionViewFlowLayout()

/**
 The previous amount of cells overflowing for the detail view.
 */
@property NSInteger previousAmountOfOverflowingCellsForDetailView;

@end

@implementation LMCollectionViewFlowLayout

@synthesize amountOfOverflowingCellsForDetailView = _amountOfOverflowingCellsForDetailView;
@synthesize indexOfItemDisplayingDetailView = _indexOfItemDisplayingDetailView;
@synthesize isDisplayingDetailView = _isDisplayingDetailView;
@synthesize indexOfDetailView = _indexOfDetailView;
@synthesize itemsPerRow = _itemsPerRow;

- (NSInteger)itemsPerRow {
	return [LMLayoutManager amountOfCollectionViewItemsPerRow];
}

- (BOOL)isDisplayingDetailView {
	return self.indexOfItemDisplayingDetailView != LMNoDetailViewSelected;
}

- (LMDetailViewDisplayMode)detailViewDisplayMode {
	return self.isDisplayingDetailView ? LMDetailViewDisplayModeCurrentIndex : LMDetailViewDisplayModeNone;
}

- (NSInteger)indexOfDetailViewForIndexOfItemDisplayingDetailView:(NSInteger)index {
	if(index > LMNoDetailViewSelected){
		NSInteger fixedIndex = (index - (index % self.itemsPerRow)) + self.itemsPerRow;
		if(fixedIndex > self.musicTrackCollections.count-1){
			return self.musicTrackCollections.count;
		}
		return fixedIndex;
	}
	return LMNoDetailViewSelected;
}

- (NSInteger)indexOfDetailView {
	return [self indexOfDetailViewForIndexOfItemDisplayingDetailView:self.indexOfItemDisplayingDetailView];
}

- (NSInteger)previousIndexOfDetailView {
	return [self indexOfDetailViewForIndexOfItemDisplayingDetailView:self.previousIndexOfItemDisplayingDetailView];
}

- (NSInteger)indexOfItemDisplayingDetailView {
	return _indexOfItemDisplayingDetailView;
}

- (NSInteger)amountOfOverflowingCellsForDetailView {
	NSInteger totalNumberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:1]; //Section 1 returns the amount of items without the detail view
	NSInteger overflow = (self.indexOfDetailView - totalNumberOfItems);
	
//	NSLog(@"total %ld overflow %ld index %ld from %@", (long)totalNumberOfItems, (long)overflow, (long)self.indexOfDetailView, self.collectionView.dataSource);
	
	if((overflow < 0) || ((overflow + self.indexOfDetailView - 1) > totalNumberOfItems)){
//		NSLog(@"No fear, returning 0");
		return 0;
	}
	
	return overflow;
}

- (void)setIndexOfItemDisplayingDetailView:(NSInteger)indexOfItemDisplayingDetailView {
	if(self.indexOfItemDisplayingDetailView == LMNoDetailViewSelected && indexOfItemDisplayingDetailView == LMNoDetailViewSelected){
		return;
	}
	
	if(indexOfItemDisplayingDetailView > LMNoDetailViewSelected && self.indexOfItemDisplayingDetailView > LMNoDetailViewSelected){ //If there is already one selected and the user is selecting a new one (and not deselecting or closing), clear the previous one first & then set the other one in
		[self setIndexOfItemDisplayingDetailView:LMNoDetailViewSelected];
		[self setIndexOfItemDisplayingDetailView:indexOfItemDisplayingDetailView];
		return;
	}
	
	if(indexOfItemDisplayingDetailView == LMNoDetailViewSelected){
		self.frameOfItemDisplayingDetailView = CGRectMake(-self.frameOfItemDisplayingDetailView.size.width, self.frameOfItemDisplayingDetailView.origin.y, 0, 0);
		
		[self.detailView hideFloatingControls];
	}
	else{ //Setting new detail view open
		LMEmbeddedDetailView *detailView = [[LMEmbeddedDetailView alloc] initWithMusicTrackCollection:[self.musicTrackCollections objectAtIndex:indexOfItemDisplayingDetailView] musicType:self.musicType];
		detailView.backgroundColor = [UIColor whiteColor];
		detailView.musicType = self.musicType;
		detailView.flowLayout = self;
		detailView.userInteractionEnabled = YES;
		detailView.adjustForFloatingControls = (!LMLayoutManager.isiPad && !LMLayoutManager.isLandscape);
		
		self.detailView = detailView;
		
		if(![LMLayoutManager isiPad]){
			LMCompactBrowsingView *compactView = self.compactView;
			LMCoreViewController *coreViewController = compactView.rootViewController;
			[coreViewController.buttonNavigationBar minimise:YES];
		}
	}
	
	self.previousIndexOfItemDisplayingDetailView = _indexOfItemDisplayingDetailView;
	self.previousAmountOfOverflowingCellsForDetailView = self.amountOfOverflowingCellsForDetailView;
	
	_indexOfItemDisplayingDetailView = indexOfItemDisplayingDetailView;
	
	NSMutableArray *items = [NSMutableArray arrayWithArray:@[ [NSIndexPath indexPathForRow:self.isDisplayingDetailView ? self.indexOfDetailView : self.previousIndexOfDetailView inSection:0] ]];
	
	NSInteger overflowCountToUse = self.isDisplayingDetailView ? self.amountOfOverflowingCellsForDetailView : self.previousAmountOfOverflowingCellsForDetailView;
	NSInteger indexOfDetailViewToUse = self.isDisplayingDetailView ? self.indexOfDetailView : self.previousIndexOfDetailView;
	
	for(NSInteger i = (indexOfDetailViewToUse - overflowCountToUse); i < indexOfDetailViewToUse; i++){
		[items addObject:[NSIndexPath indexPathForRow:i inSection:0]];
	}
	
	NSLog(@"%d/%d/%d/%d %@", self.isDisplayingDetailView, (int)overflowCountToUse, (int)indexOfDetailViewToUse, (int)self.previousAmountOfOverflowingCellsForDetailView, items);
	
	[UIView animateWithDuration:0.25 animations:^{
		[self.collectionView performBatchUpdates:^{
			self.isDisplayingDetailView ? [self.collectionView insertItemsAtIndexPaths:items] : [self.collectionView deleteItemsAtIndexPaths:items];
		} completion:nil];
	}];
	
//	self.collectionView.scrollEnabled = !self.isDisplayingDetailView;
}

- (CGSize)collectionViewContentSize {
	CGSize size = CGSizeMake(self.collectionView.frame.size.width, 0);

	if(self.isDisplayingDetailView){
		size.height += [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:self.indexOfDetailView inSection:0]
							   detailViewDisplayMode:LMDetailViewDisplayModeCurrentIndex].size.height;
		
		size.height += COMPACT_VIEW_SPACING_BETWEEN_ITEMS;
	}
	
	NSInteger amountOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:1];
	if(amountOfItems > 0){
		NSInteger amountOfRows = (amountOfItems/self.itemsPerRow) + (((amountOfItems % self.itemsPerRow) == 0) ? 0 : 1);
		
		size.height += [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
								detailViewDisplayMode:LMDetailViewDisplayModeNone].size.height * amountOfRows;
		
		size.height += amountOfRows * COMPACT_VIEW_SPACING_BETWEEN_ITEMS * (LMLayoutManager.isLandscape ? 1.00f : 1.40f);
		
		size.height -= ((amountOfRows / 5) * COMPACT_VIEW_SPACING_BETWEEN_ITEMS); //don't ask
	}
	
//	size.height += 75;
	
	return size;
	
//	CGSize superSize = [super collectionViewContentSize];
//	CGRect frame = self.collectionView.frame;
//	return CGSizeMake(fmaxf(superSize.width, CGRectGetWidth(frame)), fmaxf(superSize.height, CGRectGetHeight(frame)));
}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
//	NSLog(@"Appearing %@", itemIndexPath);
	
	if(itemIndexPath.row == self.indexOfDetailView){
//		NSLog(@"Is index of detail view");
		
		CGRect initialDetailViewFrame = [self frameForCellAtIndexPath:itemIndexPath detailViewDisplayMode:LMDetailViewDisplayModeCurrentIndex];
		if(self.detailView.frame.size.height == 0){
			initialDetailViewFrame.size.height = 0;
		}
		
		layoutAttributes.frame = initialDetailViewFrame;
	}
	else {
//		NSLog(@"Is displaying detail view");
		
		layoutAttributes.frame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:itemIndexPath.row inSection:0] detailViewDisplayMode:LMDetailViewDisplayModeCurrentIndex];
	}
	

	return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
//	NSLog(@"Disappearing %@", itemIndexPath);
	
	if(itemIndexPath.row == self.previousIndexOfDetailView){ //Shrink the detail view to 0 in height
//		NSLog(@"Is previous index");
		CGRect initialDetailViewFrame = [self frameForCellAtIndexPath:itemIndexPath detailViewDisplayMode:LMDetailViewDisplayModePreviousIndex];
		initialDetailViewFrame.size.height = 0;
		
		attributes.frame = initialDetailViewFrame;
	}
	else if(itemIndexPath.row == self.indexOfDetailView && self.detailView.isChangingSize){ //Is transitioning from music collections view to specific collection
//		attributes.alpha = 0;
	}
	else if(self.isDisplayingDetailView){ //Is an actual item in the compact view and is transitioning along with the now-opening detail view
//		NSLog(@"Displaying detail view %@", itemIndexPath);
		attributes.frame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:itemIndexPath.row inSection:0] detailViewDisplayMode:self.detailView.isChangingSize ? LMDetailViewDisplayModeCurrentIndex : LMDetailViewDisplayModeNone];
	}
	else if(!self.isDisplayingDetailView){ //Is an item in the compact view and is transitioning along with the now-closing detail view
//		NSLog(@"Not displaying detail view");
		attributes.frame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:itemIndexPath.row-1 inSection:0] detailViewDisplayMode:LMDetailViewDisplayModeCurrentIndex];
	}
	else{
		NSLog(@"Hey");
	}
	
	return attributes;
}

//- (CGSize)collectionViewContentSize {
//	return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height * 1.50);
//}

- (CGRect)frameForCellAtIndexPath:(NSIndexPath*)indexPath detailViewDisplayMode:(LMDetailViewDisplayMode)detailViewDisplayMode {
	NSInteger factor = self.itemsPerRow; //How many items to display in one row
	
//	NSLog(@"\n = %@ = \n itemDisplayingIndex %d \n indexOfDetailView %d \n itemsPerRow %d", (self.isDisplayingDetailView ? @"showing detail view" : @"not showing detail view"), (int)self.indexOfItemDisplayingDetailView, (int)self.indexOfDetailView, (int)self.itemsPerRow);
	
//	NSLog(@"Display mode is %d", (int)detailViewDisplayMode);
	
	NSInteger detailViewIndexToUse = (detailViewDisplayMode == LMDetailViewDisplayModePreviousIndex) ? self.previousIndexOfDetailView : self.indexOfDetailView;
	BOOL detailViewIndexIsNegative = (detailViewIndexToUse < 0);
	BOOL displayingDetailView = (detailViewDisplayMode != LMDetailViewDisplayModeNone) && !detailViewIndexIsNegative;
	
	BOOL isDetailViewRow = (indexPath.row == detailViewIndexToUse) && displayingDetailView && !detailViewIndexIsNegative;
	BOOL isBelowDetailViewRow = (indexPath.row > detailViewIndexToUse) && displayingDetailView && !detailViewIndexIsNegative;
	
	NSInteger amountOfItems = [self.collectionView numberOfItemsInSection:0];
	NSInteger amountLeft = ((amountOfItems-1)-self.indexOfItemDisplayingDetailView-1);
	NSInteger amountOfItemsInLastRow = (amountOfItems-1) % self.itemsPerRow;
	NSInteger amountOfItemsAfterDetailView = amountLeft-amountOfItemsInLastRow;
	
	NSInteger fixedIndexPathRow = (indexPath.row - isBelowDetailViewRow) + ((isDetailViewRow && amountOfItemsAfterDetailView < 0) ? (self.itemsPerRow+amountOfItemsAfterDetailView) : 0);
	
//	if(isBelowDetailViewRow){
//		NSLog(@"Fuck %d/%d %d %@", (int)indexPath.row, (int)fixedIndexPathRow, (int)detailViewIndexToUse, [[[self.musicTrackCollections objectAtIndex:(fixedIndexPathRow > -1) ? fixedIndexPathRow : 0] representativeItem] albumTitle]);
//	}
	
	CGSize collectionViewSize = self.collectionView.frame.size; //Get the current size of the collection view
	if(self.musicType == LMMusicTypePlaylists && !LMLayoutManager.isLandscape){
		LMCompactBrowsingView *compactView = self.compactView;
		collectionViewSize.height += compactView.playlistModificationButtonBackgroundView.frame.size.height;
	}
	CGFloat sideLength = collectionViewSize.width/factor; //Get the side length of one cell based on the factor provided
	
	if(![LMLayoutManager isiPad] && ![LMLayoutManager isLandscape]){
		sideLength = collectionViewSize.height/[LMLayoutManager amountOfCollectionViewItemsPerRowForScreenSizeClass:LMScreenSizeClassPhone isLandscape:YES];
	}
	
	sideLength -= COMPACT_VIEW_SPACING_BETWEEN_ITEMS; //Remove 15px from it for spacing
	
	if([LMLayoutManager isiPhoneX]){
		sideLength -= 24;
	}
	else if([LMLayoutManager isLandscape]){
		sideLength -= 10;
	}
	
	CGFloat spacing = (collectionViewSize.width-(sideLength*factor))/(factor+1); //Calculate the amount of spacing total
	
	CGSize size = CGSizeMake(sideLength,
								sideLength * (2.8/2.0)); //The height side length is greater than the width side length because of the album art
	
	CGFloat spacingDividerFactor = (1+(![LMLayoutManager isLandscape] && ![LMLayoutManager isiPad]));
	
	CGPoint origin = CGPointMake(((fixedIndexPathRow % factor) * (size.width+spacing)) + spacing, //The column which the cell is in
								 ((fixedIndexPathRow / factor) * (size.height+(spacing/spacingDividerFactor))) + spacing/spacingDividerFactor); //The row

//	if(indexPath.row != 0){
//		NSLog(@"%d - %@: %d to %d: %@ (%@)", (int)detailViewDisplayMode, (isDetailViewRow ? @"Detail" : (isBelowDetailViewRow ? @"Below" : (displayingDetailView ? @"Above" : @"None"))), (int)indexPath.row, (int)fixedIndexPathRow, NSStringFromCGPoint(origin), [[[self.musicTrackCollections objectAtIndex:(fixedIndexPathRow > -1) ? fixedIndexPathRow : 0] representativeItem] albumTitle]);
//	}
	
	CGFloat detailViewHeight = 0;
	
	if(isDetailViewRow || isBelowDetailViewRow){
		CGFloat maximumDetailViewHeight = [self.detailView totalSize].height;
		CGRect normalItemFrame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] detailViewDisplayMode:LMDetailViewDisplayModeNone];
		
		detailViewHeight = (collectionViewSize.height - normalItemFrame.size.height) - COMPACT_VIEW_SPACING_BETWEEN_ITEMS - normalItemFrame.origin.y + 5; //I'm not going to pull my hair out trying to figure out where the 5 pixels actually comes from, sorry
		
		if(self.musicType == LMMusicTypePlaylists && !LMLayoutManager.isLandscape){
			LMCompactBrowsingView *compactView = self.compactView;
			detailViewHeight -= compactView.playlistModificationButtonBackgroundView.frame.size.height;
		}
		
		if(!LMLayoutManager.isiPad){
			detailViewHeight -= 15;
		}
		
//		detailViewHeight -= 224;
		
		detailViewHeight = fmin(detailViewHeight, maximumDetailViewHeight);
	}
	
	if(isBelowDetailViewRow){
		origin.y += (spacing) + detailViewHeight;
	}
	
	CGRect itemFrame = CGRectMake(origin.x, origin.y, size.width, size.height); //Return the frame
	
	if(self.indexOfItemDisplayingDetailView == indexPath.row){
		self.frameOfItemDisplayingDetailView = itemFrame;
	}
	
	if(indexPath.row == 0){
		self.normalItemSize = itemFrame.size;
	}
	
	if(isDetailViewRow){
		CGRect finalFrame = CGRectMake(0, origin.y + spacing/4, collectionViewSize.width, detailViewHeight);
		
//		NSLog(@"\ncollframe %@ \n content offset %@ \n superviewframe %@ \n size of item %@\nfinal frame %@", NSStringFromCGRect(self.collectionView.frame), NSStringFromCGPoint(self.collectionView.contentOffset), NSStringFromCGRect(self.collectionView.superview.frame), NSStringFromCGRect([self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] detailViewDisplayMode:LMDetailViewDisplayModeNone]), NSStringFromCGRect(finalFrame));
		
//		NSLog(@"Amount left %ld-%ld-1 == %ld", amountOfItems-1, (long)self.indexOfItemDisplayingDetailView, (long)amountLeft);
		
		return finalFrame;
	}
	
	return itemFrame;
}

//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
//
//	return 0.0;
//}
//
//- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//
//	return UIEdgeInsetsMake(0, 0, 0, 0); // top, left, bottom, right
//}
//
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
//	return 0.0;
//}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	attributes.alpha = 1;
	attributes.frame = [self frameForCellAtIndexPath:indexPath detailViewDisplayMode:self.detailViewDisplayMode];
	
	return attributes;
}

- (NSArray<NSIndexPath*>*)indexPathsOfItemsInRect:(CGRect)rect {
	NSMutableArray *indexPathsInRect = [NSMutableArray new];
	
	NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
	BOOL foundFirstItem = NO;
	for(NSInteger i = 0; i < numberOfItems; i++){
		NSIndexPath *indexPathOfItem = [NSIndexPath indexPathForRow:i inSection:0];
		CGRect frameOfItem = [self frameForCellAtIndexPath:indexPathOfItem detailViewDisplayMode:self.detailViewDisplayMode];
		BOOL containsFrame = CGRectContainsRect(rect, frameOfItem);
		BOOL containsOrigin = CGRectContainsPoint(rect, frameOfItem.origin);
		BOOL frameOfItemContainsFrameOfDetailView = CGRectContainsRect(frameOfItem, rect); //Detail view
		BOOL framesIntersect = CGRectIntersectsRect(rect, frameOfItem) || CGRectIntersectsRect(frameOfItem, rect);

		if(containsFrame || containsOrigin || frameOfItemContainsFrameOfDetailView || framesIntersect){
			[indexPathsInRect addObject:indexPathOfItem];
			foundFirstItem = YES;
		}
		if(!containsFrame && !containsOrigin && !frameOfItemContainsFrameOfDetailView && !framesIntersect && foundFirstItem){
			break; //Stop it if it's already found a sequence of items, and then didn't find one, it won't be able to find anymore
		}
	}
	
//	NSLog(@"%@ for %@ %lu items", indexPathsInRect, NSStringFromCGRect(rect), (unsigned long)self.musicTrackCollections.count);

	return indexPathsInRect;
}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
//	NSInteger page = ceil(proposedContentOffset.y / [self.collectionView frame].size.height);
//	return CGPointMake(0, page * [self.collectionView frame].size.height);
//}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSMutableArray *layoutAttributes = [NSMutableArray new];
	
	NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect]; //Get the index paths of the items which fit into the rect provided
	for (NSIndexPath *indexPath in visibleIndexPaths) {
		UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath]; //Get their attributes, add those to the array
		[layoutAttributes addObject:attributes];
	}
	
	return layoutAttributes; //Return that array of attributes
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	CGRect oldBounds = self.collectionView.bounds;
	if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
		return YES;
	}
	return NO;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
		self.previousIndexOfItemDisplayingDetailView = LMNoDetailViewSelected;
	}
	return self;
}

@end
