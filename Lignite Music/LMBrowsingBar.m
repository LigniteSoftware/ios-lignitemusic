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

@interface LMBrowsingBar()

/**
 The background view for the search button.
 */
@property UIView *searchButtonBackgroundView;

/**
 The image view for the search button.
 */
@property UIImageView *searchButtonImageView;

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
		
		self.letterTabBar = [LMLetterTabBar newAutoLayoutView];
		[self addSubview:self.letterTabBar];
		
		[self.letterTabBar autoPinEdgesToSuperviewEdges];
	}
}

@end
