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
#import "LMTriangleView.h"

@interface LMControlBarView()

@property NSLayoutConstraint *heightConstraint;
@property NSLayoutConstraint *triangleConstraint;

@property UIView *backgroundView;
@property UIView *buttonBackgroundView;
@property LMTriangleView *triangleView;

@property NSMutableArray *controlButtonViews;

@end

@implementation LMControlBarView

- (void)updateHeightConstraintWithHeight:(float)height {
	[self.superview layoutIfNeeded];
	[self.backgroundView layoutIfNeeded];
	
	self.heightConstraint.constant = height;
	self.triangleConstraint.constant = height == 0 ? -50 : 0;
	
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
		[self.superview layoutIfNeeded];
		[self.backgroundView layoutIfNeeded];
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

- (void)tappedButtonBackgroundView:(UITapGestureRecognizer*)gestureRecognizer {
	NSLog(@"Tapped %@", gestureRecognizer.view);
	UIView *viewTapped = gestureRecognizer.view;
	uint8_t viewTappedIndex = 0;
	for(int i = 0; i < self.controlButtonViews.count; i++){
		UIView *view = [self.controlButtonViews objectAtIndex:i];
		if(view == viewTapped){
			viewTappedIndex = i;
			break;
		}
	}
	
	BOOL shouldHighlight = [self.delegate buttonTappedWithIndex:viewTappedIndex forControlBarView:self];
	[UIView animateWithDuration:0.5 animations:^{
		viewTapped.backgroundColor = shouldHighlight ? [UIColor whiteColor] : [LMColour lightGrayBackgroundColour];
	}];
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	self.userInteractionEnabled = YES;
	
	self.backgroundView = [UIView newAutoLayoutView];
	self.backgroundView.backgroundColor = [LMColour lightGrayBackgroundColour];
	self.backgroundView.layer.masksToBounds = YES;
	self.backgroundView.layer.cornerRadius = 10.0;
	self.backgroundView.userInteractionEnabled = YES;
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
	NSLog(@"%d items for control bar", amountOfItemsForControlBar);
	for(int i = 0; i < amountOfItemsForControlBar; i++){
		UIView *lastBackgroundView = nil;
		if(self.controlButtonViews.count > 0){
			lastBackgroundView = [[self.controlButtonViews objectAtIndex:i-1] superview];
		}
		
		UIView *buttonAreaView = [UIView newAutoLayoutView];
		[self.buttonBackgroundView addSubview:buttonAreaView];
		
		BOOL isFirstBackground = (self.controlButtonViews.count == 0);
		
		[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[buttonAreaView autoPinEdge:ALEdgeLeading toEdge:isFirstBackground ? ALEdgeLeading : ALEdgeTrailing ofView:isFirstBackground ? self.buttonBackgroundView : lastBackgroundView];
		[buttonAreaView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBackgroundView withMultiplier:(1.0/(float)amountOfItemsForControlBar)];
		
		UIView *buttonBackgroundView = [UIImageView newAutoLayoutView];
		buttonBackgroundView.layer.masksToBounds = YES;
		buttonBackgroundView.layer.cornerRadius = 10.0;
		buttonBackgroundView.userInteractionEnabled = YES;
		[buttonAreaView addSubview:buttonBackgroundView];
		
		[buttonBackgroundView autoCenterInSuperview];
		[buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonAreaView withMultiplier:0.8];
		[buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonAreaView withMultiplier:0.8];
		
		UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButtonBackgroundView:)];
		[buttonBackgroundView addGestureRecognizer:gestureRecognizer];
		
		UIImageView *buttonImageView = [UIImageView newAutoLayoutView];
		buttonImageView.contentMode = UIViewContentModeScaleAspectFit;
		buttonImageView.image = [self.delegate imageWithIndex:i forControlBarView:self];
		[buttonBackgroundView addSubview:buttonImageView];
		
		[buttonImageView autoCenterInSuperview];
		[buttonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonBackgroundView withMultiplier:0.5];
		[buttonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonBackgroundView withMultiplier:0.5];
		
		[self.controlButtonViews addObject:buttonBackgroundView];
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
	
	self.triangleView = [LMTriangleView newAutoLayoutView];
	self.triangleView.backgroundColor = [UIColor whiteColor];
	[self.backgroundView addSubview:self.triangleView];
	
	[self.triangleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.triangleConstraint = [self.triangleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.triangleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.backgroundView withMultiplier:(1.0/10.0)];
	[self.triangleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundView withMultiplier:(1.0/6.0)];
	
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
