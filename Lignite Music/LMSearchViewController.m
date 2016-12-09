//
//  LMSearchViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchViewController.h"
#import "LMSearchView.h"
#import "LMSearchBar.h"

@interface LMSearchViewController () <LMSearchBarDelegate>

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
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.searchView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.searchBar];
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.searchBar showKeyboard];
	}];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load search view controller's view");
	
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
