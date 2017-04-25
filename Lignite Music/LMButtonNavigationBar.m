//
//  LMNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButtonNavigationBar.h"
#import "LMSourceSelectorView.h"
#import "LMCoreViewController.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMMusicPlayer.h"
#import "LMButtonBar.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMButton.h"
#import "LMLabel.h"

@interface LMButtonNavigationBar()<UIGestureRecognizerDelegate,
							 LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMLayoutChangeDelegate, LMLandscapeNavigationBarDelegate>

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

@end

@implementation LMButtonNavigationBar

@synthesize viewAttachedToButtonBar = _viewAttachedToButtonBar;

- (CGFloat)maximizedHeight {
	if(self.layoutManager.isLandscape){
		NSLog(@"Size is %f", self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width);
		return self.buttonBar.frame.size.width + self.viewAttachedToButtonBar.frame.size.width;
	}
	
	return self.buttonBar.frame.size.height + self.viewAttachedToButtonBar.frame.size.height;
}

- (void)setButtonBarBottomConstraintConstant:(NSInteger)constant completion:(void (^ __nullable)(BOOL finished))completion {
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
	
	NSLog(@"Set view attached with class %@", [[viewAttachedToButtonBar class] description]);
	
	BOOL isDecreasing = self.layoutManager.isLandscape ? (viewAttachedToButtonBar.frame.size.width < previouslyAttachedView.frame.size.width)
		: (viewAttachedToButtonBar.frame.size.height < previouslyAttachedView.frame.size.height);
	
	_viewAttachedToButtonBar = viewAttachedToButtonBar;
	
	NSLayoutConstraint *previousViewTopConstraint = [self topConstrantForView:previouslyAttachedView];
	NSLayoutConstraint *currentViewTopConstraint = [self topConstrantForView:viewAttachedToButtonBar];
	
	[self layoutIfNeeded];

//    NSLog(@"Fuck you!!! lol %@", viewAttachedToButtonBar);
	
//    [self.minibarBackgroundView removeConstraints:self.minibarBackgroundView.constraints];
    
	
	previousViewTopConstraint.constant = self.layoutManager.isLandscape ? (previouslyAttachedView.frame.size.height*2) : self.buttonBar.frame.size.height;
	currentViewTopConstraint.constant = self.layoutManager.isLandscape ? 0 : -viewAttachedToButtonBar.frame.size.height;
	
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
    
    self.isMinimized = YES;
    self.isCompletelyHidden = YES;
	
	[self setButtonBarBottomConstraintConstant:WINDOW_FRAME.size.height/2 completion:^(BOOL finished) {
		LMButtonNavigationBar *strongSelf = weakSelf;
		if(!strongSelf){
			return;
		}
		
		NSLog(@"Looter in a riot");
		
		if(finished) {
			[strongSelf.delegate requiredHeightForNavigationBarChangedTo:0
												   withAnimationDuration:0.10];
		}
	}];
	
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.frame.size.height);
	
	self.heightBeforeAdjustingToScrollPosition = -1;
}

- (void)minimize {
	return;
	
    if(self.isMinimized){
        return;
    }
    
    self.isMinimized = YES;
    self.isCompletelyHidden = NO;
    
	NSLog(@"Minimize");
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant:self.buttonBar.frame.size.height
                                             + self.viewAttachedToButtonBar.frame.size.height
									completion:^(BOOL finished) {
										LMButtonNavigationBar *strongSelf = weakSelf;
										if(!strongSelf){
											return;
										}
									}];
	
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.buttonBarBottomConstraint.constant);
	
	self.heightBeforeAdjustingToScrollPosition = -1;
}

- (void)maximize {
	NSLog(@"Maximize");
    
    self.isMinimized = NO;
    self.isCompletelyHidden = NO;
	
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
}

- (void)setSelectedTab:(LMNavigationTab)tab {
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
		case LMNavigationTabView:
			if(self.viewAttachedToButtonBar == self.sourceSelector){
				[self setViewAttachedToButtonBar:nil]; //Hide the source selector
			}
			else{
				[self setViewAttachedToButtonBar:self.sourceSelector];
			}
			self.buttonBarBottomConstraint.constant = 0;
			break;
	}
	
	[self.buttonBar setButtonAtIndex:tab highlighted:YES];
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

- (void)setCurrentSourceIcon:(UIImage*)icon {
	UIView *sourceBackgroundView = [self.buttonBar backgroundViewForIndex:LMNavigationTabView];
	UIImageView *iconView;
	for(int i = 0; i < sourceBackgroundView.subviews.count; i++){
		id subview = [sourceBackgroundView.subviews objectAtIndex:i];
		if([subview class] == [UIImageView class]){
			iconView = subview;
		}
	}
	iconView.image = icon;
}

- (void)clickedButton:(LMButton *)button {
	[self maximize];
	[self setSelectedTab:LMNavigationTabView];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	[self.searchBarDelegate searchTermChangedTo:searchTerm];
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.searchBarDelegate searchDialogOpened:opened withKeyboardHeight:keyboardHeight];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		NSLayoutConstraint *newButtonBarBottomConstraint = self.buttonBarBottomConstraint;
		
		CGFloat previousConstant = self.buttonBarBottomConstraint.constant;
		
		for(NSLayoutConstraint *constraint in self.constraints){
			if(constraint.firstItem == self.buttonBar
				&& (  (constraint.firstAttribute == NSLayoutAttributeBottom && !self.layoutManager.isLandscape)
				   || (constraint.firstAttribute == NSLayoutAttributeTrailing && self.layoutManager.isLandscape)  )){
				   
				NSLog(@"New constraint layout attribute %ld", constraint.firstAttribute);
				newButtonBarBottomConstraint = constraint;
			}
		}
		
		self.buttonBarBottomConstraint = newButtonBarBottomConstraint;
//		self.buttonBarBottomConstraint.constant = -previousConstant;
		
		[self.delegate requiredHeightForNavigationBarChangedTo:[self maximizedHeight]
										 withAnimationDuration:0.25];
	}];
}

- (void)layoutSubviews {
//	return;
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Did layout constraints!");
		
		
//		self.backgroundColor = [UIColor purpleColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.heightBeforeAdjustingToScrollPosition = -1;

		
		//Dont even tell me how bad this shit is
		CGFloat properNum = self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
		
	
		
		//Setup the order of the views first then later impose constraints 
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		[self addSubview:self.browsingBar];
		
		
//		self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		// ^ has already been created
        self.miniPlayerCoreView.rootViewController = self.rootViewController;
		[self addSubview:self.miniPlayerCoreView];
		
		
		
		
		self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
		self.sourceSelector.backgroundColor = [UIColor redColor];
		self.sourceSelector.sources = self.sourcesForSourceSelector;
		[self addSubview:self.sourceSelector];
		
		
		
		self.buttonBar = [LMButtonBar newAutoLayoutView];
		self.buttonBar.amountOfButtons = 3;
		self.buttonBar.buttonIconsArray = @[ @(LMIconBrowse), @(LMIconMiniplayer), @(LMIconSource) ];
		self.buttonBar.buttonScaleFactorsArray = @[ @(1.0/2.5), @(1.0/2.5), @(1.0/2.5) ];
		self.buttonBar.buttonIconsToInvertArray = @[ @(LMNavigationTabBrowse), @(LMNavigationTabView) ];
		self.buttonBar.delegate = self;
		self.buttonBar.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.buttonBar];
		
		
		NSLog(@"Frame %@", NSStringFromCGRect(WINDOW_FRAME));
		
		[self beginAddingNewPortraitConstraints];
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		self.buttonBarBottomConstraint = [self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		 [self.buttonBar beginAddingNewPortraitConstraints];
		[self.buttonBar autoSetDimension:ALDimensionHeight toSize:properNum/8.0];
		
		[self beginAddingNewLandscapeConstraints];
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		NSLayoutConstraint *landscapeButtonBarConstraint = [self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		if(self.layoutManager.isLandscape){
			self.buttonBarBottomConstraint = landscapeButtonBarConstraint;
		}
		 [self.buttonBar beginAddingNewLandscapeConstraints];
		[self.buttonBar autoSetDimension:ALDimensionWidth toSize:properNum/8.0];
		
		[self endAddingNewConstraints];
		[self.buttonBar endAddingNewConstraints];
		
		
		self.buttonBarSourceSelectorWarningLabel = [LMLabel newAutoLayoutView];
		self.buttonBarSourceSelectorWarningLabel.text = NSLocalizedString(@"TapViewAgainToOpenSourceSelector", nil);
		self.buttonBarSourceSelectorWarningLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		self.buttonBarSourceSelectorWarningLabel.textAlignment = NSTextAlignmentCenter;
		self.buttonBarSourceSelectorWarningLabel.textColor = [UIColor blackColor];
		self.buttonBarSourceSelectorWarningLabel.backgroundColor = [UIColor whiteColor];
		self.buttonBarSourceSelectorWarningLabel.topAndBottomPadding = 1.0;
		self.buttonBarSourceSelectorWarningLabel.userInteractionEnabled = YES;
        self.buttonBarSourceSelectorWarningLabel.layer.shadowOpacity = 0.25f;
        self.buttonBarSourceSelectorWarningLabel.layer.shadowOffset = CGSizeMake(0, 0);
        self.buttonBarSourceSelectorWarningLabel.layer.masksToBounds = NO;
        self.buttonBarSourceSelectorWarningLabel.layer.shadowRadius = 5;
		[self addSubview:self.buttonBarSourceSelectorWarningLabel];
		
		[self.buttonBarSourceSelectorWarningLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBarSourceSelectorWarningLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonBarSourceSelectorWarningLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.buttonBarSourceSelectorWarningLabel autoMatchDimension:ALDimensionHeight
													   toDimension:ALDimensionHeight
															ofView:self.buttonBar
													withMultiplier:(1.0/3.0)];
		
		
		
	
		
		
		self.buttonBarBottomWhitespaceView = [LMView newAutoLayoutView];
		self.buttonBarBottomWhitespaceView.backgroundColor = [UIColor whiteColor];
		[self.buttonBar addSubview:self.buttonBarBottomWhitespaceView];
		
		[self.buttonBarBottomWhitespaceView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonBar];
		[self.buttonBarBottomWhitespaceView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBarBottomWhitespaceView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonBarBottomWhitespaceView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/2.0];
	
		
		
		[self beginAddingNewPortraitConstraints];
		[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		 [self.miniPlayerCoreView beginAddingNewPortraitConstraints];
		[self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:properNum/5.0];
		
		[self beginAddingNewLandscapeConstraints];
		[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		 [self.miniPlayerCoreView beginAddingNewLandscapeConstraints];
		[self.miniPlayerCoreView autoSetDimension:ALDimensionWidth toSize:properNum/2.8];
		
		[self.miniPlayerCoreView endAddingNewConstraints];
		[self endAddingNewConstraints];
		
//		[self.miniPlayerView setup];
		
		self.miniPlayerCoreView.backgroundColor = [UIColor blueColor];
		self.miniPlayerCoreView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.miniPlayerCoreView.layer.shadowOpacity = 0.25f;
		self.miniPlayerCoreView.layer.shadowOffset = CGSizeMake(0, 0);
		self.miniPlayerCoreView.layer.masksToBounds = NO;
		self.miniPlayerCoreView.layer.shadowRadius = 5;
//		self.miniPlayerView.hidden = YES;
		
		
		[self beginAddingNewPortraitConstraints];
		[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		 [self.browsingBar beginAddingNewPortraitConstraints];
		[self.browsingBar autoSetDimension:ALDimensionHeight toSize:properNum/15.0];
//		self.browsingBar.hidden = YES;

		[self beginAddingNewLandscapeConstraints];
		[self.browsingBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		 [self.browsingBar beginAddingNewLandscapeConstraints];
		[self.browsingBar autoSetDimension:ALDimensionWidth toSize:properNum/17.5];
		
		[self.browsingBar endAddingNewConstraints];
		
		
		[self beginAddingNewPortraitConstraints];
		[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:20];
		 [self.sourceSelector beginAddingNewPortraitConstraints];
		[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:properNum-LMNavigationBarTabHeight];
		
		[self beginAddingNewLandscapeConstraints];
		[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
		[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		 [self.sourceSelector beginAddingNewLandscapeConstraints];
		[self.sourceSelector autoSetDimension:ALDimensionWidth toSize:properNum-LMNavigationBarTabWidth];
		
		[self.sourceSelector endAddingNewConstraints];
		[self endAddingNewConstraints];
		
		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];
		
		
		[self sendSubviewToBack:self.buttonBarSourceSelectorWarningLabel];
		
		
		[self setSelectedTab:LMNavigationTabView];
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			[self setSelectedTab:LMNavigationTabMiniplayer];
		} repeats:NO];
		
		
		self.sourceSelector.hidden = YES;
//		self.miniPlayerCoreView.hidden = YES;
		
//		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
//			self.originalPoint = self.buttonBar.frame.origin;
//			self.currentPoint = self.buttonBar.frame.origin;
//			[self minimize];
//		} repeats:NO];
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
