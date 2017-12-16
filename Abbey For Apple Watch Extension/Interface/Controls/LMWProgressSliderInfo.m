//
//  LMWProgressSliderInfo.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import "LMWProgressSliderInfo.h"

@interface LMWProgressSliderInfo()

/**
 The actual progress bar.
 */
@property WKInterfaceGroup *progressBar;

/**
 The container that contains the progress bar and is shaded gray.
 */
@property WKInterfaceGroup *container;

/**
 The interface controller that contains the progress bar.
 */
@property WKInterfaceController *interfaceController;

/**
 The current size of the progress bar.
 */
@property CGSize size;

/**
 Whether or not the progress slider is currently shrunk.
 */
@property BOOL isShrunk;

/**
 The width of the grabber that is on the tip of the progress bar.
 */
@property (readonly) CGFloat grabberWidth;

/**
 Whether or not the user is interacting. If YES, all setPercentage:animated: calls will be ignored.
 */
@property BOOL userIsInteracting;

@end

@implementation LMWProgressSliderInfo

@synthesize grabberWidth = _grabberWidth;
@synthesize isShrunk = _isShrunk;

- (CGFloat)grabberWidth {
	return 8.0f;
}

- (void)setWidthOfSlider:(CGFloat)width animated:(BOOL)animated {
	self.size = CGSizeMake(width, self.size.height);
	
	if(animated){
		[self.interfaceController animateWithDuration:0.5 animations:^{
			[self.progressBar setWidth:width];
		}];
	}
	else{
		[self.progressBar setWidth:width];
	}
}

- (void)setPercentage:(CGFloat)percentage animated:(BOOL)animated {
	if(self.userIsInteracting){
		return;
	}
	
	[self setWidthOfSlider:self.width * percentage
				  animated:animated];
}

- (void)setIsShrunk:(BOOL)isShrunk {
	_isShrunk = isShrunk;
	
	[self.interfaceController animateWithDuration:0.2 animations:^{
		[self.container setRelativeHeight:isShrunk ? 1.0 : 1.0
						   withAdjustment:0];
	}];
}

- (BOOL)isShrunk {
	return _isShrunk;
}

- (void)handleProgressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer {	
	self.userIsInteracting = YES;
	
	if(self.isShrunk){
		[self setIsShrunk:NO];
	}
	
	CGPoint rawTranslatedPoint = panGestureRecognizer.translationInObject;
	
	CGPoint translatedPoint = rawTranslatedPoint;
	
	static CGFloat firstX = 0;
	
	static BOOL didBeginSlidingFromLeft = NO;
	static BOOL didBeginSlidingFromRight = NO;
	
	CGFloat capFactor = self.interfaceController.contentFrame.size.width/5;
	
	if (panGestureRecognizer.state == WKGestureRecognizerStateBegan) {
		firstX = self.size.width;
		
		didBeginSlidingFromRight = (firstX > self.interfaceController.contentFrame.size.width-capFactor);
		didBeginSlidingFromLeft = (firstX < self.size.width+capFactor);
	}
	
	translatedPoint = CGPointMake(firstX+translatedPoint.x, 0);
	
	//The cap algorithm helps with scrolling it to the ends of the screen, because reaching the edges can be difficult.
	//It accelerates the scrolling speed at the far left and far right.
	
	CGFloat capFactorRightSideWidth = (capFactor * 4);
	CGFloat capFactorRightPercentage = ((translatedPoint.x-capFactorRightSideWidth)/capFactorRightSideWidth);
	CGFloat capFactorLeftPercentage = 1.0-(translatedPoint.x/capFactor);
	
	if(translatedPoint.x > capFactorRightSideWidth && !didBeginSlidingFromRight){
		translatedPoint.x += capFactorRightPercentage * fabs(translatedPoint.x);
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
	
	if(translatedPoint.x > self.interfaceController.contentFrame.size.width){
		translatedPoint.x = self.interfaceController.contentFrame.size.width;
	}
	else if(translatedPoint.x < self.grabberWidth){
		translatedPoint.x = self.grabberWidth;
	}
	
	[self setWidthOfSlider:translatedPoint.x animated:NO];
	
	if(panGestureRecognizer.state == WKGestureRecognizerStateEnded){
		didBeginSlidingFromLeft = NO;
		didBeginSlidingFromRight = NO;
		
		self.userIsInteracting = NO;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self setIsShrunk:YES];
			}];
		});
		
		if(self.delegate){
			CGFloat percentageTowards = (self.size.width-self.grabberWidth)/(self.interfaceController.contentFrame.size.width-self.grabberWidth);
			
			[self.delegate progressSliderWithInfo:self slidToNewPositionWithPercentage:percentageTowards];
		}
	}
}

- (instancetype)initWithProgressBarGroup:(WKInterfaceGroup*)progressBarGroup
							 inContainer:(WKInterfaceGroup*)containerGroup
				   onInterfaceController:(WKInterfaceController*)interfaceController {
	
	self = [super init];
	if(self){
		self.progressBar = progressBarGroup;
		self.container = containerGroup;
		self.interfaceController = interfaceController;
		self.isShrunk = YES;
		
		self.width = self.interfaceController.contentFrame.size.width;
		
		self.size = CGSizeMake(0, 24);
	}
	return self;
}

@end
