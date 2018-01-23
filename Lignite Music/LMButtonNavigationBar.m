//
//  LMNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "UIImage+AverageColour.h"
#import "LMButtonNavigationBar.h"
#import "LMSourceSelectorView.h"
#import "LMCoreViewController.h"
#import "UIColor+isLight.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMThemeEngine.h"
#import "LMMusicPlayer.h"
#import "LMButtonBar.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMButton.h"
#import "LMLabel.h"

@interface LMButtonNavigationBar()<UIGestureRecognizerDelegate,
							 LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The button bar for controlling the view's currently chosen displayed subview.
 */
@property LMButtonBar *buttonBar;

/**
 The whitespace view which goes below the button bar so that if the user drags up too high, they don't see the contents below it.
 */
@property LMView *buttonBarBottomWhitespaceView;

/**
 The constraint which pins the button bar to the bottom of the view.
 */
@property NSLayoutConstraint *buttonBarBottomConstraint;

/**
 The source selector.
 */
@property LMSourceSelectorView *sourceSelector;

/**
 The label that goes right above the minibar for when the source selector is minimized.
 */
@property LMLabel *buttonBarSourceSelectorWarningLabel;

/**
 The height of the navigation bar when the adjustment of the scroll position began.
 */
@property NSInteger heightBeforeAdjustingToScrollPosition;

/**
 The two points required for calculating the drag position.
 */
@property CGPoint originalPoint, currentPoint;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The minimize button.
 */
@property UIView *minimizeButton;

/**
 The bottom constraint for the minimize button.
 */
@property (readonly) NSLayoutConstraint *minimizeButtonBottomConstraint;

/**
 The icon image view for the minimize button.
 */
@property UIImageView *minimizeButtonIconImageView;

/**
 Whether or not the button navigation bar was automatically minimized. If so, automatic maximization is OK, otherwise, do not automatically maximize.
 */
@property BOOL wasAutomaticallyMinimized;

/**
 The frame of the button navigation bar without being modified by being completely hidden.
 */
@property CGRect unmodifiedFrame;

/**
 The bottom cover for the iPhone X's portrait home bar.
 */
@property UIView *iPhoneXBottomCoverView;

/**
 The constraint which pins the iPhone X's home bar bottom cover to the bottom of the root view.
 */

@property NSLayoutConstraint *iPhoneXBottomCoverConstraint;
@property NSLayoutConstraint *minimizeButtonIconWidthConstraint;

/**
 For the fucking status bar.
 */
@property UIView *statusBarCoverView;

/**
 The restored icon for the source.
 */
@property LMIcon stateRestoredSourceLMIcon;

/**
 Whether or not the button bar is currently rotating. If YES, changes in minimization status should be ignored.
 */
@property BOOL rotating;

@end

@implementation LMButtonNavigationBar

@synthesize buttonBarBottomConstraint = _buttonBarBottomConstraint;
@synthesize viewAttachedToButtonBar = _viewAttachedToButtonBar;
@synthesize minimizeButtonBottomConstraint = _minimizeButtonBottomConstraint;
@synthesize currentlySelectedTab = _currentlySelectedTab;

- (LMNavigationTab)currentlySelectedTab {
	return _currentlySelectedTab;
}

- (void)setCurrentlySelectedTab:(LMNavigationTab)currentlySelectedTab {
	_currentlySelectedTab = currentlySelectedTab;
}

- (void)setButtonBarBottomConstraint:(NSLayoutConstraint *)buttonBarBottomConstraint {
	NSLog(@"What");
}

- (NSLayoutConstraint*)bottomConstraintForView:(UIView*)view {
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstItem == view){
			if((constraint.firstAttribute == NSLayoutAttributeBottom && !self.layoutManager.isLandscape) ||
			   (constraint.firstAttribute == NSLayoutAttributeTrailing && self.layoutManager.isLandscape)){
				return constraint;
			}
		}
	}
	return nil;
}

- (NSLayoutConstraint*)buttonBarBottomConstraint {
	return [self bottomConstraintForView:self.buttonBar];
}

- (NSLayoutConstraint*)minimizeButtonBottomConstraint {
	return [self bottomConstraintForView:self.minimizeButton];
}

- (CGFloat)maximizedHeight {
	if(self.layoutManager.isLandscape){
		NSLog(@"Size is %f", self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width);
		return self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width;
	}
	
	return self.buttonBar.frame.size.height + self.viewAttachedToButtonBar.frame.size.height + 20;
}

- (void)setButtonBarBottomConstraintConstant:(NSInteger)constant completion:(void (^ __nullable)(BOOL finished))completion {
	[self layoutIfNeeded];
	
	self.buttonBarBottomConstraint.constant = constant;
	
	BOOL maximizing = (self.buttonBarBottomConstraint.constant < 10.0f);
	if([LMLayoutManager isiPhoneX]){
		self.iPhoneXBottomCoverConstraint.constant = maximizing ? 0.0f : 22.0f;
	}
	
	NSLog(@"Setting to %ld", constant);
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:completion];
}

- (NSLayoutConstraint*)topConstrantForView:(UIView*)view {
	for(NSLayoutConstraint *constraint in self.constraints){
		BOOL isValidConstraint = (self.layoutManager.isLandscape && constraint.firstAttribute == NSLayoutAttributeTrailing) ||
			(constraint.firstAttribute == NSLayoutAttributeTop && !self.layoutManager.isLandscape);
		if(constraint.firstItem == view && isValidConstraint) {
			return constraint;
		}
	}
	return nil;
}

- (UIView*)viewAttachedToButtonBar {
    if(!_viewAttachedToButtonBar){
        return self.buttonBarSourceSelectorWarningLabel;
    }
    return _viewAttachedToButtonBar;
}

- (void)setViewAttachedToButtonBar:(UIView *)viewAttachedToButtonBar {
	UIView *previouslyAttachedView = self.viewAttachedToButtonBar;
		
	BOOL isDecreasing = self.layoutManager.isLandscape ? (viewAttachedToButtonBar.frame.size.width < previouslyAttachedView.frame.size.width)
		: (viewAttachedToButtonBar.frame.size.height < previouslyAttachedView.frame.size.height);
	
	_viewAttachedToButtonBar = viewAttachedToButtonBar;
	
	NSLayoutConstraint *previousViewTopConstraint = [self topConstrantForView:previouslyAttachedView];
	NSLayoutConstraint *currentViewTopConstraint = [self topConstrantForView:viewAttachedToButtonBar];
	
	[self layoutIfNeeded];

//    NSLog(@"Fuck you!!! lol %@", viewAttachedToButtonBar);
	
//    [self.minibarBackgroundView removeConstraints:self.minibarBackgroundView.constraints];
    
	
	previousViewTopConstraint.constant = self.layoutManager.isLandscape ? (previouslyAttachedView.frame.size.height*2) : self.buttonBar.frame.size.height;
//	if(currentViewTopConstraint != previousViewTopConstraint){
		currentViewTopConstraint.constant = self.layoutManager.isLandscape ? 0 : -viewAttachedToButtonBar.frame.size.height;
//	}
	
	NSLog(@"Setshit %f %f, tab %d, miniplayer? %d cons %p %p", previousViewTopConstraint.constant, currentViewTopConstraint.constant, self.currentlySelectedTab, (viewAttachedToButtonBar == self.miniPlayerCoreView), previousViewTopConstraint, currentViewTopConstraint);
	
	if(previousViewTopConstraint.constant == 0 && currentViewTopConstraint.constant == 0){
		static int attemptsToFixNonAppearingView = 0;
		if(attemptsToFixNonAppearingView > 3){
			attemptsToFixNonAppearingView = 0;
		}
		else{
			[NSTimer scheduledTimerWithTimeInterval:0.40 block:^{
				UIView *fixedView = nil;
				switch(self.currentlySelectedTab){
					case LMNavigationTabView:
						fixedView = self.sourceSelector;
						break;
					case LMNavigationTabBrowse:
						fixedView = self.browsingBar;
						break;
					case LMNavigationTabMiniplayer:
						fixedView = self.miniPlayerCoreView;
						break;
				}
				[self setViewAttachedToButtonBar:fixedView];
			} repeats:NO];

			attemptsToFixNonAppearingView++;
		}
	}
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.delegate requiredHeightForNavigationBarChangedTo:[self maximizedHeight]
										 withAnimationDuration:isDecreasing ? 0.10 : 0.50];
	}];
		
//	[self.delegate requiredHeightForNavigationBarChangedTo:0.0 withAnimationDuration:0.10];
}

- (void)completelyHide {
	__weak id weakSelf = self;
	
	[self setSelectedTab:LMNavigationTabBrowse];
    
    self.isMinimized = YES;
    self.isCompletelyHidden = YES;
	self.wasAutomaticallyMinimized = YES;
	
	CGFloat dimensionToUse = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height);
	
	if([LMLayoutManager isiPhoneX]){
		dimensionToUse += 50;
	}
	
	[self setButtonBarBottomConstraintConstant:dimensionToUse completion:^(BOOL finished) {
		LMButtonNavigationBar *strongSelf = weakSelf;
		if(!strongSelf){
			return;
		}
				
		if(finished) {
			[strongSelf.delegate requiredHeightForNavigationBarChangedTo:0
												   withAnimationDuration:0.10];
		}
	}];
	
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + dimensionToUse);
	
	self.heightBeforeAdjustingToScrollPosition = -1;
	
	
	[self layoutIfNeeded];
	
	self.minimizeButtonBottomConstraint.constant = ([LMLayoutManager isLandscape] || [LMLayoutManager isLandscapeiPad]) ? self.unmodifiedFrame.size.width : self.unmodifiedFrame.size.height;
	
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)minimize:(BOOL)automatic {
    if(self.isMinimized || self.rotating){
        return;
    }
    
    self.isMinimized = YES;
    self.isCompletelyHidden = NO;
	
	self.wasAutomaticallyMinimized = automatic;
    
	NSLog(@"Minimize");
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant://MAX(WINDOW_FRAME.size.height, WINDOW_FRAME.size.width) * 1.25
											 MAX(self.buttonBar.frame.size.height, self.buttonBar.frame.size.width)
                                             + self.viewAttachedToButtonBar.frame.size.height
											 + (LMLayoutManager.isiPhoneX ? (self.buttonBar.frame.size.width + 20) : 0)
									completion:^(BOOL finished) {
										LMButtonNavigationBar *strongSelf = weakSelf;
										if(!strongSelf){
											return;
										}
										
										if(finished) {
											[strongSelf.delegate requiredHeightForNavigationBarChangedTo:self.minimizeButton.frame.size.height + 10
																				   withAnimationDuration:0.10];
										}
									}];
	
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.buttonBarBottomConstraint.constant);
	
	self.heightBeforeAdjustingToScrollPosition = -1;
	
	
	[self layoutIfNeeded];
	
	self.minimizeButtonBottomConstraint.constant = 0;
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	[UIView animateWithDuration:1.0 animations:^{
		[self layoutIfNeeded];
		[coreViewController setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)maximize:(BOOL)automatic {
	if((!self.wasAutomaticallyMinimized && self.isMinimized && automatic) || self.rotating){
		return;
	}
	
	NSLog(@"Maximize");
	
	if(!automatic && self.currentlyScrolling){
		self.userMaximizedDuringScrollDeceleration = YES;
	}
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant:0 completion:^(BOOL finished) {
		LMButtonNavigationBar *strongSelf = weakSelf;
		if(!strongSelf){
			return;
		}
		
		if(finished) {
			[strongSelf.delegate requiredHeightForNavigationBarChangedTo:[strongSelf maximizedHeight]
												   withAnimationDuration:0.10];
		}
	}];
	
	self.currentPoint = self.originalPoint;
	
	self.heightBeforeAdjustingToScrollPosition = -1;
	
	if(self.currentlySelectedTab == LMNavigationTabView && self.viewAttachedToButtonBar != nil && self.isMinimized){
		[self setSelectedTab:self.currentlySelectedTab];
	}
	
	self.isMinimized = NO;
	self.isCompletelyHidden = NO;
	self.wasAutomaticallyMinimized = NO;
	
	
	self.minimizeButtonBottomConstraint.constant = 0;
	
	[self layoutIfNeeded];
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	[UIView animateWithDuration:1.0 animations:^{
		[self layoutIfNeeded];
		[coreViewController setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)setSelectedTab:(LMNavigationTab)tab {
	self.currentlySelectedTab = tab;
	
	[self.buttonBar setButtonAtIndex:LMNavigationTabBrowse highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabView highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabMiniplayer highlighted:NO];
	
	LMNavigationTab navigationTab = tab;
	switch(navigationTab){
		case LMNavigationTabBrowse:
			[self setViewAttachedToButtonBar:self.browsingBar];
			break;
		case LMNavigationTabMiniplayer:
			[self setViewAttachedToButtonBar:self.miniPlayerCoreView];
			break;
		case LMNavigationTabView:{
//			NSLayoutConstraint *sizeConstraint = nil;
//			for(NSLayoutConstraint *constraint in self.sourceSelector.constraints){
//				if(constraint.firstItem == self.sourceSelector){
//					if(constraint.firstAttribute == NSLayoutAttributeWidth || constraint.firstAttribute == NSLayoutAttributeHeight){
//						sizeConstraint = constraint;
//						break;
//					}
//				}
//			}
			
//			sizeConstraint.constant = self.layoutManager.isLandscape ? (self.unmodifiedFrame.size.height-LMNavigationBarTabWidth) : (self.unmodifiedFrame.size.width-LMNavigationBarTabHeight);
			
			// ^ this was causing the source selector to have the incorrect size on rotation due to frame not adapting to rotation changes in time
			
			[self setViewAttachedToButtonBar:self.sourceSelector];
			break;
		}
	}
	
	[self.buttonBar setButtonAtIndex:tab highlighted:YES];
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	[UIView animateWithDuration:0.25 animations:^{
		[coreViewController setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)tappedButtonBarButtonAtIndex:(NSUInteger)index forButtonBar:(LMButtonBar *)buttonBar {
	switch(index){
		case 0:
			[self setSelectedTab:LMNavigationTabBrowse];
			break;
		case 1:
			[self setSelectedTab:LMNavigationTabMiniplayer];
			break;
		case 2:
			[self setSelectedTab:LMNavigationTabView];
			break;
	}
}

- (void)setCurrentSourceIcon:(LMIcon)icon {
	UIImage *rawIconImage = [LMAppIcon imageForIcon:icon];
//	BOOL rawIconImageIsLight = [[rawIconImage averageColour] isLight];
//	UIImage *iconImage = rawIconImageIsLight ? [LMAppIcon invertImage:rawIconImage] : rawIconImage;
	UIImage *iconImage = [LMAppIcon invertImage:rawIconImage];
	
	UIView *sourceBackgroundView = [self.buttonBar backgroundViewForIndex:LMNavigationTabView];
	UIImageView *iconView;
	for(int i = 0; i < sourceBackgroundView.subviews.count; i++){
		id subview = [sourceBackgroundView.subviews objectAtIndex:i];
		if([subview class] == [UIImageView class]){
			iconView = subview;
		}
	}
	
	if(iconView){
		iconView.image = iconImage;
	}
	else{
		self.stateRestoredSourceLMIcon = icon;
	}
	
	if(iconView == nil){
		NSLog(@"Fuck");
	}
}

- (void)clickedButton:(LMButton *)button {
	[self maximize:NO];
	[self setSelectedTab:LMNavigationTabView];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	[self.searchBarDelegate searchTermChangedTo:searchTerm];
}

- (void)searchDialogueOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.searchBarDelegate searchDialogueOpened:opened withKeyboardHeight:keyboardHeight];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	
	self.rotating = YES;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(!self.isMinimized){
			[self setSelectedTab:self.currentlySelectedTab];
			
			if(self.currentlySelectedTab != LMNavigationTabView){
				[self topConstrantForView:(self.currentlySelectedTab == LMNavigationTabBrowse) ? self.miniPlayerCoreView : self.browsingBar].constant = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height) * 2;
				[self topConstrantForView:self.sourceSelector].constant = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height) * 2;
				[self layoutIfNeeded];
			}
		}
		
		self.minimizeButtonIconImageView.image = [LMAppIcon imageForIcon:(willBeLandscape || [LMLayoutManager isiPad]) ? LMIcon3DotsHorizontal : LMIcon3DotsVertical];
		
		if(self.isCompletelyHidden){
			self.isCompletelyHidden = NO;
			
			[self completelyHide];
		}
		else if(self.isMinimized){
			self.isMinimized = NO;
			
			[self minimize:NO];
		}
//		else{
//			[self maximize:NO];
//		}
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
			self.rotating = NO;
			if(self.isCompletelyHidden){
					[self completelyHide];
			}
		} repeats:NO];
	}];
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	BOOL adjustForTheFuckingNotch = (notchPosition == LMNotchPositionRight);
	
	self.minimizeButtonIconWidthConstraint.constant = adjustForTheFuckingNotch ? -30.0f : 0.0f;
	
	self.buttonBar.adjustForTheFuckingNotch = adjustForTheFuckingNotch;
	
	NSLog(@"Fuckem %@", self.minimizeButton.constraints);
	
	for(NSLayoutConstraint *constraint in self.minimizeButton.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeWidth && constraint.firstItem == self.minimizeButton){
			constraint.constant = WINDOW_FRAME.size.width/(adjustForTheFuckingNotch ? 7.0 : 8.0);
		}
	}
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

- (void)minimizeButtonTapped {
	NSLog(@"ay boy");
	self.isMinimized ? [self maximize:NO] : [self minimize:NO];
}

- (void)reloadLayout {
	[self.browsingBar.letterTabBar reloadLayout];
}

- (void)themeChanged:(LMTheme)theme {
	self.minimizeButton.backgroundColor = [LMColour mainColour];
	self.iPhoneXBottomCoverView.backgroundColor = [LMColour mainColour];
}

- (void)layoutSubviews {
//	return;
		
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Did layout constraints!");
		
		self.unmodifiedFrame = self.frame;
		
		
		self.layer.shadowOpacity = 0.25f;
		self.layer.shadowOffset = CGSizeMake(0, 0);
		self.layer.masksToBounds = NO;
		self.layer.shadowRadius = 5;
		self.clipsToBounds = NO;
		
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		[[LMThemeEngine sharedThemeEngine] addDelegate:self];
		
		
		self.backgroundColor = [UIColor clearColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.heightBeforeAdjustingToScrollPosition = -1;

		
		//Dont even tell me how bad this shit is
		CGFloat properDimension = self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
		if([LMLayoutManager isiPad]){
			properDimension = [LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width;
		}
		
		
		
		if([LMLayoutManager isiPhoneX]){
			self.iPhoneXBottomCoverView = [UIView newAutoLayoutView];
			self.iPhoneXBottomCoverView.backgroundColor = [LMColour mainColour];
			[self addSubview:self.iPhoneXBottomCoverView];
			
			
			[self.iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			self.iPhoneXBottomCoverConstraint = [self.iPhoneXBottomCoverView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			
			NSArray *buttonNavigationBarBottomCoverViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.iPhoneXBottomCoverView autoSetDimension:ALDimensionHeight toSize:22.0f];
			}];
			[LMLayoutManager addNewPortraitConstraints:buttonNavigationBarBottomCoverViewPortraitConstraints];
			
			NSArray *buttonNavigationBarBottomCoverViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.iPhoneXBottomCoverView autoSetDimension:ALDimensionHeight toSize:0];
			}];
			[LMLayoutManager addNewLandscapeConstraints:buttonNavigationBarBottomCoverViewLandscapeConstraints];
		}
		
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		[self addSubview:self.browsingBar];

		
		self.miniPlayerCoreView.rootViewController = self.rootViewController;
		[self addSubview:self.miniPlayerCoreView];
		
//		UIView *shadowView = [UIView newAutoLayoutView];
//		shadowView.layer.shadowOpacity = 0.25f;
//		shadowView.layer.shadowOffset = CGSizeMake(0, 0);
//		shadowView.layer.masksToBounds = NO;
//		shadowView.layer.shadowRadius = 5;
//		shadowView.backgroundColor = [UIColor lightGrayColor];
//		[self addSubview:shadowView];
//		
//		[shadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.miniPlayerCoreView];
//		[shadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.miniPlayerCoreView];
//		[shadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.miniPlayerCoreView];
//		[shadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.miniPlayerCoreView];
//		
//		[self insertSubview:shadowView belowSubview:self.miniPlayerCoreView];

		
		
		self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
		self.sourceSelector.backgroundColor = [UIColor redColor];
		self.sourceSelector.sources = self.sourcesForSourceSelector;
		self.sourceSelector.isMainSourceSelector = YES;
		[self addSubview:self.sourceSelector];

		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];

		
		
//		LMView *testView = [LMView newAutoLayoutView];
////		testView.searchBarDelegate = self;
////		testView.letterTabDelegate = self.letterTabBarDelegate;
//		testView.backgroundColor = [UIColor blueColor];
//		[self addSubview:testView];
		

		
		
//		LMView *testView = [LMView newAutoLayoutView];
//		testView.backgroundColor = [UIColor purpleColor];
//		[self addSubview:testView];
//		
//		NSArray *testViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//			[testView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.5];
//		}];
//		[LMLayoutManager addNewLandscapeConstraints:testViewLandscapeConstraints];
//		
//		NSArray *testViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//			[testView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//			[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.5];
//		}];
//		[LMLayoutManager addNewPortraitConstraints:testViewPortraitConstraints];

		
		
		BOOL notched = NO;
		if([LMLayoutManager isiPhoneX]){
			LMNotchPosition notchPosition = [LMLayoutManager notchPosition];
			if(notchPosition == LMNotchPositionRight){
				notched = YES; //get fucking notched son
			}
		}
		
		self.minimizeButton = [UIView newAutoLayoutView];
		self.minimizeButton.backgroundColor = [LMColour mainColour];
		self.minimizeButton.userInteractionEnabled = YES;
		[self addSubview:self.minimizeButton];
		
		UITapGestureRecognizer *minimizeTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(minimizeButtonTapped)];
		[self.minimizeButton addGestureRecognizer:minimizeTapGestureRecognizer];
		
		
		self.minimizeButtonIconImageView = [UIImageView newAutoLayoutView];
		self.minimizeButtonIconImageView.image = [LMAppIcon imageForIcon:(self.layoutManager.isLandscape || [LMLayoutManager isiPad]) ? LMIcon3DotsHorizontal : LMIcon3DotsVertical];
		self.minimizeButtonIconImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.minimizeButtonIconImageView.userInteractionEnabled = NO;
		[self.minimizeButton addSubview:self.minimizeButtonIconImageView];
		
		[self.minimizeButtonIconImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.minimizeButtonIconImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		self.minimizeButtonIconWidthConstraint = [self.minimizeButtonIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.minimizeButton withOffset:notched ? -30 : 0];
		[self.minimizeButtonIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minimizeButton withMultiplier:[LMLayoutManager isiPad] ? (2.0/10.0) : (4.0/10.0)];
		
		
		self.buttonBar = [LMButtonBar newAutoLayoutView];
		self.buttonBar.amountOfButtons = 3;
		NSNumber *sourceIcon = (self.stateRestoredSourceLMIcon == 0) ? @(LMIconSource) : @(self.stateRestoredSourceLMIcon);
		self.buttonBar.buttonIconsArray = @[ @(LMIconBrowse), @(LMIconMiniplayer), sourceIcon ];
		self.buttonBar.buttonScaleFactorsArray = @[ @(1.0/2.5), @(1.0/2.5), @(1.0/2.5) ];
		self.buttonBar.buttonIconsToInvertArray = @[ @(LMNavigationTabBrowse), @(LMNavigationTabView) ];
		self.buttonBar.delegate = self;
		self.buttonBar.backgroundColor = [UIColor whiteColor];
		self.buttonBar.adjustForTheFuckingNotch = notched;
		[self addSubview:self.buttonBar];
		
		
//		self.buttonBar.hidden = YES;
				
//		[self.buttonBar autoPinEdgesToSuperviewEdges];
		
		NSArray *buttonBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.minimizeButton];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoPinEdge:ALEdgeBottom
								 toEdge:[LMLayoutManager isiPhoneX] ? ALEdgeTop : ALEdgeBottom
								 ofView:[LMLayoutManager isiPhoneX] ? self.iPhoneXBottomCoverView : self];
			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minimizeButton];
//			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}];
		[LMLayoutManager addNewPortraitConstraints:buttonBarPortraitConstraints];
		
		NSArray *buttonBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.buttonBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.minimizeButton];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.minimizeButton];
//			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		}];
		[LMLayoutManager addNewLandscapeConstraints:buttonBarLandscapeConstraints];
		
		NSArray *buttonBariPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			CGFloat buttonBarWidth = (2.0/3.0) * ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width);
			if(buttonBarWidth > 500){
				buttonBarWidth = 500;
			}
 			[self.buttonBar autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.buttonBar autoSetDimension:ALDimensionWidth toSize:buttonBarWidth];
//			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(2.0/3.0)];
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.buttonBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.minimizeButton];
			[self.buttonBar autoSetDimension:ALDimensionHeight toSize:properDimension/8.0];
		}];
		[LMLayoutManager addNewiPadConstraints:buttonBariPadConstraints];
		

		NSArray *browsingBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.browsingBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimizeButton];
			[self.browsingBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.browsingBar autoSetDimension:ALDimensionHeight toSize:properDimension/([LMLayoutManager isiPhoneX] ? 16.5 : 15.0)];
		}];
		[LMLayoutManager addNewPortraitConstraints:browsingBarPortraitConstraints];
		//		self.browsingBar.hidden = YES;
		
		NSArray *browsingBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar withOffset:properDimension];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.browsingBar autoSetDimension:ALDimensionWidth toSize:properDimension/([LMLayoutManager isiPhoneX] ? 20.0 : 17.5)];
		}];
		[LMLayoutManager addNewLandscapeConstraints:browsingBarLandscapeConstraints];
		
		NSArray *browsingBariPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.browsingBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.browsingBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.browsingBar autoSetDimension:ALDimensionHeight toSize:properDimension/15.0];
		}];
		[LMLayoutManager addNewiPadConstraints:browsingBariPadConstraints];
		
		
		
		NSArray *minimizeButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimizeButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.minimizeButton autoPinEdge:ALEdgeBottom
									  toEdge:[LMLayoutManager isiPhoneX] ? ALEdgeTop : ALEdgeBottom
									  ofView:[LMLayoutManager isiPhoneX] ? self.iPhoneXBottomCoverView : self];
			[self.minimizeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.browsingBar];
			[self.minimizeButton autoSetDimension:ALDimensionHeight toSize:properDimension/8.0];
		}];
		[LMLayoutManager addNewPortraitConstraints:minimizeButtonPortraitConstraints];
		
		CGFloat minimizeButtonLandscapeWidthFactorial = 8.0f;
		if(notched){
			minimizeButtonLandscapeWidthFactorial = 7.0f;
		}
		
		NSArray *minimizeButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimizeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.minimizeButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.minimizeButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.browsingBar];
			[self.minimizeButton autoSetDimension:ALDimensionWidth toSize:properDimension/minimizeButtonLandscapeWidthFactorial];
		}];
		[LMLayoutManager addNewLandscapeConstraints:minimizeButtonLandscapeConstraints];
		
		NSArray *minimizeButtoniPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimizeButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.minimizeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBar];
			[self.minimizeButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.minimizeButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.buttonBar withMultiplier:(2.0/4.0)];
		}];
		[LMLayoutManager addNewiPadConstraints:minimizeButtoniPadConstraints];
		
		
		NSArray *miniPlayerCoreViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimizeButton];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:properDimension/5.0];
		}];
		[LMLayoutManager addNewPortraitConstraints:miniPlayerCoreViewPortraitConstraints];
		
		NSArray *miniPlayerCoreViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar withOffset:properDimension];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.miniPlayerCoreView autoSetDimension:ALDimensionWidth toSize:properDimension/([LMLayoutManager isiPhoneX] ? 3.5 : 2.8)];

		}];
		[LMLayoutManager addNewLandscapeConstraints:miniPlayerCoreViewLandscapeConstraints];
		
		NSArray *miniPlayerCoreViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:properDimension/5.0];
		}];
		[LMLayoutManager addNewiPadConstraints:miniPlayerCoreViewiPadConstraints];
		
		CGFloat sourceSelectorProperSize = properDimension-(self.layoutManager.isLandscape ? LMNavigationBarTabWidth : LMNavigationBarTabHeight);
		
		NSArray *sourceSelectorPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimizeButton];
			[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:20];
			[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:sourceSelectorProperSize];
		}];
		[LMLayoutManager addNewPortraitConstraints:sourceSelectorPortraitConstraints];
		
		NSArray *sourceSelectorLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar withOffset:properDimension];
			[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.sourceSelector autoSetDimension:ALDimensionWidth toSize:sourceSelectorProperSize];
		}];
		[LMLayoutManager addNewLandscapeConstraints:sourceSelectorLandscapeConstraints];
		
		NSArray *sourceSelectoriPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
			[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:20];
			[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:properDimension-LMNavigationBarTabHeight];
		}];
		[LMLayoutManager addNewiPadConstraints:sourceSelectoriPadConstraints];
		
		if(![LMLayoutManager isiPad]){
			self.statusBarCoverView = [UIView newAutoLayoutView];
			self.statusBarCoverView.backgroundColor = [UIColor whiteColor];
			[self.sourceSelector addSubview:self.statusBarCoverView];
			
			[self.statusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.statusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.statusBarCoverView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			
			NSArray *iPhoneXStatusBarCoverViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.statusBarCoverView autoSetDimension:ALDimensionHeight toSize:[LMLayoutManager isiPhoneX] ? 64.0f : 20.0];
			}];
			[LMLayoutManager addNewPortraitConstraints:iPhoneXStatusBarCoverViewPortraitConstraints];
			
			NSArray *iPhoneXStatusBarCoverViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.statusBarCoverView autoSetDimension:ALDimensionHeight toSize:0.0f];
			}];
			[LMLayoutManager addNewLandscapeConstraints:iPhoneXStatusBarCoverViewLandscapeConstraints];
		}
		
		if([LMLayoutManager isiPad]){
			[self insertSubview:self.minimizeButton aboveSubview:self.buttonBar];
		}
		
		if([LMLayoutManager isiPhoneX]){
			[self bringSubviewToFront:self.iPhoneXBottomCoverView];
			
			[NSTimer scheduledTimerWithTimeInterval:0.10 block:^{
				[self maximize:NO];
			} repeats:NO];
		}
		
//		self.sourceSelector.hidden = YES;
	}
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.miniPlayerCoreView = [LMMiniPlayerCoreView newAutoLayoutView];
        self.miniPlayerCoreView.buttonNavigationBar = self;
	}
	return self;
}

@end
