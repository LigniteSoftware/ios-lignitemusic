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

@interface LMBoxWarningView()

/**
 The view's padding.
 */
@property UIView *paddingView;

@end

@implementation LMBoxWarningView

- (void)hide {
	[self.superview layoutIfNeeded];
	
	self.topToSuperviewConstraint.constant = -self.frame.size.height;
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.superview layoutIfNeeded];
		self.alpha = 0;
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
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
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22.0f];
		self.titleLabel.textColor = [UIColor blackColor];
		self.titleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.titleLabel];
		
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		
		
		self.subtitleLabel = [UILabel newAutoLayoutView];
		self.subtitleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsDescription", nil);
		self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
		self.subtitleLabel.textColor = [UIColor blackColor];
		self.subtitleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:8];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}
	
	[super layoutSubviews];
}

@end
