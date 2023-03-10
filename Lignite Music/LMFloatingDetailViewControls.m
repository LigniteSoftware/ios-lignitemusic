//
//  LMFloatingDetailViewControls.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/11/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMFloatingDetailViewControls.h"
#import "LMColour.h"

@interface LMFloatingDetailViewControls()

/**
 The buttons of the controls.
 */
@property NSArray<LMFloatingDetailViewButton*> *floatingButtons;

@end

@implementation LMFloatingDetailViewControls

@synthesize showingBackButton = _showingBackButton;

- (BOOL)showingBackButton {
	return _showingBackButton;
}

- (void)setShowingBackButton:(BOOL)showingBackButton {
	_showingBackButton = showingBackButton;
	
	LMFloatingDetailViewButton *backButton = [self.floatingButtons lastObject];
	[UIView animateWithDuration:0.2 animations:^{
		backButton.alpha = (showingBackButton ? (3.0/4.0) : 0.0);
	}];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	for(UIView *view in self.subviews){
		CGPoint locationInView = [view convertPoint:point fromView:self];
		if (CGRectContainsPoint(view.bounds, locationInView)) {
			return YES;
		}
	}
	return NO;
}

- (NSString*)accessibilityStringForButtonType:(LMFloatingDetailViewControlButtonType)buttonType hint:(BOOL)hint {
	switch(buttonType){
		case LMFloatingDetailViewControlButtonTypeBack:
			return NSLocalizedString(hint ? @"VoiceOverHint_DetailViewButtonBack" : @"VoiceOverLabel_DetailViewButtonBack", nil);
		case LMFloatingDetailViewControlButtonTypeClose:
			return NSLocalizedString(hint ? @"VoiceOverHint_DetailViewButtonClose" : @"VoiceOverLabel_DetailViewButtonClose", nil);
		case LMFloatingDetailViewControlButtonTypeShuffle:
			return NSLocalizedString(hint ? @"VoiceOverHint_DetailViewButtonShuffle" : @"VoiceOverLabel_DetailViewButtonShuffle", nil);
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
//		self.backgroundColor = [LMColour mainColour];
		
		const NSInteger amountOfButtons = 3;
		LMFloatingDetailViewControlButtonType buttonTypes[] = {
			LMFloatingDetailViewControlButtonTypeClose,
			LMFloatingDetailViewControlButtonTypeShuffle,
			LMFloatingDetailViewControlButtonTypeBack
		};
		
		NSMutableArray *buttonsMutableArray = [NSMutableArray new];
		
		for(NSInteger i = 0; i < amountOfButtons; i++){
			BOOL isFirstButton = (i == 0);
			LMFloatingDetailViewButton *previousButton = (isFirstButton ? nil : [buttonsMutableArray lastObject]);
			
			LMFloatingDetailViewButton *button = [LMFloatingDetailViewButton newAutoLayoutView];
			button.type = buttonTypes[i];
			button.delegate = self.delegate;
			button.isAccessibilityElement = YES;
			button.accessibilityLabel = [self accessibilityStringForButtonType:buttonTypes[i] hint:NO];
			button.accessibilityHint = [self accessibilityStringForButtonType:buttonTypes[i] hint:YES];
			[self addSubview:button];
			
			[button autoPinEdge:ALEdgeTop
						 toEdge:(isFirstButton ? ALEdgeTop : ALEdgeBottom)
						 ofView:(isFirstButton ? self : previousButton)
					 withOffset:(isFirstButton ? 15 : 10)];
			[button autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(6.5/10.0)];
			[button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:button];
			
			[buttonsMutableArray addObject:button];
		}
		
		self.floatingButtons = [NSArray arrayWithArray:buttonsMutableArray];
	}
	
	[super layoutSubviews];
}

@end
