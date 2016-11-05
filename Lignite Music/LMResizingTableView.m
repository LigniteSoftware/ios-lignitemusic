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

@property NSMutableArray *contentSubviewsArray;
@property NSMutableArray *playlistItemsArray;

@property float largeCellSize;

@property NSInteger currentLargeEntry;

@end

@implementation LMResizingTableView

- (void)setup {
	NSLog(@"Setup resizing table view");
	
	self.currentLargeEntry = -1;
	
	self.rootTableView = [LMTableView newAutoLayoutView];
	self.rootTableView.subviewDelegate = self;
	[self addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgesToSuperviewEdges];
	
	self.rootTableView.amountOfItemsTotal = 40;
	self.rootTableView.dynamicCellSize = YES;
	[self.rootTableView regenerate:NO];
}

- (LMBigListEntry*)bigListEntryForIndex:(NSUInteger)index {
	if(index == -1){
		return nil;
	}
	
	for(int i = 0; i < self.playlistItemsArray.count; i++){
		NSLog(@"Searching index %d", i);
		LMBigListEntry *indexEntry = [self.playlistItemsArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			return indexEntry;
		}
	}
	return nil;
}

- (void)sizeChangedTo:(CGSize)newSize forBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"New big list entry size %@", NSStringFromCGSize(newSize));
	
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
	NSLog(@"Returning content subview for playlist %lu", (unsigned long)bigListEntry.collectionIndex);
	return [self.contentSubviewsArray objectAtIndex:bigListEntry.collectionIndex % self.contentSubviewsArray.count];
}

- (NSString*)titleForInfoView:(LMCollectionInfoView *)infoView {
	return @"Playlist Test";
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
	NSLog(@"%@ changed to large size %d %f", bigListEntry, largeSize, newHeight);
	if(largeSize && !self.largeCellSize){
		self.largeCellSize = newHeight;
	}
	
	if(self.currentLargeEntry != -1){
		LMBigListEntry *currentBigEntry = [self bigListEntryForIndex:self.currentLargeEntry];
		if(currentBigEntry){
			NSLog(@"Setting %ld as closed", currentBigEntry.collectionIndex);
			[currentBigEntry setLarge:NO];
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
	NSLog(@"Tapped index %d", index);
	return YES;
}

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	NSLog(@"Spooked! Required items %d", (int)amount);
	if(!self.playlistItemsArray){
		self.contentSubviewsArray = [NSMutableArray new];
		self.playlistItemsArray = [NSMutableArray new];
		
		for(int i = 0; i < amount; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
//			bigListEntry.backgroundColor = [UIColor colorWithRed:0.2*(arc4random_uniform(5)) green:0.2*(arc4random_uniform(5)) blue:0.2*(arc4random_uniform(5)) alpha:0.5];
			
			LMTiledAlbumCoverView *contentSubview = [LMTiledAlbumCoverView newAutoLayoutView];
//			contentSubview.backgroundColor = [UIColor blueColor];
			
			[self.playlistItemsArray addObject:bigListEntry];
			[self.contentSubviewsArray addObject:contentSubview];
		}
	}
}

- (id)prepareSubviewAtIndex:(NSUInteger)index {
	NSLog(@"Returning prepared subview index %d", (int)(index % self.playlistItemsArray.count));
	LMBigListEntry *bigListEntry = [self.playlistItemsArray objectAtIndex:index % self.playlistItemsArray.count];
	bigListEntry.collectionIndex = index;
//	[bigListEntry setLarge:bigListEntry.collectionIndex == self.currentLargeEntry];
	NSLog(@"Sending off");
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
