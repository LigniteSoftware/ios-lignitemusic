//
//  LMBoxWarningView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/31/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBoxWarningView.h"
#import "LMColour.h"
#import "LMExtras.h"

@interface LMBoxWarningView()

/**
 The view's padding.
 */
@property UIView *paddingView;

/**
 The previous offset.
 */
@property CGFloat previousOffset;

@end

@implementation LMBoxWarningView

- (void)hide {
	if(!self.showing){
		return;
	}
	
	[self.superview layoutIfNeeded];
	
	self.previousOffset = self.topToSuperviewConstraint.constant;
	self.topToSuperviewConstraint.constant = -self.frame.size.height;
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.superview layoutIfNeeded];
		self.alpha = 0;
	}];
	
	self.showing = NO;
}

- (void)show {
	if(self.showing || !self.didLayoutConstraints){
		return;
	}
	
	[self.superview layoutIfNeeded];
	
	self.topToSuperviewConstraint.constant = self.previousOffset;
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.superview layoutIfNeeded];
		self.alpha = 1;
	}];
	
	self.showing = YES;
}

- (void)reload {
	self.topToSuperviewConstraint.constant = -self.frame.size.height;
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.previousOffset = self.topToSuperviewConstraint.constant;
		
		
		self.layer.masksToBounds = YES;
		self.layer.cornerRadius = 6.0f;
		self.backgroundColor = [LMColour controlBarGrayColour];
		
		
		self.paddingView = [UIView newAutoLayoutView];
		[self addSubview:self.paddingView];
		
		[self.paddingView autoCenterInSuperview];
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeTop];
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[self.paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(9.0/10.0)];
		
		
		self.titleLabel = [UILabel newAutoLayoutView];
		self.titleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsTitle", nil);
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f];
		self.titleLabel.textColor = [UIColor blackColor];
		self.titleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.titleLabel];
		
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		
		
		self.subtitleLabel = [UILabel newAutoLayoutView];
		self.subtitleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsDescription", nil);
		self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
		self.subtitleLabel.textColor = [UIColor blackColor];
		self.subtitleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:8];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}
	else{
		if(self.hideOnLayout){
			[self hide];
			self.hideOnLayout = NO;
		}
	}
	
	[super layoutSubviews];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.showing = YES;
	}
	return self;
}

@end
