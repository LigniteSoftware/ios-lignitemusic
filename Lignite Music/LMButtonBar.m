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
#import "LMThemeEngine.h"
#import "UIColor+isLight.h"
#import "UIImage+AverageColour.h"

@interface LMButtonBar()<LMLayoutChangeDelegate, LMThemeEngineDelegate>

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

@synthesize adjustForTheFuckingNotch = _adjustForTheFuckingNotch;

- (void)setAdjustForTheFuckingNotch:(BOOL)adjustForTheFuckingNotch {
	_adjustForTheFuckingNotch = adjustForTheFuckingNotch;
	
	if(!self.buttonsArray){ //Not initialized
		return;
	}
	
	for(LMView *view in self.buttonsArray){ //For every actual button view (that can be tapped)
		for(UIView *subview in view.subviews){ //Search its subviews (there should only be one)
			if([subview class] == [UIImageView class]){ //Make sure it's an image view
				for(NSLayoutConstraint *constraint in view.constraints){ //Check the button view's constraints
					if(constraint.firstItem == subview && constraint.firstAttribute == NSLayoutAttributeWidth){ //Check for the width constraint of the image view
						
						constraint.constant = adjustForTheFuckingNotch ? -30.0f : 0;
					}
				}
			}
		}
	}
}

- (BOOL)adjustForTheFuckingNotch {
	return _adjustForTheFuckingNotch;
}

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

- (void)setIconInverted:(BOOL)inverted forButtonBackgroundView:(LMView*)buttonBackgroundView {
	UIImageView *iconView = nil;
	for(id subview in buttonBackgroundView.subviews){
		if([subview class] == [UIImageView class]){
			iconView = subview;
			break;
		}
	}
	if(iconView){
		UIImage *image = [LMAppIcon invertImage:iconView.image];
		
		iconView.image = image;
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
	[self setIconInverted:inverted forButtonBackgroundView:backgroundView];
	[self setBackgroundColourForButtonBackgroundView:backgroundView toColour:inverted ? [LMColour whiteColour] : [LMColour mainColour] animated:YES];
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

- (void)themeChanged:(LMTheme)theme {
	for(LMView *backgroundView in self.buttonsArray){
		if(![backgroundView.backgroundColor isEqual:[LMColour whiteColour]]){
			backgroundView.backgroundColor = [LMThemeEngine mainColourForTheme:theme];
		}
	}
}

- (void)layoutSubviews {
	NSLog(@"Dig %p frame %@", self, NSStringFromCGRect(self.frame));
	
//	BOOL isLandscape = [LMLayoutManager sharedLayoutManager].isLandscape;
	
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [LMColour whiteColour];
		
		self.buttonsArray = [NSMutableArray new];
		self.currentlyHighlightedButtonsArray = [NSMutableArray new];
		
		for(NSUInteger i = 0; i < self.amountOfButtons; i++){
			BOOL isFirst = (i == 0);
			LMView *previousView = isFirst ? self : [self.buttonsArray lastObject];
			
			LMView *newBackgroundView = [LMView newAutoLayoutView];
			newBackgroundView.backgroundColor = [LMColour mainColour];
			newBackgroundView.isAccessibilityElement = YES;
			
			NSString *accessibilityKey = nil;
			switch(i){
				case 0:
					accessibilityKey = @"Browse";
					break;
				case 1:
					accessibilityKey = @"MiniPlayer";
					break;
				case 2:
					accessibilityKey = @"ViewSelector";
					break;
			}
			NSString *accessibilityLabelKey = [NSString stringWithFormat:@"VoiceOverLabel_ButtonBar_%@", accessibilityKey];
			NSString *accessibilityHintKey = [NSString stringWithFormat:@"VoiceOverHint_ButtonBar_%@", accessibilityKey];
			
			newBackgroundView.accessibilityLabel = NSLocalizedString(accessibilityLabelKey, nil);
			newBackgroundView.accessibilityHint = NSLocalizedString(accessibilityHintKey, nil);
			
			[self addSubview:newBackgroundView];
			
			NSArray *newBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[newBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:previousView withOffset:!isFirst];
				[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
				[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
				[newBackgroundView autoMatchDimension:ALDimensionWidth
										  toDimension:ALDimensionWidth
											   ofView:self
									   withMultiplier:(1.0/(CGFloat)self.amountOfButtons)].constant = (i == 1) ? -2 : 0;
			}];
			[LMLayoutManager addNewPortraitConstraints:newBackgroundViewPortraitConstraints];
			
			
			NSArray *newBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[newBackgroundView autoPinEdge:ALEdgeBottom toEdge:isFirst ? ALEdgeBottom : ALEdgeTop ofView:previousView withOffset:-1];
				[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[newBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
				[newBackgroundView autoMatchDimension:ALDimensionHeight
										  toDimension:ALDimensionHeight
											   ofView:self
									   withMultiplier:(1.0/(CGFloat)self.amountOfButtons)].constant = -1;
			}];
			[LMLayoutManager addNewLandscapeConstraints:newBackgroundViewLandscapeConstraints];
			
			
			
			UITapGestureRecognizer *sendButtonTap =
				[[UITapGestureRecognizer alloc]initWithTarget:self
													   action:@selector(didTapBackgroundView:)];
		
			[newBackgroundView addGestureRecognizer:sendButtonTap];
			
			[self.buttonsArray addObject:newBackgroundView];
			
			
			
			
			UIImageView *buttonIcon = [UIImageView newAutoLayoutView];
			buttonIcon.contentMode = UIViewContentModeScaleAspectFit;
			buttonIcon.image = [LMAppIcon imageForIcon:(LMIcon)[[self.buttonIconsArray objectAtIndex:i] unsignedIntegerValue]];
			if([self.buttonIconsToInvertArray containsObject:@(i)]){
				buttonIcon.image = [LMAppIcon invertImage:buttonIcon.image];
			}
//			sendButtonIcon.backgroundColor = [UIColor orangeColor];
			[newBackgroundView addSubview:buttonIcon];
			
			NSArray *buttonIconPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[buttonIcon autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:newBackgroundView];
				[buttonIcon autoCentreInSuperview];
				[buttonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:newBackgroundView withMultiplier:[[self.buttonScaleFactorsArray objectAtIndex:i] floatValue]];
			}];
			[LMLayoutManager addNewPortraitConstraints:buttonIconPortraitConstraints];
			
			NSArray *buttonIconLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[buttonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:newBackgroundView withMultiplier:[[self.buttonScaleFactorsArray objectAtIndex:i] floatValue]];
				[buttonIcon autoPinEdgeToSuperviewEdge:ALEdgeLeading];
				[buttonIcon autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[buttonIcon autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:newBackgroundView withOffset:0];
			}];
			[LMLayoutManager addNewLandscapeConstraints:buttonIconLandscapeConstraints];
		}
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		[self setAdjustForTheFuckingNotch:self.adjustForTheFuckingNotch];
	}
	
	[super layoutSubviews];
}

@end
