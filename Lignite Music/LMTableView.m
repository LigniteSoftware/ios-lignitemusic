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
@property BOOL loaded;

@property float calculatedHeight;
@property float calculatedSpacing;

@end

@implementation LMTableView

- (id)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
	if(self){
		
	}
	else{
		NSLog(@"Error creating LMTableView");
	}
	return self;
}

- (void)configureCell:(LMTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
//	if(!cell.queue){
//		cell.queue = [[LMOperationQueue alloc] init];
//	}
//	
//	[cell.queue cancelAllOperations];
//		
//	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
//		dispatch_sync(dispatch_get_main_queue(), ^{
//			if(operation.cancelled){
//				NSLog(@"Rejecting.");
//				return;
//			}
//			cell.everything = self.everything;
//			[cell setNeedsUpdateConstraints];
//			[cell updateConstraintsIfNeeded];
//		});
//	}];
//	
//	[cell.queue addOperation:operation];

	cell.subview = [self.subviewDelegate prepareSubviewAtIndex:indexPath.section];
	[cell setNeedsUpdateConstraints];
	[cell updateConstraintsIfNeeded];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	[self configureCell:lmCell forRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"Loading %ld", (indexPath.section % self.amountOfItemsRequired));
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"ShitPost%ld", (indexPath.section % self.amountOfItemsRequired)]];
	
	NSLog(@"Cell frame %@", NSStringFromCGRect(cell.contentView.frame));
	
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
	return self.calculatedSpacing;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	NSLog(@"Asked for header title");
	return nil;
}

- (void)prepareForUse {
	if(!self.subviewDelegate){
		NSLog(@"No subview delegate has been assigned to this LMTableView, and a subview delegate is required. The app will now exit.");
		exit(0);
		return;
	}
	
	if(!self.loaded){
		self.delegate = self;
		self.dataSource = self;
		self.backgroundColor = [UIColor whiteColor];
		self.separatorColor = [UIColor clearColor];
		
		float delegateHeight = [self.subviewDelegate sizingFactorialRelativeToWindowForTableView:self height:YES];
		self.calculatedHeight = ceilf(delegateHeight*WINDOW_FRAME.size.height);
		self.calculatedSpacing = ceilf(WINDOW_FRAME.size.height*(delegateHeight/4.0));
		self.amountOfItemsRequired = (WINDOW_FRAME.size.height/self.calculatedHeight)+2;
		[self.subviewDelegate totalAmountOfSubviewsRequired:self.amountOfItemsRequired forTableView:self];
		
		NSLog(@"\n--- LMTableView ---\nCalculated height: %f\nCalculated spacing: %f\nAmount of items total: %lu\nAmount of items required: %lu\n--- End ---", self.calculatedHeight, self.calculatedSpacing, self.amountOfItemsTotal, self.amountOfItemsRequired);
		
		for(int i = 0; i < self.amountOfItemsRequired; i++){
			[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"ShitPost%d", i]];
		}
		
		self.loaded = YES;
	}
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
