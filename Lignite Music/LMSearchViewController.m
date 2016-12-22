//
//  LMSearchViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchViewController.h"
#import "LMSearchBar.h"
#import "LMSettings.h"
#import "NSTimer+Blocks.h"

@interface LMSearchViewController () <LMSearchBarDelegate, LMSearchSelectedDelegate>

/**
 The search bar for user input.
 */
@property LMSearchBar *searchBar;

/**
 The bottom constraint for the search bar.
 */
@property NSLayoutConstraint *searchBarBottomConstraint;

/**
 The actual search view where the magic happens.
 */
@property LMSearchView *searchView;

@end

@implementation LMSearchViewController

- (BOOL)prefersStatusBarHidden {
	BOOL shown = [LMSettings shouldShowStatusBar];
	
	return !shown;
}

- (void)searchEntryTappedWithPersistentID:(LMMusicTrackPersistentID)persistentID withMusicType:(LMMusicType)musicType {
	[self.searchSelectedDelegate searchEntryTappedWithPersistentID:persistentID withMusicType:musicType];
	
	NSLog(@"Dismiss");
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	[self.searchView searchTermChangedTo:searchTerm];
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.view layoutIfNeeded];
	
	self.searchBarBottomConstraint.constant = -keyboardHeight;
	
	[UIView animateWithDuration:0.10 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	
	self.searchBar = [LMSearchBar newAutoLayoutView];
	self.searchBar.delegate = self;
	[self.view addSubview:self.searchBar];
	
	self.searchBarBottomConstraint = [self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/14.0)];
	
	
	self.searchView = [LMSearchView newAutoLayoutView];
	self.searchView.searchSelectedDelegate = self;
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.searchView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.searchBar];
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^() {
		[self.searchBar showKeyboard];
	} repeats:NO];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load search view controller's view");
	
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.automaticallyAdjustsScrollViewInsets = YES;
}

@end
