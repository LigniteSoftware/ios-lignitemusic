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
#import "LMAppIcon.h"

@interface LMButtonBar()

/**
 The views for the background of all of the buttons.
 */
@property NSMutableArray<UIView*> *buttonsArray;

/**
 The array of button indexes which are highlighted.
 */
@property NSMutableArray<NSNumber*> *currentlyHighlightedButtonsArray;

@end

@implementation LMButtonBar

- (void)invertIconForButtonBackgroundView:(UIView*)buttonBackgroundView {
	UIImageView *iconView = nil;
	for(id subview in buttonBackgroundView.subviews){
		if([subview class] == [UIImageView class]){
			iconView = subview;
			break;
		}
	}
	if(iconView){
		iconView.image = [LMAppIcon invertImage:iconView.image];
	}
}

- (void)setBackgroundColourForButtonBackgroundView:(UIView*)buttonBackgroundView toColour:(UIColor*)colour animated:(BOOL)animated {
	[UIView animateWithDuration:animated ? 0.10 : 0.0 animations:^{
		buttonBackgroundView.backgroundColor = colour;
	}];
}

- (void)setBackgroundView:(UIView*)backgroundView inverted:(BOOL)inverted {
	[self invertIconForButtonBackgroundView:backgroundView];
	[self setBackgroundColourForButtonBackgroundView:backgroundView toColour:inverted ? [UIColor whiteColor] : [LMColour ligniteRedColour] animated:YES];
}

- (void)setButtonAtIndex:(NSInteger)index highlighted:(BOOL)highlight {
	BOOL alreadyHighlighted = [self.currentlyHighlightedButtonsArray containsObject:@(index)];
	if(alreadyHighlighted && !highlight){
		[self.currentlyHighlightedButtonsArray removeObject:@(index)];
	}
	else if(!alreadyHighlighted && highlight){
		[self.currentlyHighlightedButtonsArray addObject:@(index)];
	}
	else if((alreadyHighlighted && highlight) || (!alreadyHighlighted && !highlight)){
		return;
	}
	[self setBackgroundView:[self.buttonsArray objectAtIndex:index] inverted:highlight];
}

- (void)didTapBackgroundView:(UITapGestureRecognizer*)tapGesutre {
	if(self.delegate) {
		UIView *tappedView = tapGesutre.view;
		NSInteger buttonIndex = [self.buttonsArray indexOfObject:tappedView];
		
		BOOL shouldSetAsHighlighted = [self.delegate tappedButtonBarButtonAtIndex:buttonIndex forButtonBar:self];
		
		NSLog(@"Should set as highlighted: %d (numbers %@)", shouldSetAsHighlighted, self.currentlyHighlightedButtonsArray);
		
		[self setButtonAtIndex:buttonIndex highlighted:shouldSetAsHighlighted];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		self.buttonsArray = [NSMutableArray new];
		self.currentlyHighlightedButtonsArray = [NSMutableArray new];
		
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
			if([self.buttonIconsToInvertArray containsObject:@(i)]){
				sendButtonIcon.image = [LMAppIcon invertImage:sendButtonIcon.image];
			}
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
