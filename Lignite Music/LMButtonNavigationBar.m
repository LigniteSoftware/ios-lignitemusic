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
							 LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMLayoutChangeDelegate>

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
//    if(self.isMinimized){
//        return;
//    }
//    
//    self.isMinimized = YES;
//    self.isCompletelyHidden = NO;
//    
//	NSLog(@"Minimize");
//	
//	__weak id weakSelf = self;
//	
//	[self setButtonBarBottomConstraintConstant:self.buttonBar.frame.size.height
//                                             + self.viewAttachedToButtonBar.frame.size.height
//									completion:^(BOOL finished) {
//										LMButtonNavigationBar *strongSelf = weakSelf;
//										if(!strongSelf){
//											return;
//										}
//									}];
//	
//	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.buttonBarBottomConstraint.constant);
//	
//	self.heightBeforeAdjustingToScrollPosition = -1;
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

//- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//	BOOL willBeLandscape = size.width > size.height;
//	
//	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		for(NSLayoutConstraint *constraint in self.constraints){
//			if(constraint.firstItem == self.buttonBar){
//				[self removeConstraint:constraint];
//			}
//		}
//		
//		if(willBeLandscape){
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
//		}
//		else{
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
//		}
//	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		
//		
////		[self.delegate requiredHeightForNavigationBarChangedTo:[self maximizedHeight]
////										 withAnimationDuration:0.25];
//	}];
//}

- (void)layoutSubviews {
//	return;
	
	NSLog(@"New frame %@", NSStringFromCGRect(self.frame));
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Did layout constraints!");
		
		
		self.backgroundColor = [UIColor redColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.heightBeforeAdjustingToScrollPosition = -1;

		
		//Dont even tell me how bad this shit is
		CGFloat properNum = self.layoutManager.isLandscape ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		self.browsingBar.layer.shadowOpacity = 0.25f;
		self.browsingBar.layer.shadowOffset = CGSizeMake(0, 0);
		self.browsingBar.layer.masksToBounds = NO;
		self.browsingBar.layer.shadowRadius = 5;
		[self addSubview:self.browsingBar];

		
		self.miniPlayerCoreView.rootViewController = self.rootViewController;
		[self addSubview:self.miniPlayerCoreView];
		
		UIView *shadowView = [UIView newAutoLayoutView];
		shadowView.layer.shadowOpacity = 0.25f;
		shadowView.layer.shadowOffset = CGSizeMake(0, 0);
		shadowView.layer.masksToBounds = NO;
		shadowView.layer.shadowRadius = 5;
		shadowView.backgroundColor = [UIColor lightGrayColor];
		[self addSubview:shadowView];
		
		[shadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.miniPlayerCoreView];
		[shadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.miniPlayerCoreView];
		[shadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.miniPlayerCoreView];
		[shadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.miniPlayerCoreView];
		
		[self insertSubview:shadowView belowSubview:self.miniPlayerCoreView];

		
		
		self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
		self.sourceSelector.backgroundColor = [UIColor redColor];
		self.sourceSelector.sources = self.sourcesForSourceSelector;
		[self addSubview:self.sourceSelector];

		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];

		
		
//		LMView *testView = [LMView newAutoLayoutView];
////		testView.searchBarDelegate = self;
////		testView.letterTabDelegate = self.letterTabBarDelegate;
//		testView.backgroundColor = [UIColor blueColor];
//		[self addSubview:testView];
		

		
		
		LMView *testView = [LMView newAutoLayoutView];
		testView.backgroundColor = [UIColor purpleColor];
		[self addSubview:testView];
		
		NSArray *testViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[testView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[testView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[testView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.5];
		}];
		[LMLayoutManager addNewLandscapeConstraints:testViewLandscapeConstraints];
		
		NSArray *testViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[testView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[testView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[testView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.5];
		}];
		[LMLayoutManager addNewPortraitConstraints:testViewPortraitConstraints];

		
		self.buttonBar = [LMButtonBar newAutoLayoutView];
		self.buttonBar.amountOfButtons = 3;
		self.buttonBar.buttonIconsArray = @[ @(LMIconBrowse), @(LMIconMiniplayer), @(LMIconSource) ];
		self.buttonBar.buttonScaleFactorsArray = @[ @(1.0/2.5), @(1.0/2.5), @(1.0/2.5) ];
		self.buttonBar.buttonIconsToInvertArray = @[ @(LMNavigationTabBrowse), @(LMNavigationTabView) ];
		self.buttonBar.delegate = self;
		self.buttonBar.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.buttonBar];
		
		
//		self.buttonBar.hidden = YES;
				
//		[self.buttonBar autoPinEdgesToSuperviewEdges];
		
		NSArray *buttonBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.buttonBar autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}];
		[LMLayoutManager addNewPortraitConstraints:buttonBarPortraitConstraints];
		
		NSArray *buttonBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.buttonBar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		}];
		[LMLayoutManager addNewLandscapeConstraints:buttonBarLandscapeConstraints];
		
		

		NSArray *browsingBarPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.browsingBar autoSetDimension:ALDimensionHeight toSize:properNum/15.0];
		}];
		[LMLayoutManager addNewPortraitConstraints:browsingBarPortraitConstraints];
		//		self.browsingBar.hidden = YES;
		
		NSArray *browsingBarLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.browsingBar autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.browsingBar autoSetDimension:ALDimensionWidth toSize:properNum/17.5];
		}];
		[LMLayoutManager addNewLandscapeConstraints:browsingBarLandscapeConstraints];
		
		
		
		NSArray *miniPlayerCoreViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:properNum/5.0];
		}];
		[LMLayoutManager addNewPortraitConstraints:miniPlayerCoreViewPortraitConstraints];
		
		NSArray *miniPlayerCoreViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.miniPlayerCoreView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.miniPlayerCoreView autoSetDimension:ALDimensionWidth toSize:properNum/2.8];

		}];
		[LMLayoutManager addNewLandscapeConstraints:miniPlayerCoreViewLandscapeConstraints];
		
		
		
		NSArray *sourceSelectorPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
			[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
			[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:20];
			[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:properNum-LMNavigationBarTabHeight];
		}];
		[LMLayoutManager addNewPortraitConstraints:sourceSelectorPortraitConstraints];
		
		NSArray *sourceSelectorLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.buttonBar];
			[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[self.sourceSelector autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[self.sourceSelector autoSetDimension:ALDimensionWidth toSize:properNum-LMNavigationBarTabWidth];
		}];
		[LMLayoutManager addNewLandscapeConstraints:sourceSelectorLandscapeConstraints];
		
		
		self.sourceSelector.hidden = YES;
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
