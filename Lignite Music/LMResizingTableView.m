//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMResizingTableView.h"
#import "LMTableView.h"
#import "LMBigListEntry.h"
#import "LMTiledAlbumCoverView.h"
#import "LMExtras.h"

//#import "LMPlaylistView.h"
//#import "LMControlBarView.h"
//#import "LMAppIcon.h"
//#import "LMTableView.h"
//#import "LMTiledAlbumCoverView.h"
//#import "LMCollectionInfoView.h"
//#import "LMBigListEntry.h"

//@interface LMPlaylistView()<LMControlBarViewDelegate, LMTableViewSubviewDelegate, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>
@interface LMResizingTableView()<LMTableViewSubviewDelegate, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>

@property LMTableView *rootTableView;

@property (strong, nonatomic) NSMutableArray *contentSubviewsArray;
@property (strong, nonatomic) NSMutableArray *playlistItemsArray;

@property float largeCellSize;

@property NSInteger currentLargeEntry;

@end

@implementation LMResizingTableView

- (void)setup {	
	self.currentLargeEntry = -1;
	
	self.rootTableView = [LMTableView newAutoLayoutView];
	self.rootTableView.subviewDelegate = self;
	self.rootTableView.amountOfItemsTotal = 40;
	self.rootTableView.dynamicCellSize = YES;
	[self addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgesToSuperviewEdges];
	
	[self.rootTableView regenerate:NO];
}

- (LMBigListEntry*)bigListEntryForIndex:(NSUInteger)index {
	if(index == -1){
		return nil;
	}
	
	for(int i = 0; i < self.playlistItemsArray.count; i++){
		LMBigListEntry *indexEntry = [self.playlistItemsArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			return indexEntry;
		}
	}
	return nil;
}

- (void)sizeChangedTo:(CGSize)newSize forBigListEntry:(LMBigListEntry *)bigListEntry {
	if(newSize.height > 0 && self.largeCellSize < 1){
		self.largeCellSize = newSize.height;
	}
	
	[self.rootTableView reloadSize];
//	self.bigListEntryHeightConstraint.constant = newSize.height;
//	[self layoutIfNeeded];
}

- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry *)bigListEntry {
	return 0.4;
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry *)bigListEntry {
	return [self.contentSubviewsArray objectAtIndex:bigListEntry.collectionIndex % self.contentSubviewsArray.count];
}

- (int)indexInArrayForInfoView:(LMCollectionInfoView*)infoView {
	for(int i = 0; i < self.playlistItemsArray.count; i++){
		LMBigListEntry *bigListEntry = [self.playlistItemsArray objectAtIndex:i];
		UIView *rootView = [bigListEntry.subviews objectAtIndex:0];
		for(int rootIndex = 0; rootIndex < rootView.subviews.count; rootIndex++){
			UIView *subview = [rootView.subviews objectAtIndex:rootIndex];
			if([subview isEqual:infoView]){
				return i;
			}
		}
	}
	return -1;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView *)infoView {
	int rindex = [self indexInArrayForInfoView:infoView];
	LMBigListEntry *entry = [self.playlistItemsArray objectAtIndex:rindex];
	return [NSString stringWithFormat:@"CIndex %ld - RIndex %d", entry.collectionIndex, rindex];
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView *)infoView {
	return @"72 Songs";
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView *)infoView {
	return @"Right text!";
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView *)infoView {
	return [UIImage imageNamed:@"icon_bug.png"];
}

/**
 See LMTableView for documentation on this function.
 */
- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(!height){
		return 0.1;
	}
	return [LMBigListEntry smallSizeForBigListEntryWithDelegate:self]/WINDOW_FRAME.size.height;
//	return height ? self.windowPercentage : 0.2;
}

- (float)largeCellSizeForTableView:(LMTableView *)tableView {
//	return 200;
	
	return self.largeCellSize ? self.largeCellSize : 200;
}

- (NSArray*)largeCellSizesAffectedIndexesForTableView:(LMTableView *)tableView {
	return (self.currentLargeEntry == -1) ? @[] : @[@(self.currentLargeEntry)];
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry *)bigListEntry {
	if(largeSize && !self.largeCellSize){
		self.largeCellSize = newHeight;
	}
	
	if(self.currentLargeEntry != -1){
		if(largeSize && bigListEntry.collectionIndex != self.currentLargeEntry){
			LMBigListEntry *currentBigEntry = [self bigListEntryForIndex:self.currentLargeEntry];
			if(currentBigEntry){
				[currentBigEntry setLarge:NO animated:YES];
			}
		}
	}
	
	if(largeSize){
		self.currentLargeEntry = bigListEntry.collectionIndex;
	}
	
	if(!largeSize && bigListEntry.collectionIndex == self.currentLargeEntry){
		self.currentLargeEntry = -1;
	}
	
	[self.rootTableView reloadSize];
}

/**
 See LMTableView for documentation on this function.
 */
- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 25;
	//TODO fix this
}

/**
 See LMTableView for documentation on this function.
 */
- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return NO;
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return YES;
}

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(!self.playlistItemsArray){
		self.contentSubviewsArray = [NSMutableArray new];
		self.playlistItemsArray = [NSMutableArray new];
		
		for(int i = 0; i < amount; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			LMTiledAlbumCoverView *contentSubview = [LMTiledAlbumCoverView newAutoLayoutView];
			//			contentSubview.backgroundColor = [UIColor blueColor];
			
			[self.playlistItemsArray addObject:bigListEntry];
			[self.contentSubviewsArray addObject:contentSubview];
			
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			[bigListEntry setup];
//			bigListEntry.backgroundColor = [UIColor colorWithRed:0.2*(arc4random_uniform(5)) green:0.2*(arc4random_uniform(5)) blue:0.2*(arc4random_uniform(5)) alpha:0.5];
		}
	}
}

- (id)prepareSubviewAtIndex:(NSUInteger)index {
	LMBigListEntry *bigListEntry = [self.playlistItemsArray objectAtIndex:index % self.playlistItemsArray.count];
	bigListEntry.collectionIndex = index;
	[bigListEntry reloadData];
	
	[bigListEntry setLarge:(self.currentLargeEntry == index) animated:NO];
//	[bigListEntry setLarge:bigListEntry.collectionIndex == self.currentLargeEntry];
	return bigListEntry;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
