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

@interface LMControlBarView()

@property NSLayoutConstraint *heightConstraint;

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
	self.controlButtonViews = [NSMutableArray new];
	
	self.buttonBackgroundView = [UIView newAutoLayoutView];
	self.buttonBackgroundView.backgroundColor = [UIColor orangeColor];
	[self addSubview:self.buttonBackgroundView];
	
	[self.buttonBackgroundView autoCenterInSuperview];
	[self.buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(8.0/10.0)];
	[self.buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(9.5/10.0)];
	
	uint8_t amountOfItemsForControlBar = [self.delegate amountOfButtonsForControlBarView:self];
	for(int i = 0; i < amountOfItemsForControlBar; i++){
		UIView *lastBackgroundView = nil;
		if(self.controlButtonViews.count > 0){
			lastBackgroundView = [self.controlButtonViews objectAtIndex:i-1];
		}
		
		UIView *buttonBackgroundView = [UIView newAutoLayoutView];
		buttonBackgroundView.backgroundColor = [UIColor colorWithRed:0.0 green:0.2*(i+1) blue:0.1 alpha:1.0];
		[self.buttonBackgroundView addSubview:buttonBackgroundView];
		
		BOOL isFirstBackground = (self.controlButtonViews.count == 0);
		
		[buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[buttonBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirstBackground ? ALEdgeLeading : ALEdgeTrailing ofView:isFirstBackground ? self.buttonBackgroundView : lastBackgroundView];
		[buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBackgroundView withMultiplier:(1.0/(float)amountOfItemsForControlBar)];
		
		[self.controlButtonViews addObject:buttonBackgroundView];
	}
	
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
