//
//  LMCollectionViewFlowLayout.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMCollectionViewFlowLayout.h"
#import "LMExtras.h"

@implementation LMCollectionViewFlowLayout

- (CGSize)collectionViewContentSize { //Workaround?
	CGSize superSize = [super collectionViewContentSize];
	CGRect frame = self.collectionView.frame;
	return CGSizeMake(fmaxf(superSize.width, CGRectGetWidth(frame)), fmaxf(superSize.height, CGRectGetHeight(frame)));
}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
	layoutAttributes.alpha = 1;
	
	if(itemIndexPath.row == 4 && self.testingShit){
		CGRect initialDetailViewFrame = [self frameForCellAtIndexPath:itemIndexPath testingShit:YES];
		initialDetailViewFrame.size.height = 0;
		
		layoutAttributes.frame = initialDetailViewFrame;
	}
	else if(!self.testingShit){
		layoutAttributes.frame = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:itemIndexPath.row+1 inSection:0] testingShit:YES];
	}
	

	
//	NSLog(@"Called!");
	
	return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
	NSLog(@"Disappearing %@", itemIndexPath);
	
	if(itemIndexPath.row == 4 && !self.testingShit){
		CGRect initialDetailViewFrame = [self frameForCellAtIndexPath:itemIndexPath testingShit:YES];
		initialDetailViewFrame.size.height = 0;
		
		attributes.frame = initialDetailViewFrame;
	}
	else if(self.testingShit){
		attributes.frame = [self frameForCellAtIndexPath:itemIndexPath testingShit:NO];
	}
	
	return attributes;
}

//- (CGSize)collectionViewContentSize {
//	return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height * 1.50);
//}

- (CGRect)frameForCellAtIndexPath:(NSIndexPath*)indexPath testingShit:(BOOL)testingShit {
	NSInteger factor = 4; //How many items to display in one row
	
	BOOL isDetailViewRow = (indexPath.row == 4) && testingShit;
	BOOL isBelowDetailViewRow = (indexPath.row > 4) && testingShit;
	
	NSInteger fixedIndexPathRow = (indexPath.row - isBelowDetailViewRow);
	
	CGSize collectionViewSize = [self collectionViewContentSize]; //Get the current size of the collection view
	CGFloat sideLength = collectionViewSize.width/factor; //Get the side length of one cell based on the factor provided
	
	sideLength -= 15; //Remove 15px from it for spacing
	
	CGFloat spacing = (collectionViewSize.width-(sideLength*factor))/(factor+1); //Calculate the amount of spacing total
	
	CGSize size = CGSizeMake(sideLength,
								sideLength * (2.8/2.0)); //The height side length is greater than the width side length because of the album art
	
	CGPoint origin = CGPointMake(((fixedIndexPathRow % factor) * (size.width+spacing)) + spacing, //The column which the cell is in
								 ((fixedIndexPathRow/factor) * (size.height+spacing)) + spacing); //The row
	
	if(isBelowDetailViewRow){
		origin.y += (size.height*2) + spacing;
	}
	
	CGRect itemFrame = CGRectMake(origin.x, origin.y, size.width, size.height); //Return the frame
	
	if(isDetailViewRow){
		return CGRectMake(origin.x, origin.y, collectionViewSize.width-(origin.x * 2), size.height*2);
	}
	
	return itemFrame;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	attributes.alpha = 1;
	attributes.frame = [self frameForCellAtIndexPath:indexPath testingShit:self.testingShit];
	
	return attributes;
}

- (NSArray<NSIndexPath*>*)indexPathsOfItemsInRect:(CGRect)rect {
	NSMutableArray *indexPathsInRect = [NSMutableArray new];
	
	NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
	BOOL foundFirstItem = NO;
	for(NSInteger i = 0; i < numberOfItems; i++){
		NSIndexPath *indexPathOfItem = [NSIndexPath indexPathForRow:i inSection:0];
		CGRect frameOfItem = [self frameForCellAtIndexPath:indexPathOfItem testingShit:self.testingShit];
		BOOL containsFrame = CGRectContainsRect(rect, frameOfItem);
		BOOL containsOrigin = CGRectContainsPoint(rect, frameOfItem.origin);
		if(containsFrame || containsOrigin){
			[indexPathsInRect addObject:indexPathOfItem];
			foundFirstItem = YES;
		}
		if(!containsFrame && !containsOrigin && foundFirstItem){
			break; //Stop it if it's already found a sequence of items, and then didn't find one, it won't be able to find anymore
		}
	}

	return indexPathsInRect;
}

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

@end
