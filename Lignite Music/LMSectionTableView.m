//
//  LMSectionTableView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSectionTableView.h"
#import "LMTableView.h"
#import "LMExtras.h"
#import "LMColour.h"
#import "LMSectionHeaderView.h"

@interface LMSectionTableView()<LMTableViewSubviewDataSource>

/**
 The table view which is at the heart of the section table view.
 */
@property LMTableView *tableView;

/**
 The array of which indexes are section headers.
 */
@property NSMutableArray<NSNumber*> *sectionIndexArray;

/**
 The array of section header views which contain all of the text and stuff for the headers.
 */
@property NSMutableArray<LMSectionHeaderView*> *sectionHeaderViewsArray;

@end

@implementation LMSectionTableView

- (NSUInteger)sectionNumberForIndex:(NSUInteger)index {
//	NSLog(@"Sections are %@", self.sectionIndexArray);
	
	NSUInteger section = [[self.sectionIndexArray objectAtIndex:self.sectionIndexArray.count-1] unsignedIntegerValue];
	
//	NSLog(@"Top section is %d", (int)section);
	
	NSUInteger searchIndex = self.sectionIndexArray.count-1;
	while(section > index){
		searchIndex--;
		section = [[self.sectionIndexArray objectAtIndex:searchIndex] unsignedIntegerValue];
		
//		NSLog(@"Next section is %d with an index of %d", (int)section, (int)searchIndex);
	}
	
//	NSLog(@"Returning %d", (int)searchIndex);
	
	return searchIndex;
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	NSUInteger section = [self sectionNumberForIndex:index];
//	NSLog(@"Index %d is in section %d", (int)index, (int)[self sectionNumberForIndex:index]);
	
	if([self.sectionIndexArray containsObject:@(index)]){
		NSLog(@"Section %d %d %d", (int)section, (int)index, (int)([self.sectionIndexArray indexOfObject:@(index)] % self.sectionHeaderViewsArray.count));
		LMSectionHeaderView *sectionHeader = [self.sectionHeaderViewsArray objectAtIndex:[self.sectionIndexArray indexOfObject:@(index)] % self.sectionHeaderViewsArray.count];
		sectionHeader.sectionHeaderTitle = [self.delegate titleAtSection:section forSectionTableView:self];
		sectionHeader.icon = [self.delegate iconAtSection:section forSectionTableView:self];
		return sectionHeader;
	}
	
	UIView *view = [UIView newAutoLayoutView];
	view.backgroundColor = [LMColour superLightGrayColour];
	return view;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if([self.sectionIndexArray containsObject:@(index)]){
		return WINDOW_FRAME.size.height/10.0 + ((index == 0) ? WINDOW_FRAME.size.height/20 : 0);
	}
	return WINDOW_FRAME.size.height/8.0;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	return 0;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView {
	NSLog(@"Number of objects %lu", (unsigned long)amountOfObjects);
}

- (void)reloadData {
	self.sectionIndexArray = [NSMutableArray new];
	if(self.numberOfSections > 0){
		[self.sectionIndexArray addObject:@(0)];
	}
	
	for(int section = 1; section < self.numberOfSections; section++){
		NSUInteger numberOfRowsForPreviousSection = [self.delegate numberOfRowsForSection:section-1 forSectionTableView:self];
		NSUInteger previousSectionIndex = [[self.sectionIndexArray objectAtIndex:section-1] unsignedIntegerValue];
		
		[self.sectionIndexArray addObject:@(previousSectionIndex + numberOfRowsForPreviousSection + 1)];
	}
	
	NSUInteger totalNumberOfItems = 0;
	totalNumberOfItems += self.numberOfSections;
	for(int i = 0; i < self.numberOfSections; i++){
		totalNumberOfItems += [self.delegate numberOfRowsForSection:i forSectionTableView:self];
	}
	
	self.tableView.totalAmountOfObjects = totalNumberOfItems;
	
	[self.tableView reloadSubviewData];
	
	NSLog(@"There %d total entries with sections @ %@", (int)totalNumberOfItems, self.sectionIndexArray);
}

- (void)setup {
	self.sectionHeaderViewsArray = [NSMutableArray new];
	for(int i = 0; i < 6; i++){
		LMSectionHeaderView *sectionHeader = [LMSectionHeaderView newAutoLayoutView];
		[self.sectionHeaderViewsArray addObject:sectionHeader];
	}
	
	self.tableView = [LMTableView newAutoLayoutView];
	self.tableView.totalAmountOfObjects = 4; //self.sources.count;
	self.tableView.subviewDataSource = self;
	self.tableView.shouldUseDividers = YES;
	self.tableView.averageCellHeight = WINDOW_FRAME.size.height/12.0;
	self.tableView.title = @"SectionTableView";
	self.tableView.dividerColour = [UIColor blackColor];
	self.tableView.bottomSpacing = 0;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self reloadData];
}

@end
