//
//  LMSectionTableView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSectionTableView.h"
#import "LMTableViewCell.h"
#import "LMExtras.h"
#import "LMSectionHeaderView.h"
#import "LMColour.h"
#import "LMListEntry.h"
#import "LMAppIcon.h"

@interface LMSectionTableView()<UITableViewDelegate, UITableViewDataSource, LMListEntryDelegate>

@property NSUInteger requiredAmountOfObjects;

@property BOOL hasRegisteredCellIdentifiers;

@end

@implementation LMSectionTableView

- (void)tappedListEntry:(LMListEntry*)entry {
	
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [UIColor redColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	return [NSString stringWithFormat:@"Row %d", (int)entry.collectionIndex];
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	return @"Subtitle";
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return [LMAppIcon imageForIcon:LMIconAlbums];
}

- (instancetype)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
	if(self){
		self.backgroundColor = [UIColor whiteColor];
		self.separatorColor = [LMColour superLightGrayColour];
		self.alwaysBounceVertical = YES;
		
		self.delegate = self;
		self.dataSource = self;
	
		
		self.title = @"SectionTableView";
	}
	return self;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	
	//prepare shit
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@Cell_%lu", self.title, indexPath.section % self.requiredAmountOfObjects];
	
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	cell.contentView.backgroundColor = [LMColour superLightGrayColour];
	
	LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
	listEntry.collectionIndex = indexPath.row;
	listEntry.delegate = self;
	[cell.contentView addSubview:listEntry];
	
	[listEntry autoPinEdgesToSuperviewEdges];
	
	[listEntry setup];
												   
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return WINDOW_FRAME.size.height/8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return WINDOW_FRAME.size.height/12;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [NSString stringWithFormat:@"%ld", section];
}

/**
 Gets the view for a header for a certain section. If shouldUseDividers is set to YES, this will draw a divider half way through the view of the header.
 **/
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, self.frame.size.width, [self tableView:self heightForHeaderInSection:section]);
	LMSectionHeaderView *view = [[LMSectionHeaderView alloc] initWithFrame:frame];
	view.sectionHeaderTitle = [NSString stringWithFormat:@"Section %d", (int)section];
	view.icon = [UIImage imageNamed:@"icon_bug.png"];
//	//	view.backgroundColor = [UIColor yellowColor];
//	
//	if(self.shouldUseDividers && ![self.dividerSectionsToIgnore containsObject:@(section)] && !(self.bottomSpacing > 0 && section == self.numberOfSections-1)){
//		uint8_t dividerHeight = 1;
//		float frameWidth = (frame.size.width * 0.9);
//		float frameX = (frame.size.width-frameWidth)/2;
//		float frameY = frame.size.height/2 - dividerHeight/2;
//		UIView *dividerView = [[UIView alloc]initWithFrame:CGRectMake(frameX, frameY, frameWidth, dividerHeight)];
//		dividerView.backgroundColor = self.dividerColour ? self.dividerColour : [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
//		[view addSubview:dividerView];
//		
//		//		NSLog(@"%@ RESULTS\nWindow frame %@\ntable frame %@\nheader frame %@\ndivider frame %@", self.title, NSStringFromCGRect(WINDOW_FRAME),  NSStringFromCGRect(self.frame), NSStringFromCGRect(frame), NSStringFromCGRect(dividerView.frame));
//	}
	
	return view;
}

- (void)setup {
	for(int i = 0; i < 100; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
}

@end
