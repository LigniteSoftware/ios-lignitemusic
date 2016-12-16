//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBigListEntryTableView.h"
#import "LMTableView.h"
#import "LMExtras.h"
#import "LMColour.h"

@interface LMBigListEntryTableView()<LMTableViewSubviewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMControlBarViewDelegate>

@property NSMutableArray *bigListEntriesArray;
@property NSMutableArray *contentViewsArray;

@property NSInteger currentlyOpenedIndex;

@property float normalSize;
@property float largeSize;

@end

@implementation LMBigListEntryTableView

- (LMBigListEntry*)bigListEntryForCollectionInfoView:(LMCollectionInfoView*)infoView {
	for(int i = 0; i < self.bigListEntriesArray.count; i++){
		LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:i];
		for(int subviewIndex = 0; subviewIndex < bigListEntry.subviews.count; subviewIndex++){
			id subview = [bigListEntry.subviews objectAtIndex:subviewIndex];
			if([subview isEqual:infoView]){
				return bigListEntry;
			}
		}
	}
	NSLog(@"WARNING: Returning nil for big list entry!");
	return nil;
}

- (LMBigListEntry*)bigListEntryForControlBar:(LMControlBarView*)controlBar {
	for(int i = 0; i < self.bigListEntriesArray.count; i++){
		LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:i];
		for(int subviewIndex = 0; subviewIndex < bigListEntry.subviews.count; subviewIndex++){
			UIView *subview = [bigListEntry.subviews objectAtIndex:subviewIndex];
			if([subview isEqual:controlBar]){
				return bigListEntry;
			}
		}
	}
	NSLog(@"WARNING: Returning nil for control bar view!");
	return nil;
}

- (void)reloadControlBars {
	for(int i = 0; i < self.bigListEntriesArray.count; i++){
		LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:i];
		[bigListEntry reloadData:NO];
	}
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
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
	[bigListEntry reloadData:YES];
	return bigListEntry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	return index == self.currentlyOpenedIndex ? self.largeSize : self.normalSize;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	return index == 0 ? 40 : 20;
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	id contentSubview = [self.contentViewsArray objectAtIndex:bigListEntry.collectionIndex % self.bigListEntriesArray.count];
	
	[self.delegate prepareContentSubview:contentSubview forBigListEntry:bigListEntry];
	
	return contentSubview;
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	return [self.delegate contentSubviewFactorial:height forBigListEntry:bigListEntry];
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
	largeSize ? (self.largeSize = newHeight) : (self.normalSize = newHeight);
	
	if(bigListEntry.isLargeSize){
		//Find the last control bar view which was open and close it
		for(int i = 0; i < self.bigListEntriesArray.count; i++){
			LMBigListEntry *bigListIndexEntry = [self.bigListEntriesArray objectAtIndex:i];
			if(bigListIndexEntry.collectionIndex == self.currentlyOpenedIndex){
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
	return [self.delegate imageWithIndex:index forBigListEntry:[self bigListEntryForControlBar:controlBar]];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView *)controlBar {
	return [self.delegate buttonHighlightedWithIndex:index wasJustTapped:wasJustTapped forBigListEntry:[self bigListEntryForControlBar:controlBar]];
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return [self.delegate amountOfButtonsForBigListEntry:[self bigListEntryForControlBar:controlBar]];
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	return [self.delegate titleForBigListEntry:[self bigListEntryForCollectionInfoView:infoView]];
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return [self.delegate leftTextForBigListEntry:[self bigListEntryForCollectionInfoView:infoView]];
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return [self.delegate rightTextForBigListEntry:[self bigListEntryForCollectionInfoView:infoView]];
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return [self.delegate centerImageForBigListEntry:[self bigListEntryForCollectionInfoView:infoView]];
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	if([self.delegate respondsToSelector:@selector(contentViewTappedForBigListEntry:)]){
		[self.delegate contentViewTappedForBigListEntry:bigListEntry];
	}
}

- (void)focusBigListEntryAtIndex:(NSUInteger)index {
	LMBigListEntry *bigListEntry = [self subviewAtIndex:index forTableView:self.tableView];
//	[bigListEntry setLarge:YES animated:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[UIView animateWithDuration:0.75 animations:^{
			bigListEntry.backgroundColor = [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:0.15];
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.75 animations:^{
				bigListEntry.backgroundColor = [UIColor whiteColor];
			}];
		}];
	}];
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView {	
	for(int i = 0; i < self.bigListEntriesArray.count; i++){
		LMBigListEntry *bigListEntry = [self.bigListEntriesArray objectAtIndex:i];
		[bigListEntry removeFromSuperview];
		bigListEntry.hidden = YES;
	}
	
	self.bigListEntriesArray = [NSMutableArray new];
	self.contentViewsArray = [NSMutableArray new];
	
	for(int i = 0; i < amountOfObjects; i++){
		LMBigListEntry *newBigListEntry = [LMBigListEntry newAutoLayoutView];
		newBigListEntry.infoDelegate = self;
		newBigListEntry.entryDelegate = self;
		newBigListEntry.controlBarDelegate = self;
		newBigListEntry.collectionIndex = i;
		
		[self.bigListEntriesArray addObject:newBigListEntry];
		[self.contentViewsArray addObject:[self.delegate contentSubviewForBigListEntry:newBigListEntry]];
		
		[newBigListEntry setup];
	}
}

- (void)reloadData {
	[self.tableView reloadData];
}

- (void)setup {
	self.currentlyOpenedIndex = -1;
	
	self.normalSize = 100;
	
	self.tableView = [LMTableView newAutoLayoutView];
	self.tableView.title = @"BigTestView";
	self.tableView.averageCellHeight = WINDOW_FRAME.size.height*(1.0/3.0);
	self.tableView.totalAmountOfObjects = self.totalAmountOfObjects;
	self.tableView.shouldUseDividers = NO;
	self.tableView.subviewDataSource = self;
	self.tableView.bottomSpacing = 25;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
	
	if(self.totalAmountOfObjects == 0){
		UILabel *noObjectsLabel = [UILabel newAutoLayoutView];
		noObjectsLabel.numberOfLines = 0;
		noObjectsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f];
		noObjectsLabel.text = NSLocalizedString(@"TheresNothingHere", nil);
		noObjectsLabel.textAlignment = NSTextAlignmentCenter;
		noObjectsLabel.backgroundColor = [UIColor whiteColor];
		[self addSubview:noObjectsLabel];
		
		[noObjectsLabel autoPinEdgesToSuperviewMargins];
	}
}

@end
