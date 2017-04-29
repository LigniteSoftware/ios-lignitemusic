//
//  LMBrowsingBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLayoutManager.h"
#import "LMBrowsingBar.h"
#import "LMAppIcon.h"
#import "LMColour.h"

@interface LMBrowsingBar()

/**
 The background view for the toggle button.
 */
@property LMView *toggleButtonBackgroundView;

/**
 The image view for the toggle button.
 */
@property UIImageView *toggleButtonImageView;

/**
 The leading constraint for the search bar, so it can be offset depending on if the user is searching or not.
 */
@property NSLayoutConstraint *searchBarLeadingConstraint;

/**
 The constraint which is tied to the width of the search button for showing/hiding letter tabs.
 */
@property NSLayoutConstraint *searchButtonWidthConstraint;

@end

@implementation LMBrowsingBar

@synthesize isInSearchMode = _isInSearchMode;
@synthesize keyboardIsShowing = _keyboardIsShowing;
@synthesize showingLetterTabs = _showingLetterTabs;

- (instancetype)init {
	self = [super init];
	if(self) {
		self.letterTabBar = [LMLetterTabBar newAutoLayoutView];
	}
	return self;
}

- (void)setIsInSearchMode:(BOOL)isInSearchMode {
	_isInSearchMode = isInSearchMode;
	
	if(self.didLayoutConstraints){
		[self layoutIfNeeded];
		
		self.searchBarLeadingConstraint.constant = self.isInSearchMode ? -self.frame.size.width : 0.0;
		
		[UIView animateWithDuration:0.25 animations:^{
			[self layoutIfNeeded];
		}];
	}
}

- (BOOL)isInSearchMode {
	return _isInSearchMode;
}

- (void)setKeyboardIsShowing:(BOOL)keyboardIsShowing {
	_keyboardIsShowing = keyboardIsShowing;
	
	if(self.searchBarDelegate){
		[self.searchBarDelegate searchDialogOpened:YES withKeyboardHeight:0];
	}
}

- (BOOL)keyboardIsShowing {
	return _keyboardIsShowing;
}

- (void)tappedToggleButton {
	NSLog(@"Is in search");
	
	self.isInSearchMode = !self.isInSearchMode;
	self.keyboardIsShowing = YES;
}

- (BOOL)showingLetterTabs {
	return _showingLetterTabs;
}

- (void)setShowingLetterTabs:(BOOL)showingLetterTabs {
	_showingLetterTabs = showingLetterTabs;
	
	[self layoutIfNeeded];
	self.searchButtonWidthConstraint.constant = showingLetterTabs ? 0 : (self.frame.size.width-self.frame.size.height);
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;

		
		self.toggleButtonBackgroundView = [LMView newAutoLayoutView];
		self.toggleButtonBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self addSubview:self.toggleButtonBackgroundView];
		
		NSArray *toggleButtonBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.toggleButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.toggleButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			self.searchButtonWidthConstraint = [self.toggleButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
			[self.toggleButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}];
		[LMLayoutManager addNewPortraitConstraints:toggleButtonBackgroundViewPortraitConstraints];
		
		NSArray *toggleButtonBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.toggleButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.toggleButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			self.searchButtonWidthConstraint = [self.toggleButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
			[self.toggleButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		}];
		[LMLayoutManager addNewLandscapeConstraints:toggleButtonBackgroundViewLandscapeConstraints];
		
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToggleButton)];
		[self.toggleButtonBackgroundView addGestureRecognizer:tapGesture];
		
		
		self.toggleButtonImageView = [UIImageView newAutoLayoutView];
		self.toggleButtonImageView.image = [LMAppIcon imageForIcon:LMIconSearch];
		self.toggleButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.toggleButtonBackgroundView addSubview:self.toggleButtonImageView];
		
		[self.toggleButtonImageView autoCenterInSuperview];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		
		
		//Is created in init
		self.letterTabBar.delegate = self.letterTabDelegate;
		[self addSubview:self.letterTabBar];
		
		NSArray *letterTabBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.letterTabBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.toggleButtonBackgroundView];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		}];
		[LMLayoutManager addNewPortraitConstraints:letterTabBarPortraitConstraints];
		
		NSArray *letterTabBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.letterTabBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.toggleButtonBackgroundView];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		}];
		[LMLayoutManager addNewLandscapeConstraints:letterTabBarLandscapeConstraints];
		
			
		
		[self bringSubviewToFront:self.toggleButtonBackgroundView];
	}
}

@end
