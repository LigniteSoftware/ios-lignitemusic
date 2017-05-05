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

//- (CGSize)collectionViewContentSize { //Workaround?
//	CGSize superSize = [super collectionViewContentSize];
//	CGRect frame = self.collectionView.frame;
//	return CGSizeMake(fmaxf(superSize.width, CGRectGetWidth(frame)), fmaxf(superSize.height, CGRectGetHeight(frame)));
//}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
	if(itemIndexPath.row > 2){
		layoutAttributes.alpha = 0;
	}
	
	NSLog(@"Called!");
	
	return layoutAttributes;
}

- (CGSize)collectionViewContentSize {
	return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height * 1.50);
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes =
	[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	attributes.frame = CGRectMake(0, indexPath.row * 225, 100, 200);
	
	return attributes;
}

- (NSArray<NSIndexPath*>*)indexPathsOfItemsInRect:(CGRect)rect {
//	return @[];
	
	if(self.testingShit){
		return @[ [NSIndexPath indexPathForRow:0 inSection:0],  [NSIndexPath indexPathForRow:1 inSection:0],  [NSIndexPath indexPathForRow:2 inSection:0], [NSIndexPath indexPathForRow:3 inSection:0] ];
	}
	else{
		return @[ [NSIndexPath indexPathForRow:0 inSection:0],  [NSIndexPath indexPathForRow:1 inSection:0],  [NSIndexPath indexPathForRow:2 inSection:0] ];
	}
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSLog(@"The frame is %@ compared to %@", NSStringFromCGRect(rect), NSStringFromCGRect(WINDOW_FRAME));
	
	NSMutableArray *layoutAttributes = [NSMutableArray new];
	
	NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect];
	for (NSIndexPath *indexPath in visibleIndexPaths) {
		UICollectionViewLayoutAttributes *attributes =
		[self layoutAttributesForItemAtIndexPath:indexPath];
		[layoutAttributes addObject:attributes];
	}
	
	return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	CGRect oldBounds = self.collectionView.bounds;
	if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
		return YES;
	}
	return NO;
}

@end
