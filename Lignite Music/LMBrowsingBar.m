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
 The letter tab bar for browsing through letters.
 */
@property LMLetterTabBar *letterTabBar;

/**
 The search bar.
 */
@property LMSearchBar *searchBar;

@end

@implementation LMBrowsingBar

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
		
		
		self.toggleButtonImageView = [UIImageView newAutoLayoutView];
		self.toggleButtonImageView.image = [LMAppIcon imageForIcon:LMIconSearch];
		self.toggleButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.toggleButtonBackgroundView addSubview:self.toggleButtonImageView];
		
		[self.toggleButtonImageView autoCenterInSuperview];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		[self.toggleButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.toggleButtonBackgroundView withMultiplier:(1.0/2.0)];
		
		
		self.letterTabBar = [LMLetterTabBar newAutoLayoutView];
		[self addSubview:self.letterTabBar];
		
		[self.letterTabBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.toggleButtonBackgroundView];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.letterTabBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		
		[self bringSubviewToFront:self.toggleButtonBackgroundView];
	}
}

@end
