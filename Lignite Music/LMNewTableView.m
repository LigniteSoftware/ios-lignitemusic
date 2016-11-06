//
//  LMNewTableView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMNewTableView.h"
#import "LMTableViewCell.h"
#import "LMExtras.h"

@interface LMNewTableView()<UITableViewDelegate, UITableViewDataSource>

@property NSUInteger requiredAmountOfObjects;

/**
 Whether or not the cell identifiers have been registered yet. This flag is to prevent crashes related to cell identifiers not being registered and can be reliably checked.
 */
@property BOOL hasRegisteredCellIdentifiers;

@end

@implementation LMNewTableView

/**
 Initializes the LMTableView with its defaults as stated in LMTableView.h.

 @return The new LMTableView.
 */
- (instancetype)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
	if(self){
		self.backgroundColor = [UIColor whiteColor];
		self.separatorColor = [UIColor clearColor];
		self.alwaysBounceVertical = NO;
		
		self.delegate = self;
		self.dataSource = self;
		
		self.totalAmountOfObjects = 0;
		self.requiredAmountOfObjects = 0;
		
		self.dividerColour = [UIColor blackColor];
		
		self.title = @"UnnamedLMTableView";
	}
	return self;
}

- (void)reloadSubviewData {
	self.hasRegisteredCellIdentifiers = NO;
	
	self.requiredAmountOfObjects = (WINDOW_FRAME.size.height/self.averageCellHeight) + 2;
	
	if(self.requiredAmountOfObjects > self.totalAmountOfObjects){
		self.requiredAmountOfObjects = self.totalAmountOfObjects;
	}
	
	for(int i = 0; i < self.requiredAmountOfObjects; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
	
	CGFloat dummyViewHeight = 100;
	UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WINDOW_FRAME.size.width, dummyViewHeight)];
	self.tableHeaderView = dummyView;
	self.contentInset = UIEdgeInsetsMake(-dummyViewHeight, 0, 0, 0);
	
	[self.subviewDataSource amountOfObjectsRequiredChangedTo:self.requiredAmountOfObjects forTableView:self];
}

- (void)reloadSubviewSizes {
	if(!self.hasRegisteredCellIdentifiers) {
		NSLog(@"[LMTableView \"%@\"]: This LMTableView does not have its cell identifiers registered yet! Rejecting resize.", self.title);
		return;
	}
	[UIView animateWithDuration:0.3 animations:^{
		[self beginUpdates];
		[self endUpdates];
	}];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	
	lmCell.subview = [self.subviewDataSource subviewAtIndex:indexPath.section forTableView:self];
	
	if(!lmCell.didSetupConstraints){
		lmCell.selectionStyle = UITableViewCellSelectionStyleNone;
		[lmCell setNeedsUpdateConstraints];
		[lmCell updateConstraintsIfNeeded];
	}
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
	return nil;
}

/**
 Gets the view for a header for a certain section. If shouldUseDividers is set to YES, this will draw a divider half way through the view of the header.
 **/
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, self.frame.size.width, [self tableView:self heightForHeaderInSection:section]);
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.backgroundColor = [UIColor blueColor];
	
	if(self.shouldUseDividers && section != 0){
		uint8_t dividerHeight = 1;
		float frameWidth = (frame.size.width * 0.9);
		float frameX = (frame.size.width-frameWidth)/2;
		float frameY = frame.size.height/2 - dividerHeight/2;
		UIView *dividerView = [[UIView alloc]initWithFrame:CGRectMake(frameX, frameY, frameWidth, dividerHeight)];
		dividerView.backgroundColor = self.dividerColour ? self.dividerColour : [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
		[view addSubview:dividerView];
	}
	
	return view;
}

@end
