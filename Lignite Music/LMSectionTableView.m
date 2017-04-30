//
//  LMSectionTableView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSectionHeaderView.h"
#import "LMSectionTableView.h"
#import "LMLayoutManager.h"
#import "LMTableViewCell.h"
#import "LMListEntry.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMLabel.h"

@interface LMSectionTableView()<UITableViewDelegate, UITableViewDataSource, LMListEntryDelegate, LMLayoutChangeDelegate>

@property BOOL hasRegisteredCellIdentifiers;

@property NSMutableArray *listEntryArray;

@property LMLayoutManager *layoutManager;

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
	return nil;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	if(entry.indexPath){
		return [self.contentsDelegate iconForIndexPath:entry.indexPath forSectionTableView:self];
	}
	return nil;
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
			
			if(accessorySubview){
				NSString *accessorySubviewClass = [[accessorySubview class] description];
//				BOOL shouldHangRight = ![accessorySubviewClass isEqualToString:@"UISwitch"];
				
				UIView *accessoryView = [UIView newAutoLayoutView];
//				accessoryView.backgroundColor = [LMColour randomColour];
				[cell.contentView addSubview:accessoryView];
				
				float padding = 0.06*WINDOW_FRAME.size.width;
				
				[accessoryView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:cell.contentView withOffset:-padding];
				[accessoryView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[accessoryView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:cell.contentView withMultiplier:(1.0/2.0)];
				[accessoryView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:cell.contentView withMultiplier:(1.0/2.0)];
				
				[accessoryView addSubview:accessorySubview];
				
				if([accessorySubviewClass isEqualToString:@"UISwitch"] || [accessorySubviewClass isEqualToString:@"LMSettingsSwitch"]){
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
		}
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/8.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat properNumber = (self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height);
	if(section == 0){
		return properNumber/10.0 + properNumber/30.0;
	}
	return properNumber/10.0;
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

- (void)tappedClose {
	if(self.contentsDelegate){
		if([self.contentsDelegate respondsToSelector:@selector(tappedCloseButtonForSectionTableView:)]){
			[self.contentsDelegate tappedCloseButtonForSectionTableView:self];
		}
	}
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
		view.heightFactorial = ((self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/10)
								/ frame.size.height;
		view.title = @""; //self.title;
		
//		view.xIconTapSelector = @selector(tappedClose);
	}
	
	return view;
}

- (void)registerCellIdentifiers {
	int totalRows = (int)[self rawIndexForIndexPath:[NSIndexPath indexPathForRow:[self.contentsDelegate numberOfRowsForSection:self.totalNumberOfSections-1 forSectionTableView:self] inSection:self.totalNumberOfSections-1]];
	
	for(int i = 0; i < totalRows; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self reloadData];
		
//		NSIndexSet *headers = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfSections)];
//		[self reloadSections:headers withRowAnimation:UITableViewRowAnimationNone];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self reloadData];
		
//		NSLog(@"Reloading %@", NSStringFromRange(NSMakeRange(0, self.numberOfSections)));
	}];
}

- (void)setup {
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = 0; i < 15; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.contentViewHeightMultiplier = 0.875;
		
		[self.listEntryArray addObject:listEntry];
	}
	
	[self registerCellIdentifiers];
}

@end
