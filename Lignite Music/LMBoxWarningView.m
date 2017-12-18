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
#import "LMAppIcon.h"

@interface LMBoxWarningView()

/**
 The view's padding.
 */
@property UIView *paddingView;

/**
 The previous offset.
 */
@property CGFloat previousOffset;

/**
 The X-cross for dismissing the warning box. Fuck this shit lol.
 */
@property UIImageView *xCrossImageView;

/**
 If YES, the box will never show again.
 */
@property BOOL forceHide;

@end

@implementation LMBoxWarningView

- (void)hide {
	if(!self.showing){
		return;
	}
	
	[UIView animateWithDuration:0.3 animations:^{
		self.alpha = 0;
	}];
	
	self.showing = NO;
}

- (void)show {
	if(self.showing || !self.didLayoutConstraints || self.forceHide){
		return;
	}
	
	[UIView animateWithDuration:0.3 animations:^{
		self.alpha = 1;
	}];
	
	self.showing = YES;
}

- (void)xCrossTapped {
	[self hide];
	
	self.forceHide = YES;
	
	if([self.delegate respondsToSelector:@selector(boxWarningViewWasForceClosed:)]){
		[self.delegate boxWarningViewWasForceClosed:self];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
				
		
		self.layer.masksToBounds = YES;
		self.layer.cornerRadius = 6.0f;
		self.backgroundColor = [LMColour controlBarGrayColour];
		
		
		self.paddingView = [UIView newAutoLayoutView];
		[self addSubview:self.paddingView];
		
		CGFloat padding = 5.0f;
		
		[self.paddingView autoCentreInSuperview];
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeTop].constant = padding;
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeBottom].constant = -padding;
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeTrailing].constant = -padding;
		[self.paddingView autoPinEdgeToSuperviewMargin:ALEdgeLeading].constant = padding;
		//		[self.paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(9.0/10.0)];
		
		
		self.xCrossImageView = [UIImageView newAutoLayoutView];
		self.xCrossImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.xCrossImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconXCross]];
		self.xCrossImageView.userInteractionEnabled = YES;
		[self.paddingView addSubview:self.xCrossImageView];
		
		[self.xCrossImageView autoSetDimension:ALDimensionWidth toSize:20.0f];
		[self.xCrossImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.xCrossImageView];
		[self.xCrossImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.xCrossImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		UITapGestureRecognizer *xCrossTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(xCrossTapped)];
		[self.xCrossImageView addGestureRecognizer:xCrossTapGestureRecognizer];
		
		
		self.titleLabel = [UILabel newAutoLayoutView];
		self.titleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsTitle", nil);
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
		self.titleLabel.textColor = [UIColor blackColor];
		self.titleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.titleLabel];
		
		[self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.xCrossImageView];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
		
		
		self.subtitleLabel = [UILabel newAutoLayoutView];
		self.subtitleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsDescription", nil);
		self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
		self.subtitleLabel.textColor = [UIColor blackColor];
		self.subtitleLabel.numberOfLines = 0;
		[self.paddingView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:12];
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
