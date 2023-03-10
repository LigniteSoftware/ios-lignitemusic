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
							 LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMLayoutChangeDelegate, LMThemeEngineDelegate, LMMusicPlayerDelegate>

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
@property UIView *minimiseButton;

/**
 The bottom constraint for the minimize button.
 */
@property (readonly) NSLayoutConstraint *minimiseButtonBottomConstraint;

/**
 The icon image view for the minimize button.
 */
@property UIImageView *minimiseButtonIconImageView;

/**
 Whether or not the button navigation bar was automatically minimized. If so, automatic maximization is OK, otherwise, do not automatically maximize.
 */
@property BOOL wasAutomaticallyMinimised;

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
 The constraints for the mini player size, which are adjusted based on VoiceOver status.
 */
@property NSLayoutConstraint *miniPlayerHeightConstraint;
@property NSLayoutConstraint *miniPlayerWidthConstraint;

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
@synthesize minimiseButtonBottomConstraint = _minimiseButtonBottomConstraint;
@synthesize currentlySelectedTab = _currentlySelectedTab;
@synthesize isMinimised = _isMinimised;

- (void)setIsMinimised:(BOOL)isMinimized {
	_isMinimised = isMinimized;
	
	self.minimiseButton.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"VoiceOverLabel_MinimizeButton", nil), NSLocalizedString(isMinimized ? @"VoiceOverLabel_Minimized" : @"VoiceOverLabel_NotMinimized", nil)];
}

- (BOOL)isMinimised {
	return _isMinimised;
}

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

- (NSLayoutConstraint*)minimiseButtonBottomConstraint {
	return [self bottomConstraintForView:self.minimiseButton];
}

- (CGFloat)maximisedHeight {
	if(self.layoutManager.isLandscape){
		NSLog(@"Size is %f", self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width);
		return self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width;
	}
	
	return self.buttonBar.frame.size.height + self.viewAttachedToButtonBar.frame.size.height + 20;
}

- (void)setButtonBarBottomConstraintConstant:(NSInteger)constant
								  completion:(void (^ __nullable)(BOOL finished))completion {
	[self layoutIfNeeded];
	
	self.buttonBarBottomConstraint.constant = constant;
	
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
	
	NSLog(@"Setshit %f %f, tab %lu, miniplayer? %d cons %p %p", previousViewTopConstraint.constant, currentViewTopConstraint.constant, (unsigned long)self.currentlySelectedTab, (viewAttachedToButtonBar == self.miniPlayerCoreView), previousViewTopConstraint, currentViewTopConstraint);
	
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
					case LMNavigationTabMiniPlayer:
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
		[self.delegate requiredHeightForNavigationBarChangedTo:[self maximisedHeight]
										 withAnimationDuration:isDecreasing ? 0.10 : 0.50];
	}];
		
//	[self.delegate requiredHeightForNavigationBarChangedTo:0.0 withAnimationDuration:0.10];
}

- (void)completelyHide {
	__weak id weakSelf = self;
	
	[self setSelectedTab:LMNavigationTabBrowse];
    
    self.isMinimised = YES;
    self.isCompletelyHidden = YES;
	self.wasAutomaticallyMinimised = YES;
	
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
	
	self.minimiseButtonBottomConstraint.constant = ([LMLayoutManager isLandscape] || [LMLayoutManager isLandscapeiPad]) ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
	
	NSLog(@"Unmodified %@", NSStringFromCGRect(self.unmodifiedFrame));
	
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)minimise:(BOOL)automatic {
    if(self.isMinimised || self.rotating){
        return;
    }
    
    self.isMinimised = YES;
    self.isCompletelyHidden = NO;
	
	self.wasAutomaticallyMinimised = automatic;
    
	NSLog(@"Minimise");
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant://MAX(WINDOW_FRAME.size.height, WINDOW_FRAME.size.width) * 1.25
											 MAX(self.buttonBar.frame.size.height, self.buttonBar.frame.size.width)
	 + (LMLayoutManager.isLandscape ? self.viewAttachedToButtonBar.frame.size.width : self.viewAttachedToButtonBar.frame.size.height)
									completion:^(BOOL finished) {
										LMButtonNavigationBar *strongSelf = weakSelf;
										if(!strongSelf){
											return;
										}
										
										if(finished) {
											[strongSelf.delegate requiredHeightForNavigationBarChangedTo:self.minimiseButton.frame.size.height + 10 withAnimationDuration:0.10];
										}
									}];
	
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.buttonBarBottomConstraint.constant);
	
	self.heightBeforeAdjustingToScrollPosition = -1;
	
	
	[self layoutIfNeeded];
	
	self.minimiseButtonBottomConstraint.constant = 0;
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	[UIView animateWithDuration:1.0 animations:^{
		[self layoutIfNeeded];
		[coreViewController setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)maximise:(BOOL)automatic {
	if((!self.wasAutomaticallyMinimised && self.isMinimised && automatic) || self.rotating){
		return;
	}
	
	NSLog(@"Maximise");
	
	if(!automatic && self.currentlyScrolling){
		self.userMaximisedDuringScrollDeceleration = YES;
	}
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant:0 completion:^(BOOL finished) {
		LMButtonNavigationBar *strongSelf = weakSelf;
		if(!strongSelf){
			return;
		}
		
		if(finished) {
			[strongSelf.delegate requiredHeightForNavigationBarChangedTo:[strongSelf maximisedHeight]
												   withAnimationDuration:0.10];
		}
	}];
	
	self.currentPoint = self.originalPoint;
	
	self.heightBeforeAdjustingToScrollPosition = -1;
	
	if(self.currentlySelectedTab == LMNavigationTabView && self.viewAttachedToButtonBar != nil && self.isMinimised){
		[self setSelectedTab:self.currentlySelectedTab];
	}
	
	self.isMinimised = NO;
	self.isCompletelyHidden = NO;
	self.wasAutomaticallyMinimised = NO;
	
	
	[self layoutIfNeeded];
	
	self.minimiseButtonBottomConstraint.constant = 0;
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
		[coreViewController setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)setSelectedTab:(LMNavigationTab)tab {
	self.currentlySelectedTab = tab;
	
	[self.buttonBar setButtonAtIndex:LMNavigationTabBrowse highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabView highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabMiniPlayer highlighted:NO];
	
	LMNavigationTab navigationTab = tab;
	switch(navigationTab){
		case LMNavigationTabBrowse:
			[self setViewAttachedToButtonBar:self.browsingBar];
			break;
		case LMNavigationTabMiniPlayer:
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
	
	if([self.delegate respondsToSelector:@selector(buttonNavigationBarSelectedNavigationTab:)]){
		[self.delegate buttonNavigationBarSelectedNavigationTab:tab];
	}
	
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
			[self setSelectedTab:LMNavigationTabMiniPlayer];
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
	[self maximise:NO];
	[self setSelectedTab:LMNavigationTabView];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	[self.searchBarDelegate searchTermChangedTo:searchTerm];
}

- (void)searchDialogueOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.searchBarDelegate searchDialogueOpened:opened withKeyboardHeight:keyboardHeight];
}

- (void)reloadMiniPlayerSize {
	//Don't even tell me how bad this shit is
	CGFloat properDimension = self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
	if([LMLayoutManager isiPad]){
		properDimension = [LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width;
	}
	
	BOOL voiceOverRunning = UIAccessibilityIsVoiceOverRunning();
	
	CGFloat normalWidthFactorial = 3.1;
	CGFloat normalHeightFactorial = 5.0;
	
	CGFloat accessibilityWidthFactorial = 2.4;
	CGFloat accessibilityHeightFactorial = 3.7;
	
	if([LMLayoutManager isiPhoneX]){
		accessibilityWidthFactorial = 2.9;
		normalWidthFactorial = 3.5;
		
		accessibilityHeightFactorial = 3.9;
		normalHeightFactorial = 5.5;
	}
	
	if([LMLayoutManager isLandscape]){
		self.miniPlayerWidthConstraint.constant = properDimension/(voiceOverRunning ? accessibilityWidthFactorial : normalWidthFactorial);
		self.miniPlayerHeightConstraint.constant = self.frame.size.height;
	}
	else{
		self.miniPlayerHeightConstraint.constant = properDimension/(voiceOverRunning ? accessibilityHeightFactorial : normalHeightFactorial);
		self.miniPlayerWidthConstraint.constant = self.frame.size.width;
	}
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
		
		[self setSelectedTab:self.currentlySelectedTab];
	}];
}

- (void)voiceOverStatusChanged:(BOOL)voiceOverEnabled {
	[self reloadMiniPlayerSize];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	
	self.rotating = YES;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(!self.isMinimised){
			[self setSelectedTab:self.currentlySelectedTab];
			
			if(self.currentlySelectedTab != LMNavigationTabView){
				[self topConstrantForView:(self.currentlySelectedTab == LMNavigationTabBrowse) ? self.miniPlayerCoreView : self.browsingBar].constant = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height) * 2;
				[self topConstrantForView:self.sourceSelector].constant = MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height) * 2;
				[self layoutIfNeeded];
			}
		}
		
		self.minimiseButtonIconImageView.image = [LMAppIcon imageForIcon:(willBeLandscape || [LMLayoutManager isiPad]) ? LMIcon3DotsHorizontal : LMIcon3DotsVertical];
		
		if(self.isCompletelyHidden){
			self.isCompletelyHidden = NO;
			
			[self completelyHide];
		}
		else if(self.isMinimised){
			self.isMinimised = NO;
			
			[self minimise:NO];
		}
		
		[self reloadMiniPlayerSize];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
			self.rotating = NO;
			
			if(self.isCompletelyHidden){
					[self completelyHide];
			}
			
			[self reloadMiniPlayerSize];
		} repeats:NO];
	}];
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	BOOL adjustForTheFuckingNotch = (notchPosition == LMNotchPositionRight);
	
	self.minimizeButtonIconWidthConstraint.constant = adjustForTheFuckingNotch ? -30.0f : 0.0f;
	
	self.buttonBar.adjustForTheFuckingNotch = adjustForTheFuckingNotch;
	
	NSLog(@"Fuckem %@", self.minimiseButton.constraints);
	
	for(NSLayoutConstraint *constraint in self.minimiseButton.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeWidth && constraint.firstItem == self.minimiseButton){
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
	self.isMinimised ? [self maximise:NO] : [self minimise:NO];
}

- (void)reloadLayout {
	[self.browsingBar.letterTabBar reloadLayout];
}

- (void)themeChanged:(LMTheme)theme {
	self.minimiseButton.backgroundColor = [LMColour mainColour];
	self.iPhoneXBottomCoverView.backgroundColor = [LMColour mainColour];
}

- (void)layoutSubviews {
//	return;
	
	self.unmodifiedFrame = self.frame;
		
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor clearColor];
				
		NSLog(@"Did layout constraints!");
		
		
		self.isAccessibilityElement = NO;
		
		
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
		[self.musicPlayer addMusicDelegate:self];
		
		self.heightBeforeAdjustingToScrollPosition = -1;

		
		//Don't even tell me how bad this shit is
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
				[self.iPhoneXBottomCoverView autoSetDimension:ALDimensionHeight toSize:0.0f];
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
		
		self.minimiseButton = [UIView newAutoLayoutView];
		self.minimiseButton.backgroundColor = [LMColour mainColour];
		self.minimiseButton.userInteractionEnabled = YES;
		self.minimiseButton.isAccessibilityElement = YES;
		[self setIsMinimised:NO];
		self.minimiseButton.accessibilityHint = NSLocalizedString(@"VoiceOverHint_MinimizeButton", nil);
		[self addSubview:self.minimiseButton];
		
		UITapGestureRecognizer *minimizeTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(minimizeButtonTapped)];
		[self.minimiseButton addGestureRecognizer:minimizeTapGestureRecognizer];
		
		
		self.minimiseButtonIconImageView = [UIImageView newAutoLayoutView];
		self.minimiseButtonIconImageView.image = [LMAppIcon imageForIcon:(self.layoutManager.isLandscape || [LMLayoutManager isiPad]) ? LMIcon3DotsHorizontal : LMIcon3DotsVertical];
		self.minimiseButtonIconImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.minimiseButtonIconImageView.userInteractionEnabled = NO;
		[self.minimiseButton addSubview:self.minimiseButtonIconImageView];
		
		[self.minimiseButtonIconImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.minimiseButtonIconImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		self.minimizeButtonIconWidthConstraint = [self.minimiseButtonIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.minimiseButton withOffset:notched ? -30 : 0];
		[self.minimiseButtonIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minimiseButton withMultiplier:[LMLayoutManager isiPad] ? (2.0/10.0) : (4.0/10.0)];
		
		
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
			[self.buttonBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.minimiseButton];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoPinEdge:ALEdgeBottom
								 toEdge:[LMLayoutManager isiPhoneX] ? ALEdgeTop : ALEdgeBottom
								 ofView:[LMLayoutManager isiPhoneX] ? self.iPhoneXBottomCoverView : self];
			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minimiseButton];
//			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}];
		[LMLayoutManager addNewPortraitConstraints:buttonBarPortraitConstraints];
		
		NSArray *buttonBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.buttonBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.minimiseButton];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.minimiseButton];
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
			[self.buttonBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.minimiseButton];
			[self.buttonBar autoSetDimension:ALDimensionHeight toSize:properDimension/8.0];
		}];
		[LMLayoutManager addNewiPadConstraints:buttonBariPadConstraints];
		

		NSArray *browsingBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.browsingBar autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimiseButton];
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
		
		
		
		NSArray *minimiseButtonPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimiseButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.minimiseButton autoPinEdge:ALEdgeBottom
									  toEdge:[LMLayoutManager isiPhoneX] ? ALEdgeTop : ALEdgeBottom
									  ofView:[LMLayoutManager isiPhoneX] ? self.iPhoneXBottomCoverView : self];
			[self.minimiseButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.browsingBar];
			[self.minimiseButton autoSetDimension:ALDimensionHeight toSize:properDimension/8.0];
		}];
		[LMLayoutManager addNewPortraitConstraints:minimiseButtonPortraitConstraints];
		
		CGFloat minimiseButtonLandscapeWidthFactorial = 8.0f;
		if(notched){
			minimiseButtonLandscapeWidthFactorial = 7.0f;
		}
		
		NSArray *minimizeButtonLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimiseButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.minimiseButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.minimiseButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.browsingBar];
			[self.minimiseButton autoSetDimension:ALDimensionWidth toSize:properDimension/minimiseButtonLandscapeWidthFactorial];
		}];
		[LMLayoutManager addNewLandscapeConstraints:minimizeButtonLandscapeConstraints];
		
		NSArray *minimizeButtoniPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.minimiseButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[self.minimiseButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.buttonBar];
			[self.minimiseButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.minimiseButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.buttonBar withMultiplier:(2.0/4.0)];
		}];
		[LMLayoutManager addNewiPadConstraints:minimizeButtoniPadConstraints];
		
		
		NSArray *miniPlayerCoreViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimiseButton];
//			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
		}];
		[LMLayoutManager addNewPortraitConstraints:miniPlayerCoreViewPortraitConstraints];
		
		NSArray *miniPlayerCoreViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar withOffset:properDimension];
			[self.miniPlayerCoreView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
//			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		}];
		[LMLayoutManager addNewLandscapeConstraints:miniPlayerCoreViewLandscapeConstraints];
		
		NSArray *miniPlayerCoreViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.buttonBar];
		}];
		[LMLayoutManager addNewiPadConstraints:miniPlayerCoreViewiPadConstraints];
		
		//These values are in reloadMiniPlayerSize as well
		//Thank you past Edwin
		//You're welcome
		self.miniPlayerHeightConstraint = [self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:properDimension/([LMLayoutManager isiPhoneX] ? 5.5 : 5.0)];
		self.miniPlayerWidthConstraint = [self.miniPlayerCoreView autoSetDimension:ALDimensionWidth toSize:properDimension/([LMLayoutManager isiPhoneX] ? 3.5 : 2.9)];
		
		
		
		
		CGFloat sourceSelectorProperSize = properDimension-(self.layoutManager.isLandscape ? LMNavigationBarTabWidth : LMNavigationBarTabHeight);
		
		NSArray *sourceSelectorPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.minimiseButton];
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
				[self.statusBarCoverView autoSetDimension:ALDimensionHeight toSize:[LMLayoutManager isiPhoneX] ? 44.0f : 20.0];
			}];
			[LMLayoutManager addNewPortraitConstraints:iPhoneXStatusBarCoverViewPortraitConstraints];
			
			NSArray *iPhoneXStatusBarCoverViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[self.statusBarCoverView autoSetDimension:ALDimensionHeight toSize:0.0f];
			}];
			[LMLayoutManager addNewLandscapeConstraints:iPhoneXStatusBarCoverViewLandscapeConstraints];
		}
		
		if([LMLayoutManager isiPad]){
			[self insertSubview:self.minimiseButton aboveSubview:self.buttonBar];
		}
		
		if([LMLayoutManager isiPhoneX]){
			[self bringSubviewToFront:self.iPhoneXBottomCoverView];
			
			[NSTimer scheduledTimerWithTimeInterval:0.10 block:^{
				[self maximise:NO];
			} repeats:NO];
		}
		
		
		[self reloadMiniPlayerSize];
		
		[self.delegate buttonNavigationBarFinishedInitialising];
		
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
