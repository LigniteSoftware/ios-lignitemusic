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
#import "LMLabel.h"

@interface LMSectionTableView()<UITableViewDelegate, UITableViewDataSource, LMListEntryDelegate>

@property BOOL hasRegisteredCellIdentifiers;

@property NSMutableArray *listEntryArray;

@end

@implementation LMSectionTableView

- (NSUInteger)rawIndexForIndexPath:(NSIndexPath*)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	
	NSUInteger totalRows = row;
	for(NSUInteger i = 0; i < section; i++){
		totalRows += [self.contentsDelegate numberOfRowsForSection:i forSectionTableView:self];
	}
	
	return totalRows;
}

- (void)tappedListEntry:(LMListEntry*)entry {
	[self.contentsDelegate tappedIndexPath:entry.indexPath forSectionTableView:self];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [UIColor redColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	if(entry.indexPath){
		return [self.contentsDelegate titleForIndexPath:entry.indexPath forSectionTableView:self];
	}
	return @"Unnamned title";
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	if(entry.indexPath){
		return [self.contentsDelegate subtitleForIndexPath:entry.indexPath forSectionTableView:self];
	}
	return @"Unnamned subtitle";
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return nil;
	return [LMAppIcon imageForIcon:LMIconAlbums];
}

- (instancetype)init {
	self = [super initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
	if(self){
		self.backgroundColor = [UIColor whiteColor];
//		self.separatorColor = [LMColour superLightGrayColour];
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
	NSUInteger rawRow = [self rawIndexForIndexPath:indexPath];
	
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@Cell_%lu", self.title, rawRow % self.listEntryArray.count];
	
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	cell.contentView.backgroundColor = [LMColour superLightGrayColour];
		
	LMListEntry *subview = [self.listEntryArray objectAtIndex:rawRow % self.listEntryArray.count];
	subview.indexPath = indexPath;
	[subview reloadContents];
	
	cell.subview = subview;
	
	if(!cell.didSetupConstraints){
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell setNeedsUpdateConstraints];
		[cell updateConstraintsIfNeeded];
		
		if([self.contentsDelegate respondsToSelector:@selector(accessoryViewForIndexPath:forSectionTableView:)]){
			id accessorySubview = [self.contentsDelegate accessoryViewForIndexPath:indexPath forSectionTableView:self];
			NSString *accessorySubviewClass = [[accessorySubview class] description];
			BOOL shouldHangRight = ![accessorySubviewClass isEqualToString:@"UISwitch"];
			
			UIView *accessoryView = [UIView newAutoLayoutView];
//			accessoryView.backgroundColor = [LMColour randomColour];
			[cell.contentView addSubview:accessoryView];
			
			[accessoryView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:subview.contentView withOffset:shouldHangRight ? 10 : 0];
			[accessoryView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[accessoryView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:cell.contentView withMultiplier:(1.0/2.0)];
			[accessoryView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:cell.contentView withMultiplier:(1.0/2.0)];
			
			[accessoryView addSubview:accessorySubview];
			
			if([accessorySubviewClass isEqualToString:@"UISwitch"]){
				[accessorySubview autoCenterInSuperview];
			}
			else if([accessorySubviewClass isEqualToString:@"UIImageView"]){
				[accessorySubview autoCenterInSuperview];
				[accessorySubview autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:accessoryView withMultiplier:(1.0/2.0)];
				[accessorySubview autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:accessoryView withMultiplier:(1.0/2.0)];
			}
			else{
				NSLog(@"[%@]: Unknown class %@ for accessory.", self.title, accessorySubviewClass);
			}
		}
		
//		UIImageView *arrowView = [UIImageView newAutoLayoutView];
//		arrowView.image = [UIImage imageNamed:@"icon_arrow_forward.png"];
//		[accessoryView addSubview:arrowView];
//		
//		[arrowView autoCenterInSuperview];
//		[arrowView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:accessoryView withMultiplier:(1.0/2.0)];
//		[arrowView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:accessoryView withMultiplier:(1.0/2.0)];
		
//		UISwitch *testSwitch = [UISwitch newAutoLayoutView];
//		[accessoryView addSubview:testSwitch];
//		
//		[testSwitch autoCenterInSuperview];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return WINDOW_FRAME.size.height/8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if(section == 0){
		return WINDOW_FRAME.size.height/10 + WINDOW_FRAME.size.height/30;
	}
	return WINDOW_FRAME.size.height/10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.contentsDelegate numberOfRowsForSection:section forSectionTableView:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.totalNumberOfSections;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

/**
 Gets the view for a header for a certain section. If shouldUseDividers is set to YES, this will draw a divider half way through the view of the header.
 **/
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, self.frame.size.width, [self tableView:self heightForHeaderInSection:section]);
	LMSectionHeaderView *view = [[LMSectionHeaderView alloc] initWithFrame:frame];
	view.sectionHeaderTitle = [self.contentsDelegate titleAtSection:section forSectionTableView:self];
	view.icon = [self.contentsDelegate iconAtSection:section forSectionTableView:self];
	
	if(section == 0){
		view.heightFactorial = (WINDOW_FRAME.size.height/10) / frame.size.height;
		view.title = @""; //self.title;
	}
	
	return view;
}

- (void)setup {
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = 0; i < 12; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.contentViewHeightMultiplier = 0.875;
		
		[self.listEntryArray addObject:listEntry];
		
		[listEntry setup];
	}
	
	int totalRows = (int)[self rawIndexForIndexPath:[NSIndexPath indexPathForRow:[self.contentsDelegate numberOfRowsForSection:self.totalNumberOfSections-1 forSectionTableView:self] inSection:self.totalNumberOfSections-1]];
	
	NSLog(@"%d total rows", totalRows);
	
	for(int i = 0; i < totalRows; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
}

@end
