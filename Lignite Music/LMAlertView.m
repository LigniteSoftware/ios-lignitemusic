//
//  LMAlertView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLayoutManager.h"
#import "LMAlertView.h"
#import "LMColour.h"

@interface LMAlertView()<LMLayoutChangeDelegate>

/**
 The array of buttons in order from bottom to top.
 */
@property NSMutableArray<UIButton*>* buttonsArray;

/**
 The constraint which hooks this alert view to the top of its superview.
 */
@property NSLayoutConstraint *topConstraint;

/**
 The completion handler for when the option is selected. Stored from the initial load.
 */
@property void (^completionHandler)(NSUInteger optionSelected);

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The title label, stored for rotation changes since I have to change its alignment >:(
 */
@property UILabel *titleLabel;

@end

@implementation LMAlertView

- (void)buttonTapped:(id)button {
	UIButton *buttonTapped = (UIButton*)button;
	for(int i = 0; i < self.buttonsArray.count; i++){
		UIButton *aButton = [self.buttonsArray objectAtIndex:i];
		if([aButton isEqual:buttonTapped]){
			self.completionHandler(i);
			[self hideAlert];
			break;
		}
	}
}

- (void)recursivelyRemoveSubviewsFromLayoutManagerForView:(UIView*)view {
	[LMLayoutManager removeAllConstraintsRelatedToView:view];
	
	for(UIView *subview in view.subviews){
		[self recursivelyRemoveSubviewsFromLayoutManagerForView:subview];
	}
}

- (void)hideAlert {
	[self.superview layoutIfNeeded];
	
	self.topConstraint.constant = self.frame.size.height;
	
	[UIView animateWithDuration:0.75 delay:0
		 usingSpringWithDamping:0.8 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.superview layoutIfNeeded];
						} completion:^(BOOL finished) {
							if(finished){
								[self removeFromSuperview];
								
								[self recursivelyRemoveSubviewsFromLayoutManagerForView:self];
							}
						}];
}

- (void)showAlert {
	[self.superview layoutIfNeeded];
	
	self.topConstraint.constant = 0;
	
	[UIView animateWithDuration:0.75 delay:0
		 usingSpringWithDamping:0.8 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.superview layoutIfNeeded];
						} completion:nil];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		self.titleLabel.textAlignment = willBeLandscape ? NSTextAlignmentLeft : NSTextAlignmentCenter;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	}];
}

- (void)launchOnView:(UIView*)alertRootView withCompletionHandler:(void(^)(NSUInteger optionSelected))completionHandler {
	NSLog(@"Frame %@", NSStringFromCGRect(alertRootView.frame));
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	BOOL isLandscape = self.layoutManager.isLandscape;
	CGFloat properDimension = (isLandscape ? alertRootView.frame.size.width : alertRootView.frame.size.height);
	
	self.backgroundColor = [UIColor whiteColor];
	
	self.completionHandler = completionHandler;
	
	self.buttonsArray = [NSMutableArray new];
	
	[alertRootView addSubview:self];
	
	[self autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:alertRootView];
	self.topConstraint = [self autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:alertRootView.frame.size.height];
	
	UIView *paddingView = [UIView newAutoLayoutView];
	//	paddingView.backgroundColor = [UIColor orangeColor];
	[self addSubview:paddingView];
	
	[paddingView autoCenterInSuperview];
	[paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(9.0/10.0)];
	[paddingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(9.0/10.0)];
	
	
	UILabel *titleLabel = [UILabel newAutoLayoutView];
	//	titleLabel.backgroundColor = [UIColor yellowColor];
	titleLabel.numberOfLines = 0;
	titleLabel.textAlignment = NSTextAlignmentLeft;
	titleLabel.text = self.title;
	CGFloat titleSize = 0.050 * properDimension;
	if(titleSize > 32){
		titleSize = 32;
	}
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:titleSize];
	[paddingView addSubview:titleLabel];
	
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	self.titleLabel = titleLabel;
	
	
	UILabel *contentsLabel = [UILabel newAutoLayoutView];
	//	contentsLabel.backgroundColor = [UIColor cyanColor];
	contentsLabel.numberOfLines = 0;
	contentsLabel.textAlignment = NSTextAlignmentLeft;
	contentsLabel.text = self.body;
	CGFloat descriptionSize = 0.025 * properDimension;
	if(descriptionSize > 26){
		descriptionSize = 26;
	}
	contentsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:descriptionSize];
	[paddingView addSubview:contentsLabel];
	
	[contentsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:20];
	[contentsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[contentsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	
	for(int i = 0; i < self.alertOptionTitles.count; i++){
		NSString *alertTitle = [self.alertOptionTitles objectAtIndex:i];
		UIColor *alertColour = [self.alertOptionColours objectAtIndex:i];
		
		BOOL isFirstButton = (i == 0);
		
		UIButton *optionButton = [UIButton newAutoLayoutView];
		optionButton.backgroundColor = alertColour;
		optionButton.layer.cornerRadius = 8.0f;
		optionButton.layer.masksToBounds = YES;
		optionButton.clipsToBounds = YES;
		[optionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[optionButton setTitle:alertTitle forState:UIControlStateNormal];
		[optionButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0f]];
		[paddingView addSubview:optionButton];
		
		NSArray *optionButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			if(isFirstButton){
				[optionButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			}
			else{
				[optionButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:[self.buttonsArray lastObject] withOffset:-10.0f];
			}
			[optionButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:alertRootView withMultiplier:(1.0/10.0)];
		}];
		[LMLayoutManager addNewPortraitConstraints:optionButtonPortraitConstraints];
		
		CGFloat landscapePadding = 15.0f;
		
		NSArray *optionButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			CGFloat paddingMultiplier = landscapePadding/properDimension;
			CGFloat sizeMultiplier = (1.0/(float)self.alertOptionColours.count) - paddingMultiplier;
			
			[optionButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/8.0)];
			[optionButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[optionButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:paddingView withMultiplier:sizeMultiplier].constant = -landscapePadding*(i == self.alertOptionTitles.count-1);
			if(isFirstButton){
				[optionButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			}
			else{
				[optionButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:[self.buttonsArray lastObject]].constant = landscapePadding*2;
			}
		}];
		[LMLayoutManager addNewLandscapeConstraints:optionButtonLandscapeConstraints];
		
		[self.buttonsArray addObject:optionButton];
	}

	[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(showAlert) userInfo:nil repeats:NO];
}

@end
