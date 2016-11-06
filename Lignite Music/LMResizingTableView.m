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
#import "LMControlBarView.h"

@interface LMResizingTableView()<LMTableViewSubviewDataSource, LMControlBarViewDelegate>

@property LMNewTableView *tableView;

@property float thisShit;

@property NSMutableArray *controlBarViews;

@property NSInteger currentlyOpenedIndex;

@end

@implementation LMResizingTableView

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	LMControlBarView *controlBarView = [self.controlBarViews objectAtIndex:index % self.controlBarViews.count];
	controlBarView.index = index;
	if(controlBarView.index == self.currentlyOpenedIndex){
		[controlBarView open:NO];
	}
	else{
		[controlBarView close:NO];
	}
	return controlBarView;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	LMControlBarView *controlBarView = [self.controlBarViews objectAtIndex:index % self.controlBarViews.count];
	
	return [LMControlBarView heightWhenIsOpened:[controlBarView isOpen] && controlBarView.index == self.currentlyOpenedIndex];
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView {
	return 20;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
//	NSLog(@"Control bar changed size to %@", NSStringFromCGSize(newSize));
	
	if(newSize.height > 20){
		for(int i = 0; i < self.controlBarViews.count; i++){
			LMControlBarView *controlBarView = [self.controlBarViews objectAtIndex:i];
			if([controlBarView isEqual:controlBar]){
				self.currentlyOpenedIndex = controlBarView.index;
				NSLog(@"Currently opened index is %d", (int)controlBarView.index);
				break;
			}
		}
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

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMNewTableView*)tableView {
	NSLog(@"I need %lu objects to survive!", (unsigned long)amountOfObjects);
	
	for(int i = 0; i < self.controlBarViews.count; i++){
		LMControlBarView *controlBarView = [self.controlBarViews objectAtIndex:i];
		[controlBarView removeFromSuperview];
		controlBarView.hidden = YES;
	}
	
	self.controlBarViews = [NSMutableArray new];
	
	for(int i = 0; i < amountOfObjects; i++){
		LMControlBarView *newControlBar = [LMControlBarView newAutoLayoutView];
		newControlBar.delegate = self;
		[newControlBar setup];
		
		[self.controlBarViews addObject:newControlBar];
	}
}

- (void)increaseThisShit {
	self.thisShit += 40;
	
	[self.tableView reloadSubviewSizes];
}

- (void)setup {
	NSLog(@"Set me up!");
	
	self.thisShit = 20;
	self.currentlyOpenedIndex = -1;
	
	self.tableView = [LMNewTableView newAutoLayoutView];
	self.tableView.title = @"BigTestView";
	self.tableView.averageCellHeight = [LMControlBarView heightWhenIsOpened:NO] * 2;
	self.tableView.totalAmountOfObjects = 500;
	self.tableView.shouldUseDividers = YES;
	self.tableView.subviewDataSource = self;
	[self addSubview:self.tableView];
	
	[self.tableView autoPinEdgesToSuperviewEdges];
	
	[self.tableView reloadSubviewData];
	
//	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(increaseThisShit) userInfo:nil repeats:YES];
}

@end
