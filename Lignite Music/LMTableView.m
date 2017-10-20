//
//  LMTableView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTableView.h"
#import "LMTableViewCell.h"
#import "LMExtras.h"
#import "LMColour.h"
#import "NSTimer+Blocks.h"
#import "LMListEntry.h"

@interface LMTableView()<UITableViewDelegate, UITableViewDataSource>

@property NSUInteger requiredAmountOfObjects;

/**
 Whether or not the cell identifiers have been registered yet. This flag is to prevent crashes related to cell identifiers not being registered and can be reliably checked.
 */
@property BOOL hasRegisteredCellIdentifiers;

/**
 The last frame. Temporary fix for weird frame resizing.
 */
@property CGRect previousFrame;

/**
 Whether or not the bottom white spacer has been added yet for ensuring content does not get revealed when scrolling too far.
 */
@property BOOL hasAddedBottomWhiteSpacer;

@end

@implementation LMTableView

@synthesize bottomSpacing = _bottomSpacing;

/**
 Initializes the LMTableView with its defaults as stated in LMTableView.h.

 @return The new LMTableView.
 */
- (instancetype)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
	if(self){
		self.backgroundColor = [UIColor clearColor];
		self.separatorColor = [UIColor clearColor];
		self.alwaysBounceVertical = NO;
		
		self.delegate = self;
		self.dataSource = self;
				
		self.totalAmountOfObjects = 0;
		self.requiredAmountOfObjects = 0;
		
		self.dividerSectionsToIgnore = @[ @(0) ];
		self.bottomSpacing = 0;
		
		self.dividerColour = [LMColour lightGrayBackgroundColour];
		self.notHighlightedBackgroundColour = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
				
		self.title = @"UnnamedLMTableView";
		
		self.longPressReorderEnabled = NO;
	}
	return self;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {	
	if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
		[self.longPressReorderDelegate tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
	}
}

- (NSUInteger)bottomSpacing {
    return _bottomSpacing;
}

- (void)setBottomSpacing:(NSUInteger)bottomSpacing {
    BOOL shouldReload = (bottomSpacing != _bottomSpacing);
    
    _bottomSpacing = bottomSpacing;
    
//    NSLog(@"Reloading shit");
    
    if(shouldReload){
        [self reloadContentInset];
    }
}

- (void)reloadContentInset {
    CGFloat dummyViewHeight = 100;
    UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WINDOW_FRAME.size.width, dummyViewHeight)];
    self.tableHeaderView = dummyView;
    self.contentInset = UIEdgeInsetsMake(-dummyViewHeight, 0, self.bottomSpacing, 0);
}

- (void)reloadSubviewData {
	self.hasRegisteredCellIdentifiers = NO;

	self.requiredAmountOfObjects = (WINDOW_FRAME.size.height/self.averageCellHeight);
	
	if(self.requiredAmountOfObjects > self.totalAmountOfObjects){
		self.requiredAmountOfObjects = self.totalAmountOfObjects;
	}
	
	for(int i = 0; i < self.requiredAmountOfObjects; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
	
    [self reloadContentInset];
    
	[self.subviewDataSource amountOfObjectsRequiredChangedTo:self.requiredAmountOfObjects forTableView:self];
}

- (void)reloadSubviewSizes {
	if(!self.hasRegisteredCellIdentifiers) {
		NSLog(@"[LMTableView \"%@\"]: This LMTableView does not have its cell identifiers registered yet! Rejecting resize.", self.title);
		return;
	}

//	[UIView animateWithDuration:0.3 animations:^{
	
	[self beginUpdates];
	[self endUpdates];
	
//	}];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if(self.secondaryDelegate){
		if([self.secondaryDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]){
			[self.secondaryDelegate scrollViewWillBeginDragging:scrollView];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if(self.secondaryDelegate){
		if([self.secondaryDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]){
			[self.secondaryDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
		}
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if(self.secondaryDelegate){
		if([self.secondaryDelegate respondsToSelector:@selector(scrollViewDidScroll:)]){
			[self.secondaryDelegate scrollViewDidScroll:scrollView];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if(self.secondaryDelegate){
		if([self.secondaryDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]){
			[self.secondaryDelegate scrollViewDidEndDecelerating:scrollView];
		}
	}
}

//- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//
//	UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Add to Queue" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
//		// maybe show an action sheet with more options
//		NSLog(@"Tapped");
//	}];
//	moreAction.backgroundColor = [UIColor colorWithRed:0.00 green:0.60 blue:0.16 alpha:1.0];
//
//	return @[moreAction];
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	
	NSLog(@"Will display %@", indexPath);
	
	id newSubview = [self.subviewDataSource subviewAtIndex:indexPath.section forTableView:self];
	
	for(int i = 0; i < lmCell.contentView.subviews.count; i++){
		id subview = [lmCell.contentView.subviews objectAtIndex:i];
//		NSLog(@"index %ld types %@ %@", indexPath.section, [[subview class] description], [[newSubview class] description]);
		if(([subview class] == [UIView class]      && [newSubview class] == [LMListEntry class])
		|| ([subview class] == [LMListEntry class] && [newSubview class] == [UIView class])){ //If there's a big list entry on top and we're replacing it with a list entry or vice versa, remove the old view from the superview and attach the new one
			if(!self.longPressReorderEnabled){
				[subview removeFromSuperview];
			}
			
			[lmCell.contentView addSubview:newSubview];
						
			[newSubview autoPinEdgesToSuperviewEdges];
		}
	}
	
	lmCell.subview = newSubview;
	lmCell.index = (int)indexPath.section;
	lmCell.backgroundColour = (indexPath.section == 0 && self.firstEntryClear) ? [UIColor clearColor] : self.notHighlightedBackgroundColour;
	
	if(!lmCell.didSetupConstraints){
		lmCell.selectionStyle = UITableViewCellSelectionStyleNone;
		[lmCell setNeedsUpdateConstraints];
		[lmCell updateConstraintsIfNeeded];
	}
	else{
		lmCell.backgroundColor = lmCell.backgroundColour ? lmCell.backgroundColour : self.notHighlightedBackgroundColour; //For the clear background colour required in detail view
	}
}

- (void)focusCellAtIndex:(NSUInteger)index {
	UIView *cellSubview = [self.subviewDataSource subviewAtIndex:index forTableView:self];
	//	[bigListEntry setLarge:YES animated:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^() {
		[UIView animateWithDuration:0.75 animations:^{
			cellSubview.backgroundColor = [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:0.15];
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.75 animations:^{
				cellSubview.backgroundColor = self.notHighlightedBackgroundColour;
			}];
		}];
	} repeats:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@Cell_%lu", self.title, indexPath.section % self.requiredAmountOfObjects];
	
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self.subviewDataSource heightAtIndex:indexPath.section forTableView:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self.subviewDataSource spacingAtIndex:section forTableView:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.totalAmountOfObjects;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [NSString stringWithFormat:@"%ld", section];
}

- (void)layoutSubviews {
    [super layoutSubviews];
	
//    NSLog(@"Prick %@ %@", self.title, NSStringFromCGSize(self.contentSize));
    
	//Fixes dividers going off to the right way too far
	if([self.title isEqualToString:@"SourceSelector"] && self.previousFrame.size.width > self.frame.size.width){
		[self reloadData];
	}
	
	static UIView *testView;
    
    if(self.contentSize.width > 0 && self.contentSize.height > 0 && !self.hasAddedBottomWhiteSpacer && self.addBottomWhiteSpace){
//        NSLog(@"Adding this shit");
        testView = [UIView new];
        testView.backgroundColor = self.notHighlightedBackgroundColour;
        [self addSubview:testView];
    
        CGRect testViewFrame = CGRectMake(0, self.contentSize.height, self.contentSize.width, self.contentSize.height);
        testView.frame = testViewFrame;
        
//        NSLog(@"gutless %@ %@", self.title, NSStringFromCGRect(testViewFrame));
        
        self.hasAddedBottomWhiteSpacer = YES;
        
        self.clipsToBounds = NO;
    }
	else if(self.hasAddedBottomWhiteSpacer && self.addBottomWhiteSpace){
		CGRect testViewFrame = CGRectMake(0, self.contentSize.height, self.contentSize.width, self.contentSize.height);
		testView.frame = testViewFrame;
	}
	
	self.previousFrame = self.frame;
}

/**
 Gets the view for a header for a certain section. If shouldUseDividers is set to YES, this will draw a divider half way through the view of the header.
 **/
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, self.frame.size.width, [self tableView:self heightForHeaderInSection:section]);
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.backgroundColor = self.notHighlightedBackgroundColour;
	
	if(self.shouldUseDividers && ![self.dividerSectionsToIgnore containsObject:@(section)]){
		uint8_t dividerHeight = 1;
		float frameWidth = (frame.size.width * 0.9);
		float frameX = (frame.size.width-frameWidth)/2;
		float frameY = frame.size.height/2 - dividerHeight/2;
		UIView *dividerView = [[UIView alloc]initWithFrame:CGRectMake(frameX, frameY, frameWidth, dividerHeight)];
		dividerView.backgroundColor = self.dividerColour ? self.dividerColour : [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
		[view addSubview:dividerView];
		
//		NSLog(@"%@ RESULTS\nWindow frame %@\ntable frame %@\nheader frame %@\ndivider frame %@", self.title, NSStringFromCGRect(WINDOW_FRAME),  NSStringFromCGRect(self.frame), NSStringFromCGRect(frame), NSStringFromCGRect(dividerView.frame));
	}
	
	return view;
}

@end
