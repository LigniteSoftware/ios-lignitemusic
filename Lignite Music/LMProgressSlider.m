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

/**
 The amount of width to incrememt by for a tick of seconds. Calculated off of the maximum value.
 */
@property float widthIncrementPerTick;

/**
 Whether or not the progress bar is currently animating.
 */
@property BOOL animating;

/**
 The last time the bar was slid manually.
 */
@property NSTimeInterval lastTimeSlid;

@end

@implementation LMProgressSlider

@synthesize leftText = _leftText;
@synthesize rightText = _rightText;
@synthesize finalValue = _finalValue;

- (NSString*)leftText {
	return _leftText;
}

- (void)setLeftText:(NSString *)leftText {
	leftText = leftText ? leftText : @"";
	
	_leftText = leftText;
	
	if(self.didLayoutConstraints){
		self.leftTextBottomLabel.text = leftText;
		self.leftTextTopLabel.text = leftText;
	}
}

- (NSString*)rightText {
	return _rightText;
}

- (void)setRightText:(NSString *)rightText {
	rightText = rightText ? rightText : @"";
	
	_rightText = rightText;
	
	if(self.didLayoutConstraints){
		self.rightTextBottomLabel.text = rightText;
		self.rightTextTopLabel.text = rightText;
	}
}

- (float)finalValue {
	return _finalValue;
}

- (void)setFinalValue:(float)finalValue {
	_finalValue = finalValue;
	
	if(self.didLayoutConstraints){
		self.widthIncrementPerTick = self.frame.size.width/finalValue;
	}
}

- (void)animate {
	[UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 [self layoutIfNeeded];
					 } completion:^(BOOL finished) {
						 self.animating = finished;
					 }];
}

- (BOOL)didJustFinishSliding {
	NSLog(@"%f", [[NSDate date] timeIntervalSince1970]-self.lastTimeSlid);
	if([[NSDate date] timeIntervalSince1970]-self.lastTimeSlid < 0.5){
		return YES;
	}
	return NO;
}

- (void)tick {
	if(self.userIsInteracting || [self didJustFinishSliding]){
		return;
	}
	
	self.sliderBackgroundWidthConstraint.constant += self.widthIncrementPerTick;
	[self reloadTextHighlightingConstants];
	[self animate];
}

- (void)reset {
	if(self.userIsInteracting){
		return;
	}
	
	self.sliderBackgroundWidthConstraint.constant = self.sliderGrabberView.frame.size.width;
	[self reloadTextHighlightingConstants];
	[self animate];
}

- (void)reloadTextHighlightingConstants {
	float topRightLabelWidth = self.sliderBackgroundWidthConstraint.constant-self.rightTextBottomLabel.frame.origin.x;
	self.rightTextTopLabelWidthConstraint.constant = topRightLabelWidth > 0 ? topRightLabelWidth : 0;
	
	float topLeftLabelWidth = self.sliderBackgroundWidthConstraint.constant-self.sliderGrabberView.frame.size.width;
	self.leftTextTopLabelWidthConstraint.constant = topLeftLabelWidth > self.leftTextBottomLabel.frame.size.width ? self.leftTextBottomLabel.frame.size.width : topLeftLabelWidth;
}

- (void)sliderGrabberPan:(UIPanGestureRecognizer*)panGestureRecognizer {
	[self.sliderBackgroundView.layer removeAllAnimations];
	
	self.userIsInteracting = YES;
	
	CGPoint rawTranslatedPoint = [panGestureRecognizer translationInView:self];
	
//	NSLog(@"%@", NSStringFromCGPoint(rawTranslatedPoint));
	
	CGPoint translatedPoint = rawTranslatedPoint;
	
	UIView *sliderGrabber = self.sliderBackgroundView;
	
	static float firstX = 0;
	static float firstY = 0;
	
	static BOOL didBeginSlidingFromLeft = NO;
	static BOOL didBeginSlidingFromRight = NO;
	
	float capFactor = self.frame.size.width/5;
	
	if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		firstX = sliderGrabber.frame.size.width;
		firstY = sliderGrabber.frame.size.height;
		
		didBeginSlidingFromRight = (firstX > self.frame.size.width-capFactor);
		didBeginSlidingFromLeft = (firstX < self.sliderGrabberView.frame.size.width+capFactor);
	}
	
	translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY);
	
	//The cap algorithm helps with scrolling it to the ends of the screen, because reaching the edges can be difficult.
	//It accelerates the scrolling speed at the far left and far right.
	
	float capFactorRightSideWidth = (capFactor * 4);
	float capFactorRightPercentage = ((translatedPoint.x-capFactorRightSideWidth)/capFactorRightSideWidth);
	float capFactorLeftPercentage = 1.0-(translatedPoint.x/capFactor);
	
	if(translatedPoint.x > capFactorRightSideWidth && !didBeginSlidingFromRight){
		translatedPoint.x += capFactorRightPercentage*fabs(translatedPoint.x);
	}
	else if(translatedPoint.x < capFactor && !didBeginSlidingFromLeft){
		translatedPoint.x -= capFactorLeftPercentage*capFactor;
	}
	
	if(translatedPoint.x > capFactor){
		didBeginSlidingFromLeft = NO;
	}
	
	if(translatedPoint.x < capFactorRightSideWidth){
		didBeginSlidingFromRight = NO;
	}
	
	if(translatedPoint.x > self.frame.size.width){
		translatedPoint.x = self.frame.size.width;
	}
	else if(translatedPoint.x-self.sliderGrabberView.frame.size.width < 0){
		translatedPoint.x = self.sliderGrabberView.frame.size.width;
	}
	
	if(!self.animating){
		[self layoutIfNeeded];
	}
	self.sliderBackgroundWidthConstraint.constant = translatedPoint.x;
	[self reloadTextHighlightingConstants];
	if(!self.animating){
		[self layoutIfNeeded];
	}
	
	if(panGestureRecognizer.state == UIGestureRecognizerStateEnded){
		didBeginSlidingFromLeft = NO;
		didBeginSlidingFromRight = NO;
		self.userIsInteracting = NO;
		
		self.lastTimeSlid = [[NSDate date] timeIntervalSince1970];
	}
	
	if(self.delegate){
		float grabberWidth = self.sliderGrabberView.frame.size.width;
		
		float percentageTowards = (self.sliderBackgroundView.frame.size.width-grabberWidth)/(self.frame.size.width-(grabberWidth));
		float progress = self.finalValue*percentageTowards;
								   
		[self.delegate progressSliderValueChanged:progress isFinal:panGestureRecognizer.state == UIGestureRecognizerStateEnded];
	}
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
		self.sliderBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self addSubview:self.sliderBackgroundView];
		
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		self.sliderBackgroundWidthConstraint = [self.sliderBackgroundView autoSetDimension:ALDimensionWidth toSize:0];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(sliderGrabberPan:)];
		[self.sliderBackgroundView addGestureRecognizer:panGesture];
		
		
		
		self.sliderGrabberView = [UIView newAutoLayoutView];
		self.sliderGrabberView.backgroundColor = [UIColor whiteColor];
		[self.sliderBackgroundView addSubview:self.sliderGrabberView];
		
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sliderGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/40.0)];
		
		
		
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
		
		[self reloadTextHighlightingConstants];
		[self layoutSubviews];
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
