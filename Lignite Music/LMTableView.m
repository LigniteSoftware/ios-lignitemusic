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

@property MPMediaQuery *everything;
@property NSUInteger amountOfItemsRequired;
@property uint8_t loadedStatus;

@property float calculatedHeight;
@property float calculatedSpacing;

@end

@implementation LMTableView

- (id)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
	if(self){
	
	}
	else{
		NSLog(@"Error creating LMTableView");
	}
	return self;
}

- (void)configureCell:(LMTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.subview = [self.subviewDelegate prepareSubviewAtIndex:indexPath.section];
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
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"ShitPost%ld", (long)(indexPath.section % self.amountOfItemsRequired)]];
		
	//[self configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"Asked for height");
	return self.calculatedHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//	NSLog(@"Asked for sections");
	return self.amountOfItemsTotal;
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
	view.backgroundColor = [UIColor clearColor];
	
	if([self.subviewDelegate dividerForTableView:self] && section != 0){
		uint8_t dividerHeight = 1;
		float frameWidth = (frame.size.width * 0.9);
		float frameX = (frame.size.width-frameWidth)/2;
		float frameY = frame.size.height/2 - dividerHeight/2;
		UIView *dividerView = [[UIView alloc]initWithFrame:CGRectMake(frameX, frameY, frameWidth, dividerHeight)];
		dividerView.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
		[view addSubview:dividerView];
	}
	
	return view;
}

- (void)prepareForUse {
	if(!self.subviewDelegate){
		NSLog(@"No subview delegate has been assigned to this LMTableView, and a subview delegate is required. The app will now exit.");
		exit(0);
		return;
	}
	
	if(self.loadedStatus == 0){
		self.delegate = self;
		self.dataSource = self;
		self.backgroundColor = [UIColor whiteColor];
		self.separatorColor = [UIColor clearColor];
		
		float delegateHeight = [self.subviewDelegate sizingFactorialRelativeToWindowForTableView:self height:YES];
		self.calculatedHeight = ceilf(delegateHeight*WINDOW_FRAME.size.height);
		self.calculatedSpacing = ceilf(self.calculatedHeight*(delegateHeight/2.0));
		
		self.loadedStatus = 1;
	}
}

- (void)layoutSubviews {
	if(self.loadedStatus == 1){
		self.amountOfItemsRequired = (self.frame.size.height/self.calculatedHeight)*(WINDOW_FRAME.size.height/self.frame.size.height) + 1;
		if(self.amountOfItemsRequired > self.amountOfItemsTotal){
			self.amountOfItemsRequired = self.amountOfItemsTotal;
		}
		[self.subviewDelegate totalAmountOfSubviewsRequired:self.amountOfItemsRequired forTableView:self];
		
		NSLog(@"\n--- LMTableView ---\nCalculated height: %f\nCalculated spacing: %f\nAmount of items total: %lu\nAmount of items required: %lu\n--- End ---", self.calculatedHeight, self.calculatedSpacing, self.amountOfItemsTotal, (unsigned long)self.amountOfItemsRequired);
		
		for(int i = 0; i < self.amountOfItemsRequired; i++){
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
