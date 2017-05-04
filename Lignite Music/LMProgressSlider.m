//
//  LMProgressSlider.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMProgressSlider.h"
#import "LMMarqueeLabel.h"
#import "NSTimer+Blocks.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMLabel.h"

@interface LMProgressSlider()<LMLayoutChangeDelegate>

/**
 The background to the background of the slider (lol), which is by default [UIColor clearColour] though can be changed in cases like the now playing screen.
 */
@property LMView *sliderBackgroundBackgroundView;

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
 The width constraint for the slider.
 */
@property NSLayoutConstraint *sliderBackgroundWidthConstraint;

/**
 The height constraint for the slider.
 */
@property NSLayoutConstraint *sliderBackgroundHeightConstraint;

/**
 The grabber view which the user uses to slide the view's progress.
 */
@property LMView *sliderGrabberView;

/**
 The amount of width to incrememt by for a tick of seconds. Calculated off of the maximum value.
 */
@property CGFloat widthIncrementPerTick;

/**
 Whether or not the progress bar is currently animating.
 */
@property BOOL animating;

/**
 The last time the bar was slid manually.
 */
@property NSTimeInterval lastTimeSlid;

/**
 The autoshrink timer which shrinks the slider automatically after 1 second of inactivity.
 */
@property NSTimer *autoShrinkTimer;

/**
 Whether or not the slider is shrunk.
 */
@property BOOL sliderIsShrunk;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

@end

@implementation LMProgressSlider

@synthesize leftText = _leftText;
@synthesize rightText = _rightText;
@synthesize lightTheme = _lightTheme;
@synthesize finalValue = _finalValue;
@synthesize value = _value;
@synthesize autoShrink = _autoShrink;

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

- (BOOL)lightTheme {
	return _lightTheme;
}

- (void)setLightTheme:(BOOL)lightTheme {
	_lightTheme = lightTheme;
	
	if(self.didLayoutConstraints){
		UIColor *bottomColour = lightTheme ? [UIColor blackColor] : [UIColor whiteColor];
		UIColor *topColour = lightTheme ? [UIColor whiteColor] : [UIColor blackColor];
		
		if(self.nowPlayingView){
			bottomColour = lightTheme ? [UIColor whiteColor] : [UIColor blackColor];
			topColour = lightTheme ? [UIColor whiteColor] : [UIColor blackColor];
		}
		
		if(self.sliderIsShrunk){
			bottomColour = topColour;
		}
		
		[UIView transitionWithView:self.leftTextBottomLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.leftTextBottomLabel.textColor = bottomColour;
		} completion:nil];
		[UIView transitionWithView:self.rightTextBottomLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.rightTextBottomLabel.textColor = bottomColour;
		} completion:nil];
		
		[UIView transitionWithView:self.leftTextBottomLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.leftTextTopLabel.textColor = topColour;
		} completion:nil];
		[UIView transitionWithView:self.rightTextBottomLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.rightTextTopLabel.textColor = topColour;
		} completion:nil];
	}
}

- (CGFloat)finalValue {
	return _finalValue;
}

- (void)setFinalValue:(CGFloat)finalValue {
	if(isinf(finalValue)){
		finalValue = 0.0;
	}
	_finalValue = finalValue;
	
	if(self.didLayoutConstraints){
		self.widthIncrementPerTick = self.frame.size.width/finalValue;
	}
}

- (void)setValue:(CGFloat)value {
	if(isnan(value)){
		value = 0.0;
	}
	_value = value;
	
	if(self.didLayoutConstraints){
		if(self.userIsInteracting || [self didJustFinishSliding] || value == 0){
			return;
		}
		
		CGFloat grabberWidth = self.sliderGrabberView.frame.size.width;
		CGFloat percentageTowards = value/self.finalValue;
		if(isinf(percentageTowards)){
			percentageTowards = 0.0;
		}
		CGFloat grabberPercent = (1.0-percentageTowards)*grabberWidth;
		
		self.sliderBackgroundWidthConstraint.constant = (self.frame.size.width*percentageTowards)+grabberPercent;
		
		[self reloadTextHighlightingConstants];
		[self animate];
	}
}

- (CGFloat)value {
	return _value;
}

- (BOOL)autoShrink {
	return _autoShrink;
}

- (void)setAutoShrink:(BOOL)autoShrink {
	_autoShrink = autoShrink;
	
	if(!self.didLayoutConstraints){
		return;
	}
	
	if(self.sliderIsShrunk && !autoShrink){
		[self setSliderAsShrunk:NO];
	}
	else if(!self.sliderIsShrunk && autoShrink){
		[self setSliderAsShrunk:YES];
	}
}

- (void)animate {
	[UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 [self layoutIfNeeded];
					 } completion:^(BOOL finished) {
						 self.animating = !finished;
					 }];
}

- (BOOL)didJustFinishSliding {
	if([[NSDate date] timeIntervalSince1970]-self.lastTimeSlid < 0.5){
		return YES;
	}
	return NO;
}

- (void)reset {
	if(self.userIsInteracting){
		return;
	}
	
	self.sliderBackgroundWidthConstraint.constant = self.sliderGrabberView.frame.size.width;
	[self reloadTextHighlightingConstants];
	[self animate];
}

- (void)setTextLabel:(LMLabel*)textLabel asShrunk:(BOOL)shrunk {
	NSLayoutConstraint *topConstraint;
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstItem == textLabel && constraint.firstAttribute == ALAxisHorizontal){
			topConstraint = constraint;
		}
	}
	
	NSLayoutConstraint *edgePinConstraint;
	BOOL edgeIsTrailing = NO;
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstItem == textLabel
		   && (constraint.firstAttribute == NSLayoutAttributeLeading || constraint.firstAttribute == NSLayoutAttributeTrailing)){
			edgePinConstraint = constraint;
			
			edgeIsTrailing = constraint.firstAttribute == NSLayoutAttributeTrailing;
		}
	}
	
	if(!topConstraint){
		NSLog(@"Top (%@) constraint not found!", topConstraint);
		return;
	}
	
//	NSLog(@"%d Current %f %f", shrunk, topConstraint.constant, bottomConstraint.constant);
	
	[UIView transitionWithView:textLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
//		bottomColour = lightTheme ? [UIColor blackColor] : [UIColor whiteColor];
//		topColour = lightTheme ? [UIColor blackColor] : [UIColor whiteColor];
		
		if(self.nowPlayingView){
			textLabel.textColor = (self.lightTheme ? [UIColor whiteColor] : [UIColor blackColor]);
		}
		else{
			textLabel.textColor = ((shrunk ? !self.lightTheme : self.lightTheme) ? [UIColor blackColor] : [UIColor whiteColor]);
		}
	} completion:nil];
	
	topConstraint.constant = shrunk ? (LMProgressSliderTopAndBottomLabelPadding) : (0);
	edgePinConstraint.constant = shrunk ? 0 : (edgeIsTrailing ? -10 : 10);
}

- (void)setSliderAsShrunk:(BOOL)shrunk {
	NSLog(@"Setting as shrunk %d", shrunk);
	[self layoutIfNeeded];
	
	self.sliderIsShrunk = shrunk;
	self.animating = YES;
	
	self.sliderBackgroundHeightConstraint.constant = self.frame.size.height * (shrunk ? (1.0/4.0) : (1.0));
	
	[self setTextLabel:self.leftTextBottomLabel asShrunk:shrunk];
	[self setTextLabel:self.rightTextBottomLabel asShrunk:shrunk];
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		self.animating = NO;
	}];
}

- (void)autoShrinkSlider {
	[self setSliderAsShrunk:YES];
}

- (void)reloadTextHighlightingConstants {
	CGFloat topLeftLabelWidth = self.sliderBackgroundWidthConstraint.constant-10;
	
	if(topLeftLabelWidth < 0){
		topLeftLabelWidth = 0;
	}
	
	self.leftTextTopLabelWidthConstraint.constant = topLeftLabelWidth > self.leftTextBottomLabel.frame.size.width ? self.leftTextBottomLabel.frame.size.width : topLeftLabelWidth;
	
	CGFloat topRightLabelWidth = self.sliderBackgroundWidthConstraint.constant-self.rightTextBottomLabel.frame.origin.x;
	self.rightTextTopLabelWidthConstraint.constant = topRightLabelWidth > 0 ? topRightLabelWidth : 0;
}

- (void)sliderGrabberPan:(UIPanGestureRecognizer*)panGestureRecognizer {
//	[self.sliderBackgroundView.layer removeAllAnimations];
	
	self.userIsInteracting = YES;
	
	if(self.sliderIsShrunk){
		[self setSliderAsShrunk:NO];
	}
	
	CGPoint rawTranslatedPoint = [panGestureRecognizer translationInView:self];
	
//	NSLog(@"%@", NSStringFromCGPoint(rawTranslatedPoint));
	
	CGPoint translatedPoint = rawTranslatedPoint;
	
	UIView *sliderGrabber = self.sliderBackgroundView;
	
	static CGFloat firstX = 0;
	static CGFloat firstY = 0;
	
	static BOOL didBeginSlidingFromLeft = NO;
	static BOOL didBeginSlidingFromRight = NO;
	
	CGFloat capFactor = self.frame.size.width/5;
	
	if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		firstX = sliderGrabber.frame.size.width;
		firstY = sliderGrabber.frame.size.height;
		
		didBeginSlidingFromRight = (firstX > self.frame.size.width-capFactor);
		didBeginSlidingFromLeft = (firstX < self.sliderGrabberView.frame.size.width+capFactor);
	}
	
	translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY);
	
	//The cap algorithm helps with scrolling it to the ends of the screen, because reaching the edges can be difficult.
	//It accelerates the scrolling speed at the far left and far right.
	
	CGFloat capFactorRightSideWidth = (capFactor * 4);
	CGFloat capFactorRightPercentage = ((translatedPoint.x-capFactorRightSideWidth)/capFactorRightSideWidth);
	CGFloat capFactorLeftPercentage = 1.0-(translatedPoint.x/capFactor);
	
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
		
		if(self.autoShrink){
			[self.autoShrinkTimer invalidate];
			
			self.autoShrinkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																	target:self
																  selector:@selector(autoShrinkSlider)
																  userInfo:nil
																   repeats:NO];
		}
	}
	
	if(self.delegate){
		CGFloat grabberWidth = self.sliderGrabberView.frame.size.width;
		
		CGFloat percentageTowards = (self.sliderBackgroundView.frame.size.width-grabberWidth)/(self.frame.size.width-(grabberWidth));
		CGFloat progress = self.finalValue*percentageTowards;
								   
		[self.delegate progressSliderValueChanged:progress isFinal:panGestureRecognizer.state == UIGestureRecognizerStateEnded];
	}
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		self.sliderBackgroundHeightConstraint.constant = self.frame.size.height;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[NSTimer scheduledTimerWithTimeInterval:0.50 block:^{
			self.sliderBackgroundHeightConstraint.constant = self.frame.size.height;
			[self setSliderAsShrunk:self.sliderIsShrunk];
			[UIView animateWithDuration:0.25 animations:^{
				[self layoutIfNeeded];
			}];
		} repeats:NO];
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		if(self.finalValue > 0){
			self.widthIncrementPerTick = self.frame.size.width/self.finalValue;
		}
		if(isnan(self.value) || isinf(self.value)){
			self.value = 0.0;
		}
		if(isnan(self.finalValue) || isinf(self.finalValue)){
			self.finalValue = 0.0;
		}
		if(!self.backgroundBackgroundColour){
			self.backgroundBackgroundColour = [UIColor clearColor];
		}
		
		self.leftTextBottomLabel = [LMLabel newAutoLayoutView];
		self.leftTextBottomLabel.text = self.leftText ? self.leftText : @"";
		self.leftTextBottomLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.leftTextBottomLabel.textColor = [UIColor blackColor];
		[self addSubview:self.leftTextBottomLabel];
		
		NSArray *leftTextBottomLabelPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.leftTextBottomLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:10];
			[self.leftTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[self.leftTextBottomLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.6];
			[self.leftTextBottomLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(0.45)];
		}];
		[LMLayoutManager addNewPortraitConstraints:leftTextBottomLabelPortraitConstraints];

		NSArray *leftTextBottomLabelLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.leftTextBottomLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:10];
			[self.leftTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[self.leftTextBottomLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.5];
			[self.leftTextBottomLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(0.45)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:leftTextBottomLabelLandscapeConstraints];
		
		
		
		self.rightTextBottomLabel = [LMLabel newAutoLayoutView];
		self.rightTextBottomLabel.text = self.rightText ? self.rightText : @"";
		self.rightTextBottomLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.rightTextBottomLabel.textColor = [UIColor blackColor];
		self.rightTextBottomLabel.textAlignment = NSTextAlignmentRight;
		[self addSubview:self.rightTextBottomLabel];
		
		NSArray *rightTextBottomLabelPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.rightTextBottomLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-10];
			[self.rightTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[self.rightTextBottomLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.6];
			[self.rightTextBottomLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(0.45)];
		}];
		[LMLayoutManager addNewPortraitConstraints:rightTextBottomLabelPortraitConstraints];
		
		NSArray *rightTextBottomLabelLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.rightTextBottomLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-10];
			[self.rightTextBottomLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[self.rightTextBottomLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.5];
			[self.rightTextBottomLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(0.45)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:rightTextBottomLabelLandscapeConstraints];
		

		
		self.sliderBackgroundBackgroundView = [LMView newAutoLayoutView];
		self.sliderBackgroundBackgroundView.backgroundColor = self.backgroundBackgroundColour;
		self.sliderBackgroundBackgroundView.hidden = YES;
//		self.sliderBackgroundBackgroundView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.sliderBackgroundBackgroundView];
		
		
		self.sliderBackgroundView = [LMView newAutoLayoutView];
		self.sliderBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		self.sliderBackgroundView.clipsToBounds = YES;
		[self addSubview:self.sliderBackgroundView];
		
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sliderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		self.sliderBackgroundHeightConstraint = [self.sliderBackgroundView autoSetDimension:ALDimensionHeight toSize:self.frame.size.height];
		self.sliderBackgroundWidthConstraint = [self.sliderBackgroundView autoSetDimension:ALDimensionWidth toSize:(self.widthIncrementPerTick*self.value) + (self.frame.size.width*(1.0/40.0))];
		
		[self.sliderBackgroundBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderBackgroundBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sliderBackgroundBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sliderBackgroundBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.sliderBackgroundView];
		
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(sliderGrabberPan:)];
		[self addGestureRecognizer:panGesture];
		
		
		self.sliderGrabberView = [LMView newAutoLayoutView];
		self.sliderGrabberView.backgroundColor = [UIColor whiteColor]; //[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
		[self.sliderBackgroundView addSubview:self.sliderGrabberView];
		
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sliderGrabberView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sliderGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/40.0)]; //Change the sliderBackgroundWidthConstraint initial value too with this multiplier
		
		
		self.rightTextTopLabel = [LMLabel newAutoLayoutView];
		self.rightTextTopLabel.text = self.rightTextBottomLabel.text;
		self.rightTextTopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.rightTextTopLabel.textColor = [UIColor whiteColor];
		self.rightTextTopLabel.textAlignment = NSTextAlignmentRight;
		self.rightTextTopLabel.clipsToBounds = YES;
		self.rightTextTopLabel.lineBreakMode = NSLineBreakByClipping;
		[self.sliderBackgroundView addSubview:self.rightTextTopLabel];
		
		[self.rightTextTopLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.rightTextBottomLabel];
		[self.rightTextTopLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rightTextBottomLabel];
		[self.rightTextTopLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.rightTextBottomLabel];
		[self.rightTextTopLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.rightTextBottomLabel];
		
		
		
		self.leftTextTopLabel = [LMLabel newAutoLayoutView];
		self.leftTextTopLabel.text = self.leftTextBottomLabel.text;
		self.leftTextTopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
		self.leftTextTopLabel.textColor = [UIColor whiteColor];
		self.leftTextTopLabel.textAlignment = NSTextAlignmentLeft;
		self.leftTextTopLabel.lineBreakMode = NSLineBreakByClipping;
		[self.sliderBackgroundView addSubview:self.leftTextTopLabel];
		
		[self.leftTextTopLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.leftTextBottomLabel];
		self.leftTextTopLabelWidthConstraint = [self.leftTextTopLabel autoSetDimension:ALDimensionWidth toSize:0];
		[self.leftTextTopLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.leftTextBottomLabel];
		[self.leftTextTopLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.leftTextBottomLabel];
		
		[self setLightTheme:self.lightTheme];
		
		[self setSliderAsShrunk:self.autoShrink];
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^() {
			self.value = self.value;
		} repeats:NO];
	}
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
