//
//  LMBrowsingBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingBar.h"
#import "LMAppIcon.h"
#import "LMColour.h"

@interface LMBrowsingBar()

/**
 The background view for the toggle button.
 */
@property UIView *toggleButtonBackgroundView;

/**
 The image view for the toggle button.
 */
@property UIImageView *toggleButtonImageView;

/**
 The leading constraint for the search bar, so it can be offset depending on if the user is searching or not.
 */
@property NSLayoutConstraint *searchBarLeadingConstraint;

@end

@implementation LMBrowsingBar

- (void)tappedToggleButton {
	[self layoutIfNeeded];
	
	self.isInSearchMode = !self.isInSearchMode;
	
	self.searchBarLeadingConstraint.constant = self.isInSearchMode ? -self.letterTabBar.frame.size.width : 0.0;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	}];
	
	self.toggleButtonImageView.image = self.isInSearchMode ? [LMAppIcon imageForIcon:LMIconSearch] : [LMAppIcon imageForIcon:LMIconAToZ];
	
	self.isInSearchMode ? [self.searchBar showKeyboard] : [self.searchBar dismissKeyboard];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;

		
		self.toggleButtonBackgroundView = [UIView newAutoLayoutView];
		self.toggleButtonBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self addSubview:self.toggleButtonBackgroundView];
		
		[self.toggleButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.toggleButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.toggleButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
		[self.toggleButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToggleButton)];
		[self.toggleButtonBackgroundView addGestureRecognizer:tapGesture];
		
		
		self.toggleButtonImageView = [UIImageView newAutoLayoutView];
		self.toggleButtonImageView.image = [LMAppIcon imageForIcon:LMIconSearch];
		self.toggleButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.toggleButtonBackgroundView addSubview:self.toggleButtonImageView];
		
		[self.toggleButtonImageView autoCenterInSuperview];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		
		
		self.letterTabBar = [LMLetterTabBar newAutoLayoutView];
		self.letterTabBar.delegate = self.letterTabDelegate;
		[self addSubview:self.letterTabBar];
		
		[self.letterTabBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.toggleButtonBackgroundView];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		
		self.searchBar = [LMSearchBar newAutoLayoutView];
		self.searchBar.delegate = self.searchBarDelegate;
		[self addSubview:self.searchBar];
		
		self.searchBarLeadingConstraint = [self.searchBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.searchBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.searchBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.letterTabBar];
		
		
		[self bringSubviewToFront:self.toggleButtonBackgroundView];
	}
}

@end
