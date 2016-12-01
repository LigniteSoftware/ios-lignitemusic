//
//  LMProgressSlider.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMProgressSlider.h"
#import "LMColour.h"
#import "LMLabel.h"

@interface LMProgressSlider()

/**
 The text label which goes to the left of the view.
 */
@property LMLabel *leftTextLabel;

/**
 The text label which goes to the right of the view.
 */
@property LMLabel *rightTextLabel;

/**
 The background to the slider.
 */
@property UIView *sliderBackgroundView;

/**
 The width constraint for the slider.
 */
@property NSLayoutConstraint *sliderBackgroundWidthConstraint;

/**
 The grabber view which the user uses to slide the view's progress.
 */
@property UIView *sliderGrabberView;

@end

@implementation LMProgressSlider

- (void)sliderGrabberPan:(UIPanGestureRecognizer*)panGestureRecognizer {
	CGPoint rawTranslatedPoint = [panGestureRecognizer translationInView:self];
	
	CGPoint translatedPoint = rawTranslatedPoint;
	
	UIView *sliderGrabber = self.sliderGrabberView;
	
	static float firstX = 0;
	static float firstY = 0;
	
	if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan) {
		firstX = sliderGrabber.frame.origin.x;
		firstY = sliderGrabber.frame.origin.y;
	}
	
	translatedPoint = CGPointMake(firstX+translatedPoint.x+self.sliderGrabberView.frame.size.width, firstY);
	
	//The cap algorithm helps with scrolling it to the ends of the screen, because reaching the edges can be difficult.
	//It accelerates the scrolling speed at the far left and far right.
	
	float capFactor = self.frame.size.width/5;
	float capFactorRightSideWidth = (capFactor * 4);
	float capFactorRightPercentage = ((translatedPoint.x-capFactorRightSideWidth)/capFactorRightSideWidth);
	float capFactorLeftPercentage = 1.0-(translatedPoint.x/capFactor);
	
	if(translatedPoint.x > capFactorRightSideWidth && rawTranslatedPoint.x >= 0){
		translatedPoint.x += capFactorRightPercentage*fabs(translatedPoint.x);
	}
	else if(translatedPoint.x < capFactor && rawTranslatedPoint.x < 0){
		translatedPoint.x = translatedPoint.x -= capFactorLeftPercentage*capFactor;
	}
	
	if(translatedPoint.x > self.frame.size.width){
		translatedPoint.x = self.frame.size.width;
	}
	else if(translatedPoint.x-self.sliderGrabberView.frame.size.width < 0){
		translatedPoint.x = self.sliderGrabberView.frame.size.width;
	}
	
	[self layoutIfNeeded];
	self.sliderBackgroundWidthConstraint.constant = translatedPoint.x;
	[self layoutIfNeeded];
	
	
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour lightGrayBackgroundColour];
		
		self.leftTextLabel = [LMLabel newAutoLayoutView];
		self.leftTextLabel.text = @"Left Text";
		self.leftTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.leftTextLabel.textColor = [UIColor blackColor];
		[self addSubview:self.leftTextLabel];
		
		[self.leftTextLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.leftTextLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.leftTextLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.leftTextLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
		
		
		
		self.rightTextLabel = [LMLabel newAutoLayoutView];
		self.rightTextLabel.text = @"Right Text";
		self.rightTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.rightTextLabel.textColor = [UIColor blackColor];
		[self addSubview:self.rightTextLabel];
		
		[self.rightTextLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.rightTextLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.rightTextLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.rightTextLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
		
		
		
		self.sliderBackgroundView = [UIView newAutoLayoutView];
		self.sliderBackgroundView.backgroundColor = [UIColor cyanColor];
		[self addSubview:self.sliderBackgroundView];
		
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		self.sliderBackgroundWidthConstraint = [self.sliderBackgroundView autoSetDimension:ALDimensionWidth toSize:80];
		
		
		
		self.sliderGrabberView = [UIView newAutoLayoutView];
		self.sliderGrabberView.backgroundColor = [UIColor redColor];
		[self.sliderBackgroundView addSubview:self.sliderGrabberView];
		
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sliderGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/20.0)];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(sliderGrabberPan:)];
		[self.sliderBackgroundView addGestureRecognizer:panGesture];
		
		
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
