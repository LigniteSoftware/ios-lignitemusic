//
//  LMButtonBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButtonBar.h"
#import "LMColour.h"

@interface LMButtonBar()

/**
 The views for the background of all of the buttons.
 */
@property NSMutableArray<UIView*> *buttonsArray;

@end

@implementation LMButtonBar

- (void)didTapBackgroundView:(UITapGestureRecognizer*)tapGesutre {
	if(self.delegate) {
		[self.delegate tappedButtonBarButtonAtIndex:[self.buttonsArray indexOfObject:tapGesutre.view] forButtonBar:self];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		self.buttonsArray = [NSMutableArray new];
		
		for(NSUInteger i = 0; i < self.amountOfButtons; i++){
			BOOL isFirst = (i == 0);
			UIView *previousView = isFirst ? self : [self.buttonsArray lastObject];
			
			UIView *newBackgroundView = [UIView newAutoLayoutView];
			
			newBackgroundView = [UIView newAutoLayoutView];
			newBackgroundView.backgroundColor = [LMColour ligniteRedColour];
			[self addSubview:newBackgroundView];
			
			[newBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:previousView withOffset:!isFirst];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[newBackgroundView autoMatchDimension:ALDimensionWidth
									  toDimension:ALDimensionWidth
										   ofView:self
								   withMultiplier:(1.0/(CGFloat)self.amountOfButtons)];
			
			
			UITapGestureRecognizer *sendButtonTap =
				[[UITapGestureRecognizer alloc]initWithTarget:self
													   action:@selector(didTapBackgroundView:)];
		
			[newBackgroundView addGestureRecognizer:sendButtonTap];
			
			[self.buttonsArray addObject:newBackgroundView];
			
			
			UIImageView *sendButtonIcon = [UIImageView newAutoLayoutView];
			sendButtonIcon.contentMode = UIViewContentModeScaleAspectFit;
			sendButtonIcon.image = [LMAppIcon imageForIcon:(LMIcon)[[self.buttonIconsArray objectAtIndex:i] unsignedIntegerValue]];
			[newBackgroundView addSubview:sendButtonIcon];
			
			[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[sendButtonIcon autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[sendButtonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:[[self.buttonScaleFactorsArray objectAtIndex:i] floatValue]];
		}
	}
	
	[super layoutSubviews];
}

@end
