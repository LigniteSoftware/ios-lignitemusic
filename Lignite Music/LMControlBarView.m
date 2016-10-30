//
//  LMControlBarView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMControlBarView.h"
#import "LMExtras.h"
#import "LMColour.h"
#import "YIInnerShadowView.h"

@interface LMControlBarView()

@property NSLayoutConstraint *heightConstraint;

@property UIView *backgroundView;
@property UIView *buttonBackgroundView;

@property NSMutableArray *controlButtonViews;

@end

@implementation LMControlBarView

- (void)updateHeightConstraintWithHeight:(float)height {
	[self.superview layoutIfNeeded];
	
	self.heightConstraint.constant = height;
	
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
		[self.superview layoutIfNeeded];
	} completion:nil];
}

- (void)open {
	[self updateHeightConstraintWithHeight:WINDOW_FRAME.size.height/8];
}

- (void)close {
	[self updateHeightConstraintWithHeight:0];
}

- (void)invert {
	self.heightConstraint.constant == 0 ? [self open] : [self close];
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	
	self.backgroundView = [UIView newAutoLayoutView];
	self.backgroundView.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
	self.backgroundView.layer.masksToBounds = YES;
	self.backgroundView.layer.cornerRadius = 10.0;
	[self addSubview:self.backgroundView];
	
	[self.backgroundView autoCenterInSuperview];
	[self.backgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	
	self.controlButtonViews = [NSMutableArray new];
	
	self.buttonBackgroundView = [UIView newAutoLayoutView];
	[self addSubview:self.buttonBackgroundView];
	
	[self.buttonBackgroundView autoCenterInSuperview];
	[self.buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(8.0/10.0)];
	[self.buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	
	uint8_t amountOfItemsForControlBar = [self.delegate amountOfButtonsForControlBarView:self];
	for(int i = 0; i < amountOfItemsForControlBar; i++){
		UIView *lastBackgroundView = nil;
		if(self.controlButtonViews.count > 0){
			lastBackgroundView = [self.controlButtonViews objectAtIndex:i-1];
		}
		
		UIView *buttonAreaView = [UIView newAutoLayoutView];
		[self.buttonBackgroundView addSubview:buttonAreaView];
		
		BOOL isFirstBackground = (self.controlButtonViews.count == 0);
		
		[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[buttonAreaView autoPinEdge:ALEdgeLeading toEdge:isFirstBackground ? ALEdgeLeading : ALEdgeTrailing ofView:isFirstBackground ? self.buttonBackgroundView : lastBackgroundView];
		[buttonAreaView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBackgroundView withMultiplier:(1.0/(float)amountOfItemsForControlBar)];
		
		UIView *buttonBackgroundView = [UIImageView newAutoLayoutView];
		buttonBackgroundView.backgroundColor = [UIColor whiteColor];
		buttonBackgroundView.layer.masksToBounds = YES;
		buttonBackgroundView.layer.cornerRadius = 10.0;
		[buttonAreaView addSubview:buttonBackgroundView];
		
		[buttonBackgroundView autoCenterInSuperview];
		[buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonAreaView withMultiplier:0.8];
		[buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonAreaView withMultiplier:0.8];
		
		UIImageView *buttonImageView = [UIImageView newAutoLayoutView];
		buttonImageView.contentMode = UIViewContentModeScaleAspectFit;
		buttonImageView.image = [self.delegate imageWithIndex:i forControlBarView:self];
		[buttonBackgroundView addSubview:buttonImageView];
		
		[buttonImageView autoCenterInSuperview];
		[buttonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonBackgroundView withMultiplier:0.5];
		[buttonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonBackgroundView withMultiplier:0.5];
		
		[self.controlButtonViews addObject:buttonAreaView];
	}
	
	YIInnerShadowView* innerShadowView = [YIInnerShadowView newAutoLayoutView];
	innerShadowView.shadowRadius = 4;
	innerShadowView.shadowMask = YIInnerShadowMaskAll;
	innerShadowView.cornerRadius = 8.0;
	[self.backgroundView addSubview:innerShadowView];
	
	[innerShadowView autoCenterInSuperview];
	[innerShadowView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[innerShadowView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[innerShadowView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[innerShadowView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	self.heightConstraint = [self autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/8];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
