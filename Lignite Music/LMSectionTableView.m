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
#import "LMMusicPlayer.h"
#import "LMListEntry.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMLabel.h"
#import "LMView.h"

@interface LMSectionTableView()<UITableViewDelegate, UITableViewDataSource, LMListEntryDelegate, LMLayoutChangeDelegate>

@property BOOL hasRegisteredCellIdentifiers;

@property NSMutableArray *listEntryArray;

@property LMLayoutManager *layoutManager;

@end

@implementation LMSectionTableView

@synthesize totalNumberOfSections = _totalNumberOfSections;

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

- (UIView*)rightViewForListEntry:(LMListEntry*)entry {
	if([self.contentsDelegate respondsToSelector:@selector(rightViewForIndexPath:forSectionTableView:)]){
		return [self.contentsDelegate rightViewForIndexPath:entry.indexPath forSectionTableView:self];
	}
	return nil;
}

- (BOOL)swipeButtonsEnabled {
	BOOL subscribedToSwipeButtonsFunction = [self.contentsDelegate respondsToSelector:@selector(swipeButtonsForIndexPath:rightSide:)];
	BOOL subscribedToSwipeColoursFunction = [self.contentsDelegate respondsToSelector:@selector(swipeButtonColourForIndexPath:rightSide:)];
	
	if(subscribedToSwipeButtonsFunction || subscribedToSwipeColoursFunction){
		BOOL subscribedToBothSwipeButtonDelegateFunctions = subscribedToSwipeButtonsFunction &&  subscribedToSwipeColoursFunction;
		
		NSAssert(subscribedToBothSwipeButtonDelegateFunctions, @"You cannot be subscribed to only one swipeButtons function, you must provide both, sorry.");
		
		return subscribedToBothSwipeButtonDelegateFunctions;
	}
	
	return NO;
}

- (NSArray<MGSwipeButton*>*)swipeButtonsForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	if([self swipeButtonsEnabled]){
		return [self.contentsDelegate swipeButtonsForIndexPath:listEntry.indexPath rightSide:rightSide];
	}
	
	
	
	return nil;
}

- (UIColor*)swipeButtonColourForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	if([self swipeButtonsEnabled]){
		return [self.contentsDelegate swipeButtonColourForIndexPath:listEntry.indexPath rightSide:rightSide];
	}
	
	return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	LMTableViewCell *lmCell = (LMTableViewCell*)cell;
	
	//prepare shit
	
	cell.backgroundColor = [LMColour superLightGreyColour];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger rawRow = [self rawIndexForIndexPath:indexPath];
	
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@Cell_%ld", self.title, (rawRow % self.listEntryArray.count)];
	
	LMTableViewCell *cell = (LMTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor blueColor];
	
	cell.contentView.backgroundColor = [LMColour superLightGreyColour];
		
	LMListEntry *listEntrySubview = [self.listEntryArray objectAtIndex:rawRow % self.listEntryArray.count];
	listEntrySubview.indexPath = indexPath;
	[listEntrySubview reloadContents];

	cell.subview = listEntrySubview;

	NSString *accessibilityLabel = nil;
	NSString *accessibilityHint = nil;
	if([self.contentsDelegate respondsToSelector:@selector(accessibilityLabelForIndexPath:)]){
		accessibilityLabel = [self.contentsDelegate accessibilityLabelForIndexPath:indexPath];
	}
	if([self.contentsDelegate respondsToSelector:@selector(accessibilityHintForIndexPath:)]){
		accessibilityHint = [self.contentsDelegate accessibilityHintForIndexPath:indexPath];
	}
	cell.isAccessibilityElement = YES;
	cell.accessibilityLabel = accessibilityLabel;
	cell.accessibilityHint = accessibilityHint;
	
	if(!cell.didSetupConstraints){
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell setNeedsUpdateConstraints];
		[cell updateConstraintsIfNeeded];
		
		if([self.contentsDelegate respondsToSelector:@selector(accessoryViewForIndexPath:forSectionTableView:)]){
			id accessorySubview = [self.contentsDelegate accessoryViewForIndexPath:indexPath forSectionTableView:self];
			
			if(accessorySubview){
//				listEntrySubview.isAccessibilityElement = NO;
				cell.accessoryView = accessorySubview;
			}
			else{
				cell.accessoryView = nil;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
		}
	}
//	else{
//		for(UIView *view in cell.contentView.subviews){
//			if([view class] == [LMView class]){
//				LMView *lmView = (LMView*)view;
//				if([lmView.identifier isEqualToString:@"accessoryView"]){
//					for(NSLayoutConstraint *contentViewConstraint in cell.contentView.constraints){
////						NSLog(@"%@", contentViewConstraint);
//						if(contentViewConstraint.firstItem == lmView
//						   && contentViewConstraint.firstAttribute == NSLayoutAttributeTrailing
//						   && contentViewConstraint.secondAttribute == NSLayoutAttributeTrailing){
//							
//							float padding = ([LMLayoutManager isiPhoneX] ? 0.04 : 0.06)*([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width);
//							
//							if([LMLayoutManager isiPhoneX]){
//								NSLog(@"Notch position %d", (int)LMLayoutManager.notchPosition);
//								switch([LMLayoutManager notchPosition]){
//									case LMNotchPositionRight:
//										padding = 16;
//										break;
//									case LMNotchPositionLeft:
//										padding = 0;
//										break;
//									default:
//										break;
//								}
//							}
//							contentViewConstraint.constant = -padding;
//							
//							[cell.contentView layoutIfNeeded];
//						}
//					}
//				}
//			}
//		}
//	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return LMLayoutManager.standardListEntryHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat properNumber = (self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height);
	
	if([LMLayoutManager isiPad]){
		properNumber = ([LMLayoutManager isLandscapeiPad] ? (WINDOW_FRAME.size.height) : (WINDOW_FRAME.size.width));
	}
	
	CGFloat divisionFactorial = ([LMLayoutManager isiPhoneX] ? 14.0 : 10.0);
	
	if(section == 0){
		return properNumber/divisionFactorial + properNumber/30.0;
	}
	return properNumber/divisionFactorial;
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
	
	CGFloat divisionFactorial = ([LMLayoutManager isiPhoneX] ? 14.0 : 10.0);
	
	if(section == 0){
		if([LMLayoutManager isiPad]){
			view.heightFactorial = ([LMLayoutManager isLandscapeiPad] ? (WINDOW_FRAME.size.height) : (WINDOW_FRAME.size.width))/divisionFactorial;
		}
		else {
			view.heightFactorial = ((self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/divisionFactorial);
		}
		
		view.heightFactorial = view.heightFactorial / frame.size.height;
		view.title = @""; //self.title;
		
//		view.xIconTapSelector = @selector(tappedClose);
	}
	
	return view;
}

- (void)registerCellIdentifiers {
	if(self.totalNumberOfSections <= 0){
		self.hasRegisteredCellIdentifiers = YES;
		return;
	}
	
	int totalRows = (int)[self rawIndexForIndexPath:[NSIndexPath indexPathForRow:[self.contentsDelegate numberOfRowsForSection:self.totalNumberOfSections-1 forSectionTableView:self] inSection:self.totalNumberOfSections-1]];
	
	for(int i = 0; i < totalRows; i++){
		[self registerClass:[LMTableViewCell class] forCellReuseIdentifier:[NSString stringWithFormat:@"%@Cell_%d", self.title, i]];
	}
	self.hasRegisteredCellIdentifiers = YES;
}

- (void)setTotalNumberOfSections:(NSUInteger)totalNumberOfSections {
	_totalNumberOfSections = totalNumberOfSections;
	
	if(self.listEntryArray){ //Setup has completed
		[self registerCellIdentifiers];
	}
}

- (NSUInteger)totalNumberOfSections {
	return _totalNumberOfSections;
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
		listEntry.stretchAcrossWidth = NO;
		listEntry.alignIconToLeft = NO;
//		listEntry.userInteractionEnabled = NO;
//		listEntry.iPromiseIWillHaveAnIconForYouSoon = YES; some don't have an icon like in settings, idiot
		
		[self.listEntryArray addObject:listEntry];
	}
	
	[self registerCellIdentifiers];
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

@end
