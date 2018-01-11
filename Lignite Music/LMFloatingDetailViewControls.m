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
