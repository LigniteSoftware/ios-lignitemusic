//
//  LMSearchViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchViewController.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMSearchBar.h"
#import "LMSettings.h"

@interface LMSearchViewController () <LMSearchBarDelegate, LMSearchSelectedDelegate, LMLayoutChangeDelegate>

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

/**
 The background view to the status bar.
 */
@property UIView *statusBarBackgroundView;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The current search term.
 */
@property NSString *currentSearchTerm;

@end

@implementation LMSearchViewController

- (BOOL)prefersStatusBarHidden {
	return [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)searchEntryTappedWithPersistentID:(LMMusicTrackPersistentID)persistentID withMusicType:(LMMusicType)musicType {
	[self.searchSelectedDelegate searchEntryTappedWithPersistentID:persistentID withMusicType:musicType];
	
	NSLog(@"Dismiss");
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	self.currentSearchTerm = searchTerm;
	
	[self.searchView searchTermChangedTo:searchTerm];
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.view layoutIfNeeded];
	
	self.searchBarBottomConstraint.constant = -keyboardHeight;
	
	[UIView animateWithDuration:0.10 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	self.statusBarBackgroundView.hidden = size.width > size.height; //Will be landscape
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.searchView searchTermChangedTo:self.currentSearchTerm];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.searchView searchTermChangedTo:self.currentSearchTerm];
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	self.currentSearchTerm = @"";
	
	
	self.searchBar = [LMSearchBar newAutoLayoutView];
	self.searchBar.delegate = self;
	[self.view addSubview:self.searchBar];
	
	self.searchBarBottomConstraint = [self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	NSArray *searchBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/14.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:searchBarPortraitConstraints];
	
	NSArray *searchBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.searchBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/14.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:searchBarLandscapeConstraints];
	
	
	self.searchView = [LMSearchView newAutoLayoutView];
	self.searchView.searchSelectedDelegate = self;
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.searchView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.searchView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.searchBar];
	
	
	self.statusBarBackgroundView = [UIView newAutoLayoutView];
	self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.statusBarBackgroundView];
	
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.statusBarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.statusBarBackgroundView autoSetDimension:ALDimensionHeight toSize:20.0f];
	
	self.statusBarBackgroundView.hidden = self.layoutManager.isLandscape;
	
	
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^() {
		[self.searchBar showKeyboard];
	} repeats:NO];
}

- (void)dealloc {
	[LMLayoutManager removeAllConstraintsRelatedToView:self.searchBar];
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
