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

@property UIView *backgroundView;
@property UIView *buttonBackgroundView;

@property NSMutableArray *controlButtonViews;

@end

@implementation LMControlBarView

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
	[UIView animateWithDuration:0.3 animations:^{
		viewChecking.backgroundColor = shouldHighlight ? [UIColor whiteColor] : (self.verticalMode ? [LMColour verticalControlBarGreyColour] : [LMColour controlBarGreyColour]);
	} completion:nil];

	if(viewChecking.subviews.count > 0){
		UIImageView *iconView = [viewChecking.subviews objectAtIndex:0];
		if(shouldHighlight){
			iconView.image = [self.delegate imageWithIndex:viewCheckingIndex forControlBarView:self];
		}
		else{
			iconView.image = [self.delegate imageWithIndex:viewCheckingIndex forControlBarView:self];
		}
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

- (void)simulateTapAtIndex:(uint8_t)index {
	UIView *controlButtonView = [self.controlButtonViews objectAtIndex:index];
	[self buttonHighlightStatusUpdate:controlButtonView wasJustTapped:YES];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		self.userInteractionEnabled = YES;
		
		self.backgroundView = [UIView newAutoLayoutView];
		self.backgroundView.backgroundColor = self.verticalMode ? [LMColour verticalControlBarGreyColour] : [LMColour controlBarGreyColour];
		self.backgroundView.userInteractionEnabled = YES;
		[self addSubview:self.backgroundView];
		
	//	self.backgroundView.hidden = YES;
		
		[self.backgroundView autoPinEdgesToSuperviewEdges];
		
		self.controlButtonViews = [NSMutableArray new];
		
		self.buttonBackgroundView = [UIView newAutoLayoutView];
		self.buttonBackgroundView.userInteractionEnabled = YES;
		[self.backgroundView addSubview:self.buttonBackgroundView];
		
		[self.buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundView withMultiplier:(9.0/10.0)];
		[self.buttonBackgroundView autoCentreInSuperview];
		
		uint8_t amountOfItemsForControlBar = [self.delegate amountOfButtonsForControlBarView:self];
		for(int i = 0; i < amountOfItemsForControlBar; i++){
			UIView *lastBackgroundView = nil;
			if(self.controlButtonViews.count > 0){
				lastBackgroundView = [[self.controlButtonViews objectAtIndex:i-1] superview];
			}
//			NSAssert(lastBackgroundView, @"Last background view is nil! What the fuckkkk");
			
			UIView *buttonAreaView = [UIView newAutoLayoutView];
			[self.buttonBackgroundView addSubview:buttonAreaView];
			
			BOOL isFirstBackground = (self.controlButtonViews.count == 0);
			
			if(self.verticalMode){
				[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
				[buttonAreaView autoPinEdge:ALEdgeTop toEdge:isFirstBackground ? ALEdgeTop : ALEdgeBottom ofView:isFirstBackground ? self.buttonBackgroundView : lastBackgroundView];
				[buttonAreaView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.buttonBackgroundView withMultiplier:(1.0/(CGFloat)amountOfItemsForControlBar)];
			}
			else{
				[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeTop];
				[buttonAreaView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
				[buttonAreaView autoPinEdge:ALEdgeLeading toEdge:isFirstBackground ? ALEdgeLeading : ALEdgeTrailing ofView:isFirstBackground ? self.buttonBackgroundView : lastBackgroundView];
				[buttonAreaView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBackgroundView withMultiplier:(1.0/(CGFloat)amountOfItemsForControlBar)];
			}
			
			UIView *buttonBackgroundView = [UIImageView newAutoLayoutView];
			buttonBackgroundView.layer.masksToBounds = YES;
			buttonBackgroundView.layer.cornerRadius = 6.0;
			buttonBackgroundView.userInteractionEnabled = YES;
			[buttonAreaView addSubview:buttonBackgroundView];
			
			[buttonBackgroundView autoCentreInSuperview];
			[buttonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonAreaView withMultiplier:0.7];
			[buttonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonAreaView withMultiplier:0.7];
			
			UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedButtonBackgroundView:)];
			[buttonBackgroundView addGestureRecognizer:gestureRecognizer];
			
			UIImageView *buttonImageView = [UIImageView newAutoLayoutView];
			buttonImageView.contentMode = UIViewContentModeScaleAspectFit;
			buttonImageView.image = [self.delegate imageWithIndex:i forControlBarView:self];
			[buttonBackgroundView addSubview:buttonImageView];
			
			[buttonImageView autoCentreInSuperview];
			[buttonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:buttonBackgroundView withMultiplier:0.60];
			[buttonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:buttonBackgroundView withMultiplier:0.60];
			
			[self.controlButtonViews addObject:buttonBackgroundView];
			
			[self reloadHighlightedButtons];
		}
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
