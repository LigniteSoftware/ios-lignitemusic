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
 The text label which goes to the left of the view and below the dragger view.
 */
@property LMLabel *leftTextBottomLabel;

/**
 The text label which goes to the right of the view and below the dragger view.
 */
@property LMLabel *rightTextBottomLabel;

/**
 The text label which goes to the left of the view and above the dragger view.
 */
@property LMLabel *leftTextTopLabel;

/**
 The width constraint for the left text top label.
 */
@property NSLayoutConstraint *leftTextTopLabelWidthConstraint;

/**
 The text label which goes to the right of the view and above the dragger view.
 */
@property LMLabel *rightTextTopLabel;

/**
 The width constraint for the right text top label.
 */
@property NSLayoutConstraint *rightTextTopLabelWidthConstraint;

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
	
	float topRightLabelWidth = self.sliderBackgroundWidthConstraint.constant-self.rightTextBottomLabel.frame.origin.x;
	self.rightTextTopLabelWidthConstraint.constant = topRightLabelWidth > 0 ? topRightLabelWidth : 0;
	
	float topLeftLabelWidth = self.sliderBackgroundWidthConstraint.constant-self.sliderGrabberView.frame.size.width/2;
	self.leftTextTopLabelWidthConstraint.constant = topLeftLabelWidth > self.leftTextBottomLabel.frame.size.width ? self.leftTextBottomLabel.frame.size.width : topLeftLabelWidth;
	[self layoutIfNeeded];
	
	
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour lightGrayBackgroundColour];
		
		self.leftTextBottomLabel = [LMLabel newAutoLayoutView];
		self.leftTextBottomLabel.text = @"Left Text";
		self.leftTextBottomLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.leftTextBottomLabel.textColor = [UIColor blackColor];
		[self addSubview:self.leftTextBottomLabel];
		
		[self.leftTextBottomLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:10];
		[self.leftTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.leftTextBottomLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.leftTextBottomLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
		
		
		
		self.rightTextBottomLabel = [LMLabel newAutoLayoutView];
		self.rightTextBottomLabel.text = @"Right Text";
		self.rightTextBottomLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.rightTextBottomLabel.textColor = [UIColor blackColor];
		[self addSubview:self.rightTextBottomLabel];
		
		[self.rightTextBottomLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-10];
		[self.rightTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.rightTextBottomLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.rightTextBottomLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
		
		
		
		self.sliderBackgroundView = [UIView newAutoLayoutView];
		self.sliderBackgroundView.backgroundColor = [UIColor cyanColor];
		[self addSubview:self.sliderBackgroundView];
		
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		self.sliderBackgroundWidthConstraint = [self.sliderBackgroundView autoSetDimension:ALDimensionWidth toSize:80];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(sliderGrabberPan:)];
		[self.sliderBackgroundView addGestureRecognizer:panGesture];
		
		
		
		self.sliderGrabberView = [UIView newAutoLayoutView];
		self.sliderGrabberView.backgroundColor = [UIColor redColor];
		[self.sliderBackgroundView addSubview:self.sliderGrabberView];
		
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sliderGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/20.0)];
		
		
		
		self.rightTextTopLabel = [LMLabel newAutoLayoutView];
		self.rightTextTopLabel.text = @"Right Text";
		self.rightTextTopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.rightTextTopLabel.textColor = [UIColor whiteColor];
		self.rightTextTopLabel.textAlignment = NSTextAlignmentLeft;
//		self.rightTextTopLabel.backgroundColor = [UIColor yellowColor];
		self.rightTextTopLabel.lineBreakMode = NSLineBreakByClipping;
		[self addSubview:self.rightTextTopLabel];
		
		[self.rightTextTopLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.rightTextBottomLabel];
		[self.rightTextTopLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		self.rightTextTopLabelWidthConstraint = [self.rightTextTopLabel autoSetDimension:ALDimensionWidth toSize:0];
		[self.rightTextTopLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.rightTextTopLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
		
		
		
		self.leftTextTopLabel = [LMLabel newAutoLayoutView];
		self.leftTextTopLabel.text = @"Left Text";
		self.leftTextTopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.leftTextTopLabel.textColor = [UIColor whiteColor];
		self.leftTextTopLabel.textAlignment = NSTextAlignmentRight;
		//		self.rightTextTopLabel.backgroundColor = [UIColor yellowColor];
		self.leftTextTopLabel.lineBreakMode = NSLineBreakByClipping;
		[self addSubview:self.leftTextTopLabel];
		
		[self.leftTextTopLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.leftTextBottomLabel];
		[self.leftTextTopLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		self.leftTextTopLabelWidthConstraint = [self.leftTextTopLabel autoSetDimension:ALDimensionWidth toSize:0];
		[self.leftTextTopLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height/8];
		[self.leftTextTopLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-self.frame.size.height/8];
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
