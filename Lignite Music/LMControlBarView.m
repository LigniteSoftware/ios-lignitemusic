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
#import "LMAppIcon.h"

@interface LMControlBarView()

@property NSLayoutConstraint *controlBarHeightConstraint;
@property NSLayoutConstraint *triangleConstraint;

@property UIView *backgroundView;
@property UIView *buttonBackgroundView;

@property LMTriangleView *triangleView;
@property UIImageView *threeDotIconImageView;

@property NSMutableArray *controlButtonViews;

/**
 To prevent any collisions in animating button views and state changes.
 */
@property UIView *viewCurrentlyAnimating;

@end

@implementation LMControlBarView

+ (float)heightWhenIsOpened:(BOOL)isOpened {
	return WINDOW_FRAME.size.height/(isOpened ? 8 : 50);
}

- (void)updateHeightConstraintWithHeight:(float)height animated:(BOOL)animated {
	[self.backgroundView layoutIfNeeded];
	[self layoutIfNeeded];
	
	self.isOpen = (height != 0);
		
	self.triangleConstraint.constant = self.isOpen ? -2 : -50;
	self.controlBarHeightConstraint.constant = height;
	
	if(animated){
		[UIView animateWithDuration:0.3 animations:^{
			[self.backgroundView layoutIfNeeded];
			[self layoutIfNeeded];
		}];
	}
	else{
		[self.backgroundView layoutIfNeeded];
		[self layoutIfNeeded];
	}
	
	if(animated){
		[self.delegate sizeChangedTo:CGSizeMake(0, [LMControlBarView heightWhenIsOpened:self.isOpen]) forControlBarView:self];
	}
}

- (void)open:(BOOL)animated {
	[self updateHeightConstraintWithHeight:WINDOW_FRAME.size.height/8 animated:animated];
}

- (void)close:(BOOL)animated {
	[self updateHeightConstraintWithHeight:0 animated:animated];
}

- (void)invert:(BOOL)animated {
	self.isOpen ? [self close:animated] : [self open:animated];
}

- (void)animatedInvert {
	[self invert:YES];
}

- (void)buttonHighlightStatusUpdate:(UIView*)viewChecking wasJustTapped:(BOOL)wasJustTapped {	
	uint8_t viewCheckingIndex = 0;
	for(int i = 0; i < self.controlButtonViews.count; i++){
		UIView *view = [self.controlButtonViews objectAtIndex:i];
		if(view == viewChecking){
			viewCheckingIndex = i;
			break;
		}
	}
	
	BOOL shouldHighlight = [self.delegate buttonHighlightedWithIndex:viewCheckingIndex wasJustTapped:wasJustTapped forControlBar:self];
	if(self.viewCurrentlyAnimating != viewChecking){
		[UIView animateWithDuration:0.3 animations:^{
			self.viewCurrentlyAnimating = viewChecking;
			viewChecking.backgroundColor = shouldHighlight ? [UIColor whiteColor] : [LMColour lightGrayBackgroundColour];
		} completion:^(BOOL finished) {
			if(finished){
				self.viewCurrentlyAnimating = nil;
			}
		}];
	}
	
	if(viewChecking.subviews.count > 0){
		UIImageView *iconView = [viewChecking.subviews objectAtIndex:0];
		iconView.image = [self.delegate imageWithIndex:viewCheckingIndex forControlBarView:self];
	}
}

- (void)reloadHighlightedButtons {
	for(int i = 0; i < self.controlButtonViews.count; i++){
		UIView *controlButtonView = [self.controlButtonViews objectAtIndex:i];
		[self buttonHighlightStatusUpdate:controlButtonView wasJustTapped:NO];
	}
}

- (void)tappedButtonBackgroundView:(UITapGestureRecognizer*)gestureRecognizer {
	[self buttonHighlightStatusUpdate:gestureRecognizer.view wasJustTapped:YES];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setup {
	self.userInteractionEnabled = YES;
	
//	self.backgroundColor = [UIColor blueColor];
	
	self.threeDotIconImageView = [UIImageView newAutoLayoutView];
	self.threeDotIconImageView.image = [LMAppIcon imageForIcon:LMIconTripleHorizontalDots];
	self.threeDotIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.threeDotIconImageView.userInteractionEnabled = YES;
	[self addSubview:self.threeDotIconImageView];
	
	[self.threeDotIconImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.threeDotIconImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.threeDotIconImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.threeDotIconImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	UITapGestureRecognizer *tapOnThreeDotGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(animatedInvert)];
	[self addGestureRecognizer:tapOnThreeDotGesture];
	
//	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(invert) userInfo:nil repeats:YES];
//	
	self.backgroundView = [UIView newAutoLayoutView];
	self.backgroundView.backgroundColor = [LMColour lightGrayBackgroundColour];
	self.backgroundView.layer.masksToBounds = YES;
	self.backgroundView.layer.cornerRadius = 10.0;
	self.backgroundView.userInteractionEnabled = YES;
	[self addSubview:self.backgroundView];
	
//	self.backgroundView.hidden = YES;
	
	[self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	self.controlBarHeightConstraint = [self.backgroundView autoSetDimension:ALDimensionHeight toSize:0];
	
	self.controlButtonViews = [NSMutableArray new];
	
	self.buttonBackgroundView = [UIView newAutoLayoutView];
	self.buttonBackgroundView.userInteractionEnabled = YES;
	[self.backgroundView addSubview:self.buttonBackgroundView];
	
	[self.buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundView withMultiplier:(8.0/10.0)];
	[self.buttonBackgroundView autoCenterInSuperview];
	
	uint8_t amountOfItemsForControlBar = [self.delegate amountOfButtonsForControlBarView:self];
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
	innerShadowView.shadowRadius = 3.0;
	innerShadowView.shadowMask = YIInnerShadowMaskAll;
	innerShadowView.cornerRadius = 8.0;
	[self.backgroundView addSubview:innerShadowView];
//	innerShadowView.hidden = YES;
	[innerShadowView autoPinEdgesToSuperviewEdges];
	
	self.triangleView = [LMTriangleView newAutoLayoutView];
	self.triangleView.userInteractionEnabled = YES;
	[self.backgroundView addSubview:self.triangleView];
	
	UITapGestureRecognizer *tapOnTriangleGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(animatedInvert)];
	[self.triangleView addGestureRecognizer:tapOnTriangleGesture];
	
	[self.triangleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.triangleConstraint = [self.triangleView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-50.0];
	[self.triangleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.backgroundView withMultiplier:(1.0/10.0)];
	[self.triangleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundView withMultiplier:(1.0/6.0)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
