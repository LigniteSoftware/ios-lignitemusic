//
//  LMButtonBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLayoutManager.h"
#import "LMButtonBar.h"
#import "LMColour.h"
#import "LMAppIcon.h"

@interface LMButtonBar()<LMLayoutChangeDelegate>

/**
 The views for the background of all of the buttons.
 */
@property NSMutableArray<LMView*> *buttonsArray;

/**
 The array of button indexes which are highlighted.
 */
@property NSMutableArray<NSNumber*> *currentlyHighlightedButtonsArray;

@end

@implementation LMButtonBar

//- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		for(UIView *subview in self.subviews){
//			[subview removeFromSuperview];
//		}
//		
//		self.didLayoutConstraints = NO;
//		[self setNeedsLayout];
//		[self layoutIfNeeded];
//	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		
//	}];
//}

- (void)invertIconForButtonBackgroundView:(LMView*)buttonBackgroundView {
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

- (LMView*)backgroundViewForIndex:(NSInteger)index {
	return [self.buttonsArray objectAtIndex:index];
}

- (void)setBackgroundColourForButtonBackgroundView:(LMView*)buttonBackgroundView toColour:(UIColor*)colour animated:(BOOL)animated {
	[UIView animateWithDuration:animated ? 0.10 : 0.0 animations:^{
		buttonBackgroundView.backgroundColor = colour;
	}];
}

- (void)setBackgroundView:(LMView*)backgroundView inverted:(BOOL)inverted {
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
		LMView *tappedView = (LMView*)tapGesutre.view;
		NSInteger buttonIndex = [self.buttonsArray indexOfObject:tappedView];
		
		[self.delegate tappedButtonBarButtonAtIndex:buttonIndex forButtonBar:self];
	}
}

- (void)layoutSubviews {
	NSLog(@"Dig %p frame %@", self, NSStringFromCGRect(self.frame));
	
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor orangeColor];
		
		self.buttonsArray = [NSMutableArray new];
		self.currentlyHighlightedButtonsArray = [NSMutableArray new];
		
		for(NSUInteger i = 0; i < self.amountOfButtons; i++){
			BOOL isFirst = (i == 0);
			LMView *previousView = isFirst ? self : [self.buttonsArray lastObject];
			
			LMView *newBackgroundView = [LMView newAutoLayoutView];
			
			newBackgroundView = [LMView newAutoLayoutView];
			newBackgroundView.backgroundColor = [LMColour ligniteRedColour];
			[self addSubview:newBackgroundView];
			
			[self beginAddingNewPortraitConstraints];
			[newBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:previousView withOffset:!isFirst];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[newBackgroundView autoMatchDimension:ALDimensionWidth
									  toDimension:ALDimensionWidth
										   ofView:self
								   withMultiplier:(1.0/(CGFloat)self.amountOfButtons)];
			
			[self beginAddingNewLandscapeConstraints];
			[newBackgroundView autoPinEdge:ALEdgeTop toEdge:isFirst ? ALEdgeTop : ALEdgeBottom ofView:previousView withOffset:!isFirst];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[newBackgroundView autoMatchDimension:ALDimensionHeight
									  toDimension:ALDimensionHeight
										   ofView:self
								   withMultiplier:(1.0/(CGFloat)self.amountOfButtons)];
			
			[self endAddingNewConstraints];
			
			
			UITapGestureRecognizer *sendButtonTap =
				[[UITapGestureRecognizer alloc]initWithTarget:self
													   action:@selector(didTapBackgroundView:)];
		
			[newBackgroundView addGestureRecognizer:sendButtonTap];
			
			[self.buttonsArray addObject:newBackgroundView];
			
			
			[self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
			[self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
			
			
			UIImageView *sendButtonIcon = [UIImageView newAutoLayoutView];
			sendButtonIcon.contentMode = UIViewContentModeScaleAspectFit;
			sendButtonIcon.image = [LMAppIcon imageForIcon:(LMIcon)[[self.buttonIconsArray objectAtIndex:i] unsignedIntegerValue]];
			if([self.buttonIconsToInvertArray containsObject:@(i)]){
				sendButtonIcon.image = [LMAppIcon invertImage:sendButtonIcon.image];
			}
			[newBackgroundView addSubview:sendButtonIcon];
			
			[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[sendButtonIcon autoCenterInSuperview];
			[sendButtonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:newBackgroundView withMultiplier:[[self.buttonScaleFactorsArray objectAtIndex:i] floatValue]];
			
			[sendButtonIcon setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
			[sendButtonIcon setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
		}
	}
	
	[super layoutSubviews];
}

@end
