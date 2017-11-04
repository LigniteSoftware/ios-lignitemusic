//
//  LMEnhancedPlaylistCollectionViewFlowLayout.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/3/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMEnhancedPlaylistCollectionViewFlowLayout.h"
#import "LMLayoutManager.h"

@implementation LMEnhancedPlaylistCollectionViewFlowLayout

- (CGRect)frameForCellAtIndexPath:(NSIndexPath*)indexPath {
	CGFloat halfFrame = self.collectionView.frame.size.width/2;
	CGFloat sectionSpacing = 20;
	
	CGRect previousFrame = CGRectZero;
	if(indexPath.row > 0){
		previousFrame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section]];
	}
	
	CGSize size = CGSizeMake(halfFrame - sectionSpacing, indexPath.row == 0 ? 50 : 80);
	
	CGPoint coordinates = CGPointMake(indexPath.section*halfFrame + indexPath.section * sectionSpacing,
									  previousFrame.origin.y + (indexPath.row == 0 ? 0 : (indexPath.row == 1 ? 50 : 80)) + 10);
	
	if(![LMLayoutManager isiPad]){
		size.width = self.collectionView.frame.size.width;
		coordinates = CGPointMake(0,
								  previousFrame.origin.y + (indexPath.row == 0 ? 0 : (indexPath.row == 1 ? 50 : 80)) + 10);
		
		if(indexPath.section == 1 && indexPath.row == 0){
			CGRect rectOfLastItemInFirstSection = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:[self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] inSection:0]];
			
			coordinates.y += rectOfLastItemInFirstSection.origin.y;
		}
	}
	
	return CGRectMake(coordinates.x, coordinates.y, size.width, size.height);
}

- (CGSize)collectionViewContentSize {
	CGSize size = CGSizeMake(self.collectionView.frame.size.width, 0);

	NSInteger amountOfItems = 0;
	if([LMLayoutManager isiPad]){
		amountOfItems = MAX([self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0],
							[self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:1]);
	}
	else{
		amountOfItems = ([self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] +
						 [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:1]);
	}
	if(amountOfItems > 0){
		size.height += [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].size.height;
		if(amountOfItems > 1){
			size.height += ([self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].size.height * amountOfItems-1);
			size.height += amountOfItems * 10;
		}
	}

	return size;
}

- (NSArray<NSIndexPath*>*)indexPathsOfItemsInRect:(CGRect)rect {
	NSMutableArray *indexPathsInRect = [NSMutableArray new];
	
	for(NSInteger section = 0; section < [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView]; section++){
		
		NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
		BOOL foundFirstItem = NO;
		for(NSInteger i = 0; i < numberOfItems; i++){
			NSIndexPath *indexPathOfItem = [NSIndexPath indexPathForRow:i inSection:section];
			CGRect frameOfItem = [self frameForCellAtIndexPath:indexPathOfItem];
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
		
	}
	
//	NSLog(@"%@ for %@ %lu items", indexPathsInRect, NSStringFromCGRect(rect), (unsigned long)self.musicTrackCollections.count);
	
	return indexPathsInRect;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	attributes.alpha = 1;
	attributes.frame = [self frameForCellAtIndexPath:indexPath];
	
	return attributes;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSMutableArray *layoutAttributes = [NSMutableArray new];
	
	NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect]; //Get the index paths of the items which fit into the rect provided
	
	NSLog(@"Returning %@ for %@", visibleIndexPaths, NSStringFromCGRect(rect));
	
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
		//Init
	}
	return self;
}

@end
