//
//  LMLandscapeNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 4/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLandscapeNavigationBar.h"
#import "LMAppIcon.h"

@interface LMLandscapeNavigationBar()

/**
 The back button image view.
 */
@property UIImageView *backButtonImageView;

/**
 The logo image view.
 */
@property UIImageView *logoImageView;

@end

@implementation LMLandscapeNavigationBar

@synthesize mode = _mode;

- (LMLandscapeNavigationBarMode)mode {
	return _mode;
}

- (void)setMode:(LMLandscapeNavigationBarMode)mode {
	_mode = mode;
	
	if(!self.didLayoutConstraints){
		return;
	}
	
	[self.backButtonImageView removeConstraints:self.backButtonImageView.constraints];
	[self.logoImageView removeConstraints:self.logoImageView.constraints];
	[self removeConstraints:self.constraints];
	
	[self layoutIfNeeded];
	
	switch(mode){
		case LMLandscapeNavigationBarModeOnlyLogo: {
			self.backButtonImageView.hidden = YES;
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			break;
		}
		case LMLandscapeNavigationBarModeWithBackButton: {
			self.backButtonImageView.hidden = NO;
			
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
			[self.backButtonImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.backButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:0.75];
			
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.backButtonImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:2];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
			
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.logoImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			break;
		}
	}
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)tappedButton:(UIGestureRecognizer*)gestureRecognizer {
	[self.delegate buttonTappedOnLandscapeNavigationBar:(gestureRecognizer.view == self.backButtonImageView)];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.backgroundColor = [UIColor whiteColor];
		
		
		[self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
		[self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
		
		
		self.backgroundColor = [UIColor whiteColor];
		self.userInteractionEnabled = YES;
		
		self.backButtonImageView = [UIImageView new];
		self.backButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backButtonImageView.image = [LMAppIcon imageForIcon:LMIconiOSBack];
		self.backButtonImageView.clipsToBounds = YES;
		self.backButtonImageView.userInteractionEnabled = YES;
		[self addSubview:self.backButtonImageView];
		
		UITapGestureRecognizer *backButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.backButtonImageView addGestureRecognizer:backButtonTapGestureRecognizer];
		
		
		self.logoImageView = [UIImageView new];
		self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.logoImageView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
		self.logoImageView.clipsToBounds = YES;
		self.logoImageView.userInteractionEnabled = YES;
		[self addSubview:self.logoImageView];
		
		UITapGestureRecognizer *logoImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.logoImageView addGestureRecognizer:logoImageViewTapGestureRecognizer];
		
		
		[self setMode:self.mode];
	}
}

@end
