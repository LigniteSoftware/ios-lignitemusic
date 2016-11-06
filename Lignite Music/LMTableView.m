//
//  TestingViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTableView.h"
#import "LMTableViewCell.h"
#import "LMExtras.h"

@interface LMTableView () <UITableViewDelegate, UITableViewDataSource>

@property NSUInteger amountOfItemsRequired;
@property uint8_t loadedStatus;

@property UILabel *debugLabel;

@property float calculatedHeight;
@property float calculatedSpacing;

@end

@implementation LMTableView

- (id)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
	if(self){
		self.alwaysBounceVertical = NO;
		self.amountOfItemsTotal = 0;
		self.amountOfItemsRequired = 0;
	}
	else{
		NSLog(@"Error creating LMTableView");
	}
	return self;
}

- (void)configureCell:(LMTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.subview = [self.subviewDelegate prepareSubviewAtIndex:indexPath.section];
	cell.shouldNotPinContentsToBottom = self.dynamicCellSize;
	if(!cell.didSetupConstraints){
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell setNeedsUpdateConstraints];
		[cell updateConstraintsIfNeeded];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	[self configureCell:lmCell forRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"Loading %ld", (long)(indexPath.section % self.amountOfItemsRequired));
	NSString *cellIdentifier = [NSString stringWithFormat:@"ShitPost%ld", (long)(indexPath.section % self.amountOfItemsRequired)];
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	if (!cell) {
		NSLog(@"Dick?");
//		cell = [[LMTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	
	//[self configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"Asked for height %f", UITableViewAutomaticDimension);
//	return 100;
	
	if(!self.dynamicCellSize){
//		NSLog(@"Returning static calculated height %f %d", self.calculatedHeight, self.dynamicCellSize);
		return self.calculatedHeight;
	}
	else{
		NSArray *largeSizes = [self.subviewDelegate largeCellSizesAffectedIndexesForTableView:self];
		float largeSize = [self.subviewDelegate largeCellSizeForTableView:self];
		
		BOOL isLarge = [largeSizes containsObject:@(indexPath.section)];
		return isLarge ? largeSize : self.calculatedHeight;
	}
	
	return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//	NSLog(@"Asked for sections %d", (int)self.amountOfItemsTotal);
	return self.loadedStatus == 2 ? self.amountOfItemsTotal : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//	NSLog(@"Asked for number of rows");
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//	NSLog(@"Asked for spacing");
	if(section == 0){
		return self.calculatedSpacing + [self.subviewDelegate topSpacingForTableView:self];
	}
	return self.calculatedSpacing;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	NSLog(@"Asked for header title");
	return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, self.frame.size.width, [self tableView:self heightForHeaderInSection:section]);
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.backgroundColor = [UIColor blueColor];
	
	if([self.subviewDelegate dividerForTableView:self] && section != 0){
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

- (void)regenerate:(BOOL)setNeedsLayout {
	self.loadedStatus = 0;
	
	[self prepareForUse];
	
	if(setNeedsLayout){
		[self setNeedsLayout];
		[self layoutIfNeeded];
	}
}

- (void)prepareForUse {
	if(!self.subviewDelegate){
		[NSException raise:@"LMTableViewNoSubviewDelegateException" format:@"No subview delegate has been assigned to this LMTableView (%@), and a subview delegate is required.", self];
		return;
	}
	
	if(self.loadedStatus == 0){
		self.delegate = self;
		self.dataSource = self;
		self.backgroundColor = [UIColor clearColor];
		self.separatorColor = [UIColor clearColor];
		
		float delegateHeight = [self.subviewDelegate sizingFactorialRelativeToWindowForTableView:self height:YES];
		
		self.calculatedHeight = ceilf(delegateHeight*WINDOW_FRAME.size.height);
		self.calculatedSpacing = ceilf(self.calculatedHeight*(delegateHeight/5.0));
		
		self.loadedStatus = 1;
	}
}

- (void)reloadSize {
	[UIView animateWithDuration:0.3 animations:^{
		[self beginUpdates];
		
		float delegateHeight = [self.subviewDelegate sizingFactorialRelativeToWindowForTableView:self height:YES];
		self.calculatedHeight = ceilf(delegateHeight*WINDOW_FRAME.size.height);
		
		[self endUpdates];
	}];
}

- (void)layoutSubviews {
	if(self.loadedStatus == 1){
		self.amountOfItemsRequired = (self.frame.size.height/self.calculatedHeight)*(WINDOW_FRAME.size.height/self.frame.size.height) + 3;

		if(self.amountOfItemsRequired > self.amountOfItemsTotal){
			self.amountOfItemsRequired = self.amountOfItemsTotal;
		}
		
		[self.subviewDelegate totalAmountOfSubviewsRequired:self.amountOfItemsRequired forTableView:self];
		
		NSLog(@"\n--- LMTableView ---\nFrame:%@\nCalculated height: %f\nCalculated spacing: %f\nAmount of items total: %lu\nAmount of items required: %lu\n--- End ---", NSStringFromCGRect(self.frame), self.calculatedHeight, self.calculatedSpacing, (unsigned long)self.amountOfItemsTotal, (unsigned long)self.amountOfItemsRequired);
		
		for(int i = 0; i < self.amountOfItemsRequired; i++){
//			NSLog(@"Registered %@", [NSString stringWithFormat:@"ShitPost%d", i]);
			[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"ShitPost%d", i]];
		}
		
		//http://stackoverflow.com/questions/1074006/is-it-possible-to-disable-floating-headers-in-uitableview-with-uitableviewstylep
		CGFloat dummyViewHeight = 100;
		UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, dummyViewHeight)];
		self.tableHeaderView = dummyView;
		self.contentInset = UIEdgeInsetsMake(-dummyViewHeight, 0, 0, 0);
		
		self.loadedStatus = 2;
	}
	[super layoutSubviews];
}

@end
