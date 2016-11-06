//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMResizingTableView.h"
#import "LMNewTableView.h"
#import "LMBigListEntry.h"

@interface LMResizingTableView()<LMTableViewSubviewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>

@property LMNewTableView *tableView;

@property NSMutableArray *bigListEntriesArray;

@property NSInteger currentlyOpenedIndex;

@property float normalSize;
@property float largeSize;

@end

@implementation LMResizingTableView

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:index % self.bigListEntriesArray.count];
	bigListEntry.collectionIndex = index;
	if(index == self.currentlyOpenedIndex){
		//[bigListEntry open:NO];
		[bigListEntry setLarge:YES animated:NO];
	}
	else{
		//[bigListEntry close:NO];
		[bigListEntry setLarge:NO animated:NO];
	}
	NSLog(@"Entry index %lu", (unsigned long)bigListEntry.collectionIndex);
	return bigListEntry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	return index == self.currentlyOpenedIndex ? self.largeSize : self.normalSize;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	if(index == 0){
		return 80;
	}
	else{
		return 20;
	}
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	return [UIView newAutoLayoutView];
}

- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry {
	return 0.4;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
	largeSize ? (self.largeSize = newHeight) : (self.normalSize = newHeight);
	
	if(bigListEntry.isLargeSize){
		//Find the last control bar view which was open and close it
		for(int i = 0; i < self.bigListEntriesArray.count; i++){
			LMBigListEntry *bigListIndexEntry = [self.bigListEntriesArray objectAtIndex:i];
			if(bigListIndexEntry.collectionIndex == self.currentlyOpenedIndex){
				//[bigListEntry close:YES];
				NSLog(@"Setting %d to small", i);
				[bigListIndexEntry setLarge:NO animated:YES];
				break;
			}
		}
		
		//Set the currently opened control bar view as the opened one
		for(int i = 0; i < self.bigListEntriesArray.count; i++){
			LMBigListEntry *bigListIndexEntry = [self.bigListEntriesArray objectAtIndex:i];
			if([bigListIndexEntry isEqual:bigListEntry]){
				NSLog(@"Setting %ld to current opened", bigListIndexEntry.collectionIndex);
				self.currentlyOpenedIndex = bigListIndexEntry.collectionIndex;
				break;
			}
		}
	}
	//If the new size is small/closed
	else if(bigListEntry.collectionIndex == self.currentlyOpenedIndex && !bigListEntry.isLargeSize){
		self.currentlyOpenedIndex = -1;
	}
	
	[self.tableView reloadSubviewSizes];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return YES;
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	return @"Title";
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"Left text";
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"Right text";
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMNewTableView*)tableView {
	NSLog(@"I need %lu objects to survive!", (unsigned long)amountOfObjects);
	
	for(int i = 0; i < self.bigListEntriesArray.count; i++){
		LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:i];
		[bigListEntry removeFromSuperview];
		bigListEntry.hidden = YES;
	}
	
	self.bigListEntriesArray = [NSMutableArray new];
	
	for(int i = 0; i < amountOfObjects; i++){
		LMBigListEntry *newBigListEntry = [LMBigListEntry newAutoLayoutView];
		newBigListEntry.infoDelegate = self;
		newBigListEntry.entryDelegate = self;
		[newBigListEntry setup];
		
		[self.bigListEntriesArray addObject:newBigListEntry];
	}
}

- (void)setup {
	self.currentlyOpenedIndex = -1;
	
	self.normalSize = 100;
	
	self.tableView = [LMNewTableView newAutoLayoutView];
	self.tableView.title = @"BigTestView";
	self.tableView.averageCellHeight = 100;
	self.tableView.totalAmountOfObjects = 40;
	self.tableView.shouldUseDividers = YES;
	self.tableView.subviewDataSource = self;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
}

@end
