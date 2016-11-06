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

@interface LMResizingTableView()<LMTableViewSubviewDataSource>

@property LMNewTableView *tableView;

@property float thisShit;

@end

@implementation LMResizingTableView

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	NSLog(@"Providing subview at index %d", (int)index);
	
	UIView *newSubview = [UIView newAutoLayoutView];
	
	newSubview.backgroundColor = [UIColor purpleColor];
	
	return newSubview;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	return self.thisShit;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	return 10;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMNewTableView*)tableView {
	NSLog(@"I need %lu objects to survive!", (unsigned long)amountOfObjects);
}

- (void)increaseThisShit {
	self.thisShit += 40;
	
	[self.tableView reloadSubviewSizes];
}

- (void)setup {
	NSLog(@"Set me up!");
	
	self.thisShit = 20;
	
	self.tableView = [LMNewTableView newAutoLayoutView];
	self.tableView.title = @"BigTestView";
	self.tableView.averageCellHeight = 100;
	self.tableView.totalAmountOfObjects = 5;
	self.tableView.shouldUseDividers = YES;
	self.tableView.subviewDataSource = self;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(increaseThisShit) userInfo:nil repeats:YES];
}

@end
