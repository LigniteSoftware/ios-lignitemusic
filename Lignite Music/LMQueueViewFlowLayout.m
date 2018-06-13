//
//  LMQueueViewFlowLayout.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-12.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMQueueViewSeparatorLayoutAttributes.h"
#import "LMQueueViewFlowLayout.h"
#import "LMQueueViewSeparator.h"
#import "LMLayoutManager.h"

#define QUEUE_VIEW_SPACE_BETWEEN_CELLS 10

@interface LMQueueViewFlowLayout()

/**
 The changes that have been made to sections during interactive reordering.
 */
@property NSArray<NSNumber*> *sectionDifferences;

@end

@implementation LMQueueViewFlowLayout

- (void)finishedInteractivelyMoving {
	self.sectionDifferences = @[];
}

- (NSIndexPath*)targetIndexPathForInteractivelyMovingItem:(NSIndexPath *)previousIndexPath withPosition:(CGPoint)position {
	
	NSIndexPath *targetIndexPath = [super targetIndexPathForInteractivelyMovingItem:previousIndexPath withPosition:position];
	
	if(targetIndexPath.section != previousIndexPath.section){
		BOOL movingIntoPreviousTracksSection = (targetIndexPath.section == 0);
		NSLog(@"target previous %@ target %@ with position %@", previousIndexPath, targetIndexPath, NSStringFromCGPoint(position));
		if(self.sectionDifferences.count == 0){
			self.sectionDifferences = @[ @(movingIntoPreviousTracksSection ? 1 : -1),
										 @(movingIntoPreviousTracksSection ? -1 : 1) ];
		}
		else{
			self.sectionDifferences = @[];
		}
		
		NSLog(@"Section differences %@", self.sectionDifferences);
	}
	
	return targetIndexPath;
}

- (CGRect)frameForCellAtIndexPath:(NSIndexPath*)indexPath {
	CGFloat width = self.collectionView.frame.size.width;
	CGFloat sectionSpacing = 0;
	
	BOOL isFirstRow = (indexPath.row == 0);
	BOOL isFirstSection = (indexPath.section == 0);
	BOOL isVeryFirstRow = (isFirstRow && isFirstSection);
	
//	NSLog(@"index %@ previous frame %@", indexPath, NSStringFromCGRect(previousFrame));
	
	CGFloat standardListEntryHeight = [LMLayoutManager standardListEntryHeight];
	CGSize size = CGSizeMake(width - sectionSpacing, standardListEntryHeight);
	
	id<UICollectionViewDelegateFlowLayout> delegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
	
	CGFloat sectionHeaderHeight = [delegate collectionView:self.collectionView
													layout:self.collectionView.collectionViewLayout
						   referenceSizeForHeaderInSection:1].height;
	
	CGFloat spacerForHeader = !isFirstSection ? (sectionHeaderHeight - QUEUE_VIEW_SPACE_BETWEEN_CELLS) : 0;
	CGFloat previousOrigin = 0;
	
	NSInteger sectionDifferenceForFirstSection = 0;
	if(self.sectionDifferences.count > 0){
		sectionDifferenceForFirstSection = [[self.sectionDifferences objectAtIndex:0] integerValue];
	}
	
	CGFloat previousIndex = (indexPath.row - 1) + (!isFirstSection ? ([self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] + sectionDifferenceForFirstSection) : 0);
	if(previousIndex < 0){
		previousIndex = 0;
	}
	
	previousOrigin += (standardListEntryHeight * previousIndex) + (QUEUE_VIEW_SPACE_BETWEEN_CELLS * previousIndex);
	
	CGPoint coordinates = CGPointMake(0,
									  previousOrigin
									  + (isVeryFirstRow
										 ? 0
										 : standardListEntryHeight)
									  + (isVeryFirstRow ? 0 : QUEUE_VIEW_SPACE_BETWEEN_CELLS)
									  + spacerForHeader);
	
//	if(![LMLayoutManager isiPad]){
//		size.width = self.collectionView.frame.size.width;
//		coordinates = CGPointMake(0,
//								  previousFrame.origin.y + (indexPath.row == 0 ? 0 : (indexPath.row == 1 ? 50 : 80)) + 10);
//
//		if(indexPath.section == 1 && indexPath.row == 0){
//			CGRect rectOfLastItemInFirstSection = [self frameForCellAtIndexPath:[NSIndexPath indexPathForRow:[self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] inSection:0]];
//
//			coordinates.y += rectOfLastItemInFirstSection.origin.y + 20;
//		}
//	}
	
	CGRect frame = CGRectMake(coordinates.x, coordinates.y, size.width, size.height);
	
//	NSLog(@"Frame for %@ is %@", indexPath, NSStringFromCGRect(frame));
	
//	if(indexPath.row > 30){
//		NSLog(@"Who the fuck are you");
//	}
	
	return frame;
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
			size.height += (amountOfItems * 10);
		}
	}
	
	return size;
}

- (NSArray<NSIndexPath*>*)indexPathsOfItemsInRect:(CGRect)rect {
	NSMutableArray *indexPathsInRect = [NSMutableArray new];
	
	for(NSInteger section = 0; section < [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView]; section++){
		
		NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
		
		if(self.sectionDifferences.count > 0){
			numberOfItems += [[self.sectionDifferences objectAtIndex:section] integerValue];
		}
		
		BOOL foundFirstItem = NO;
		
		NSInteger initialRow = 0;
		NSIndexPath *initialIndexPath = [self.collectionView indexPathForItemAtPoint:rect.origin];
		initialRow = initialIndexPath.row;
		
		for(NSInteger i = initialRow; i < numberOfItems; i++){
			NSIndexPath *indexPathOfItem = [NSIndexPath indexPathForRow:i inSection:section];
			CGRect frameOfItem = [self frameForCellAtIndexPath:indexPathOfItem];
			BOOL containsFrame = CGRectContainsRect(rect, frameOfItem);
			BOOL containsOrigin = CGRectContainsPoint(rect, frameOfItem.origin);
			BOOL framesIntersect = CGRectIntersectsRect(rect, frameOfItem) || CGRectIntersectsRect(frameOfItem, rect);
			
			if(containsFrame || containsOrigin || framesIntersect){
				[indexPathsInRect addObject:indexPathOfItem];
//				NSLog(@"Yes");
				foundFirstItem = YES;
			}
			if(!containsFrame && !containsOrigin && !framesIntersect && foundFirstItem){
//				NSLog(@"Breaking at %d", (int)i);
				break; //Stop it if it's already found a sequence of items, and then didn't find one, it won't be able to find anymore
			}
			
			if(rect.size.height == 1 && rect.size.width == 1 && !containsFrame){
//				NSLog(@"Ending useless cycle of bullshit");
				break;
			}
		}
		
	}
	
//	NSLog(@"%d for %@", (int)indexPathsInRect.count, NSStringFromCGRect(rect));
//
//	if(indexPathsInRect.count == 0){
//		NSLog(@"The fuck");
//	}
//
	return indexPathsInRect;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	attributes.alpha = 1;
	attributes.frame = [self frameForCellAtIndexPath:indexPath];
	
	return attributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind
																 atIndexPath:(NSIndexPath *)indexPath {
	if([elementKind isEqualToString:@"separator"]){
		LMQueueViewSeparatorLayoutAttributes *attributes = [LMQueueViewSeparatorLayoutAttributes layoutAttributesForDecorationViewOfKind:elementKind withIndexPath:indexPath];
		
		CGRect cellFrame = [self frameForCellAtIndexPath:indexPath];
		
		CGFloat standardFillerHeight = (cellFrame.size.height + QUEUE_VIEW_SPACE_BETWEEN_CELLS);
		CGFloat fillerHeight = standardFillerHeight;
		
		NSInteger numberOfItemsInPreviousTracksSection = [self.collectionView.dataSource collectionView:self.collectionView
																				 numberOfItemsInSection:0];
		
		NSInteger numberOfItemsInNextTracksSection = [self.collectionView.dataSource collectionView:self.collectionView
																			 numberOfItemsInSection:1];
		
		BOOL isVeryFirstRow = (indexPath.row == 0 && indexPath.section == 0);
		BOOL isVeryLastRow = (indexPath.section == 1 && indexPath.row == (numberOfItemsInNextTracksSection - 1));
		BOOL onlyItem = NO;
		if(isVeryFirstRow){
			attributes.additionalOffset = (cellFrame.size.height * 6.0);
			if(numberOfItemsInPreviousTracksSection == 1){
				onlyItem = YES;
			}
		}
		
		if(isVeryLastRow){
			fillerHeight += (cellFrame.size.height * 6.0);
		}
		
		CGFloat yCoordinateAdjustment = ((fillerHeight - (cellFrame.size.height + 10)) / 2.0);
		
		attributes.frame = CGRectMake(cellFrame.origin.x,
									  cellFrame.origin.y + (cellFrame.size.height / 2.0) - yCoordinateAdjustment - attributes.additionalOffset - (onlyItem ? cellFrame.size.height : 0) + (isVeryLastRow ? ((fillerHeight / 2.0) - standardFillerHeight) : 0),
									  cellFrame.size.width,
									  fillerHeight + attributes.additionalOffset);
		
		return attributes;
	}
	return nil;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSMutableArray *layoutAttributes = [NSMutableArray new];
	
	NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect]; //Get the index paths of the items which fit into the rect provided
	
//	NSLog(@"Returning %@ for %@", visibleIndexPaths, NSStringFromCGRect(rect));
	
	NSInteger numberOfItemsInPreviousTracksSection = [self.collectionView.dataSource collectionView:self.collectionView
																			 numberOfItemsInSection:0];
	NSInteger numberOfItemsInNextTracksSection = [self.collectionView.dataSource collectionView:self.collectionView
																		 numberOfItemsInSection:1];
	
	for (NSIndexPath *indexPath in visibleIndexPaths) {
		UICollectionViewLayoutAttributes *cellAttributes = [self layoutAttributesForItemAtIndexPath:indexPath]; //Get their attributes, add those to the array
		cellAttributes.zIndex = 1;
		[layoutAttributes addObject:cellAttributes];
		
		LMQueueViewSeparatorLayoutAttributes *separatorAttributes = (LMQueueViewSeparatorLayoutAttributes*)[self layoutAttributesForDecorationViewOfKind:@"separator"
																									  atIndexPath:indexPath];
		
		BOOL isLastRow = (indexPath.section == 0 && indexPath.row == (numberOfItemsInPreviousTracksSection - 1))
			|| (indexPath.section == 1 && indexPath.row == (numberOfItemsInNextTracksSection - 1));
		
		separatorAttributes.isOnlyItem = (isLastRow && (numberOfItemsInPreviousTracksSection == 1));
		separatorAttributes.isLastRow = isLastRow;
		separatorAttributes.hidePlease = ((isLastRow && indexPath.section == 0) && !separatorAttributes.isOnlyItem);
		
//		separatorAttributes.zIndex = (cellAttributes.zIndex - 1);
		[layoutAttributes addObject:separatorAttributes];
	}
	
	NSArray<UICollectionViewLayoutAttributes*> *superDuperLayoutAttributes = [super layoutAttributesForElementsInRect:rect];
	
	for(UICollectionViewLayoutAttributes* layoutAttributesSet in superDuperLayoutAttributes){
		if(layoutAttributesSet.representedElementCategory == UICollectionElementCategorySupplementaryView){
//			NSLog(@"Fuck %@", layoutAttributesSet);
			
			UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:layoutAttributesSet.indexPath];
			
			[layoutAttributes addObject:headerAttributes];
		}
	}
	
//	NSLog(@"Hey %d attributes", (int)layoutAttributes.count);
	
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
		self.sectionDifferences = @[];
		
		[self registerClass:[LMQueueViewSeparator class] forDecorationViewOfKind:@"separator"];
	}
	return self;
}

@end
