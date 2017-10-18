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

/**
 The image view for the warning button.
 */
@property UIImageView *warningImageView;

@end

@implementation LMLandscapeNavigationBar

@synthesize mode = _mode;
@synthesize showWarningButton = _showWarningButton;

- (BOOL)showWarningButton {
	return _showWarningButton;
}

- (void)setShowWarningButton:(BOOL)showWarningButton {
	_showWarningButton = showWarningButton;

	[self setMode:self.mode];
}

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
	
	self.warningImageView.hidden = !self.showWarningButton;
	
	switch(mode){
		case LMLandscapeNavigationBarModeOnlyLogo: {
			self.backButtonImageView.hidden = YES;
			
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.logoImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			
			
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.warningImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
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
			
			
			[self.warningImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.backButtonImageView];
			[self.warningImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.logoImageView];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.warningImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			
			[self.warningImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[self.warningImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			
			
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
	if(gestureRecognizer.view == self.backButtonImageView){
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonBack];
	}
	else if(gestureRecognizer.view == self.logoImageView){
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonLogo];
	}
	else{
		[self.delegate buttonTappedOnLandscapeNavigationBar:LMLandscapeNavigationBarButtonWarning];
	}
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
		
		
		self.warningImageView = [UIImageView new];
		self.warningImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.warningImageView.image = [LMAppIcon imageForIcon:LMIconWarning];
		self.warningImageView.clipsToBounds = YES;
		self.warningImageView.userInteractionEnabled = YES;
		[self addSubview:self.warningImageView];
		
		UITapGestureRecognizer *warningImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButton:)];
		[self.warningImageView addGestureRecognizer:warningImageViewTapGestureRecognizer];
		
		
		[self setMode:self.mode];
	}
}

@end
