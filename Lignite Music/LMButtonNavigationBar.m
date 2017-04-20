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
#import "LMGrabberView.h"
#import "LMButtonBar.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMButton.h"
#import "LMLabel.h"

@interface LMButtonNavigationBar()<UIGestureRecognizerDelegate,
							 LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMSourceSelectorDelegate>

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
 The height of the navigation bar when the adjustment of the scroll position began.
 */
@property NSInteger heightBeforeAdjustingToScrollPosition;

/**
 The minimized bar's background view.
 */
@property LMView *minibarBackgroundView;

/**
 The label that goes right above the minibar for when the source selector is minimized.
 */
@property LMLabel *buttonBarSourceSelectorWarningLabel;

/**
 The grabber for the background of the minibar.
 */
@property (readonly) LMGrabberView *minibarBackgroundGrabber;

/**
 The constraint for the bottom pin of the minibar.
 */
@property NSLayoutConstraint *minibarBottomConstraint;

/**
 The main label for the minibar which resides on the left.
 */
@property LMLabel *minibarLabel;

/**
 The detail label for the minibar which resides on the right.
 */
@property LMLabel *minibarDetailLabel;

/**
 The button which goes in the center of the minibar.
 */
@property LMButton *minibarButton;

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

- (LMGrabberView*)minibarBackgroundGrabber {
	LMGrabberView *grabberView = nil;
	
	for(NSLayoutConstraint *constraint in self.constraints){
		id firstView = constraint.firstItem;
		id secondView = constraint.secondItem;
		
		if([firstView class] == [LMGrabberView class] && [secondView isEqual:self.minibarBackgroundView]) {
			grabberView = firstView;
			break;
		}
	}
	
	return grabberView;
}

- (CGFloat)maximizedHeight {
	return self.buttonBar.frame.size.height
    + self.viewAttachedToButtonBar.frame.size.height
    + LMNavigationBarGrabberHeight;
}

- (CGFloat)minimizedHeight {
	return self.minibarBackgroundView.frame.size.height + LMNavigationBarGrabberHeight;
}

- (void)setButtonBarBottomConstraintConstant:(NSInteger)constant completion:(void (^ __nullable)(BOOL finished))completion {
	[self layoutIfNeeded];
	
	self.buttonBarBottomConstraint.constant = constant;
    
    CGFloat totalHeight = self.viewAttachedToButtonBar.frame.size.height + self.buttonBar.frame.size.height - self.minibarBackgroundView.frame.size.height;
    CGFloat percentageConverted = constant/totalHeight;
    
    if(percentageConverted > 1){
        percentageConverted = 1;
    }
    
//    NSLog(@"Converted %f!", percentageConverted);
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
        
        self.viewAttachedToButtonBar.alpha = 1.0-percentageConverted;
        self.buttonBar.alpha = self.viewAttachedToButtonBar.alpha;
        
        self.minibarBackgroundGrabber.alpha = percentageConverted;
        self.minibarBackgroundView.alpha = self.minibarBackgroundGrabber.alpha;
	} completion:completion];
}

- (NSLayoutConstraint*)topConstrantForView:(UIView*)view {
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeTop && constraint.firstItem == view) {
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
	
	BOOL isDecreasing = viewAttachedToButtonBar.frame.size.height < previouslyAttachedView.frame.size.height;
	
	_viewAttachedToButtonBar = viewAttachedToButtonBar;
	
	NSLayoutConstraint *previousViewTopConstraint = [self topConstrantForView:previouslyAttachedView];
	NSLayoutConstraint *currentViewTopConstraint = [self topConstrantForView:viewAttachedToButtonBar];
	
	[self layoutIfNeeded];
    
    CGFloat minibarHeight = WINDOW_FRAME.size.height/12.0;

//    NSLog(@"Fuck you!!! lol %@", viewAttachedToButtonBar);
	
//    [self.minibarBackgroundView removeConstraints:self.minibarBackgroundView.constraints];
    
    for(NSLayoutConstraint *constraint in self.constraints){
        if(constraint.firstItem == self.minibarBackgroundView){
            [self removeConstraint:constraint];
        }
    }

    [self.minibarBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:viewAttachedToButtonBar ? viewAttachedToButtonBar : self.buttonBarSourceSelectorWarningLabel];
    [self.minibarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.minibarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.minibarBackgroundView autoSetDimension:ALDimensionHeight toSize:minibarHeight];
    
	
	previousViewTopConstraint.constant = self.buttonBar.frame.size.height;
	currentViewTopConstraint.constant = -viewAttachedToButtonBar.frame.size.height;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.delegate requiredHeightForNavigationBarChangedTo:[self maximizedHeight]
										 withAnimationDuration:isDecreasing ? 0.10 : 0.50];
	}];
		
	[self.delegate requiredHeightForNavigationBarChangedTo:0.0 withAnimationDuration:0.10];
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
    if(self.isMinimized){
        return;
    }
    
    self.isMinimized = YES;
    self.isCompletelyHidden = NO;
    
	NSLog(@"Minimize");
	
	__weak id weakSelf = self;
	
	[self setButtonBarBottomConstraintConstant:self.buttonBar.frame.size.height
                                             + self.viewAttachedToButtonBar.frame.size.height
											 //+ LMNavigationBarGrabberHeight
                                             - self.minibarBackgroundView.frame.size.height
									completion:^(BOOL finished) {
										LMButtonNavigationBar *strongSelf = weakSelf;
										if(!strongSelf){
											return;
										}
										
										if(finished) {
											[strongSelf.delegate requiredHeightForNavigationBarChangedTo:[strongSelf minimizedHeight]
																			 withAnimationDuration:0.30];
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	NSLog(@"%@ and %@? %d", [[gestureRecognizer class] description], [[otherGestureRecognizer class] description], ([gestureRecognizer class] != [UIPanGestureRecognizer class]));
	
	return [gestureRecognizer class] != [UIPanGestureRecognizer class];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:recognizer.view];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.buttonBar.frame.origin;
		self.currentPoint = self.buttonBar.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
    NSLog(@"%f %f", totalTranslation, translation.y);
	
	if(totalTranslation < 0){ //Moving upward
		if(recognizer.view == self.miniPlayerCoreView){
			return;
		}
		
		self.buttonBarBottomConstraint.constant = -sqrt(-totalTranslation);
	}
	else{ //Moving downward
		self.buttonBarBottomConstraint.constant = totalTranslation;
	}
	
	if(translation.y < 0 && translation.y != totalTranslation){ //Moving up
        CGFloat totalHeight = self.viewAttachedToButtonBar.frame.size.height + self.buttonBar.frame.size.height - self.minibarBackgroundView.frame.size.height;
        CGFloat percentageConverted = (-translation.y)/totalHeight;
        
        if(percentageConverted > 1){
            percentageConverted = 1;
        }
        
//        NSLog(@"Converted %f", percentageConverted);
		
        self.viewAttachedToButtonBar.alpha = percentageConverted;
        self.buttonBar.alpha = self.viewAttachedToButtonBar.alpha;
        
        self.minibarBackgroundGrabber.alpha = 1.0-percentageConverted;
        self.minibarBackgroundView.alpha = self.minibarBackgroundGrabber.alpha;
    }
    else if(translation.y >= 0 && translation.y == totalTranslation) {
        CGFloat totalHeight = self.viewAttachedToButtonBar.frame.size.height + self.buttonBar.frame.size.height - self.minibarBackgroundView.frame.size.height;
        CGFloat percentageConverted = translation.y/totalHeight;

        if(percentageConverted > 1){
            percentageConverted = 1;
        }
        
//        NSLog(@"Converted %f!", percentageConverted);
        
        self.viewAttachedToButtonBar.alpha = 1.0-percentageConverted;
        self.buttonBar.alpha = self.viewAttachedToButtonBar.alpha;
        
        self.minibarBackgroundGrabber.alpha = percentageConverted;
        self.minibarBackgroundView.alpha = self.minibarBackgroundGrabber.alpha;
    }
	
	[self layoutIfNeeded];
	
	CGFloat currentHeight = [self maximizedHeight] - self.buttonBarBottomConstraint.constant;
	
	if(currentHeight < 0){
		currentHeight = 0;
	}
	
	[self.delegate requiredHeightForNavigationBarChangedTo:currentHeight
									 withAnimationDuration:0.0];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		if((translation.y >= 0)){
			[self minimize];
		}
		else if((translation.y < 0)){
			[self maximize];
		}
	}
}

- (void)sourceTitleChangedTo:(NSString *)title {
	self.minibarLabel.text = title;
}

- (void)sourceSubtitleChangedTo:(NSString *)subtitle {
	self.minibarDetailLabel.text = subtitle;
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
	
	[self.minibarButton setImage:icon];
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

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Did layout constraints!");
		
		
//		self.backgroundColor = [UIColor purpleColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.heightBeforeAdjustingToScrollPosition = -1;

		
		self.minibarBackgroundView = [LMView newAutoLayoutView];
		self.minibarBackgroundView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.minibarBackgroundView];
		
//      [self.minibarBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:LMNavigationBarGrabberHeight];
//      [self.minibarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.minibarBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.minibarBackgroundView autoSetDimension:ALDimensionHeight toSize:minibarHeight];
		
		self.minibarBackgroundView.backgroundColor = [UIColor whiteColor];
		self.minibarBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.minibarBackgroundView.layer.shadowOpacity = 0.25f;
		self.minibarBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
		self.minibarBackgroundView.layer.masksToBounds = NO;
		self.minibarBackgroundView.layer.shadowRadius = 5;
        self.minibarBackgroundView.alpha = 0;
		
		UIPanGestureRecognizer *minibarBackgroundViewGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
		minibarBackgroundViewGrabberMoveRecognizer.delegate = self;
		[self.minibarBackgroundView addGestureRecognizer:minibarBackgroundViewGrabberMoveRecognizer];
		
		
		
		LMGrabberView *minibarBackgroundGrabberView = [LMGrabberView newAutoLayoutView];
		minibarBackgroundGrabberView.backgroundColor = [LMColour semiTransparentLigniteRedColour];
		minibarBackgroundGrabberView.layer.masksToBounds = YES;
		[self addSubview:minibarBackgroundGrabberView];
		
		[minibarBackgroundGrabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.minibarBackgroundView];
		[minibarBackgroundGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
		[minibarBackgroundGrabberView autoSetDimension:ALDimensionHeight toSize:LMNavigationBarGrabberHeight];
		[minibarBackgroundGrabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		
		UIPanGestureRecognizer *minibarBackgroundGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self
																													  action:@selector(handlePan:)];
		minibarBackgroundGrabberMoveRecognizer.delegate = self;
		[minibarBackgroundGrabberView addGestureRecognizer:minibarBackgroundGrabberMoveRecognizer];

		
		
		
		self.minibarButton = [LMButton newAutoLayoutView];
		self.minibarButton.delegate = self;
		[self.minibarBackgroundView addSubview:self.minibarButton];
		
		[self.minibarButton autoCenterInSuperview];
		[self.minibarButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.minibarBackgroundView withMultiplier:0.8];
		[self.minibarButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minibarBackgroundView withMultiplier:0.8];
		
		[self.minibarButton setupWithImageMultiplier:0.525];
		
		[self.minibarButton setImage:[LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlaylists]]];
		
		
		
		self.minibarLabel = [LMLabel newAutoLayoutView];
		self.minibarLabel.text = @"Text post please ignore";
		[self.minibarBackgroundView addSubview:self.minibarLabel];
		
		[self.minibarLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
		[self.minibarLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.minibarButton withOffset:-10];
		[self.minibarLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minibarBackgroundView withMultiplier:(1.0/3.0)];
		[self.minibarLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		self.minibarDetailLabel = [LMLabel newAutoLayoutView];
		self.minibarDetailLabel.text = @"You didn't ignore it";
		self.minibarDetailLabel.textAlignment = NSTextAlignmentRight;
		[self.minibarBackgroundView addSubview:self.minibarDetailLabel];
		
		[self.minibarDetailLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
		[self.minibarDetailLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.minibarButton withOffset:10];
		[self.minibarDetailLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.minibarBackgroundView withMultiplier:(1.0/3.0)];
		[self.minibarDetailLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		UITapGestureRecognizer *tapOnminibarGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(maximize)];
		[self.minibarBackgroundView addGestureRecognizer:tapOnminibarGesture];
		
		
		//Setup the order of the views first then later impose constraints 
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		[self addSubview:self.browsingBar];
        
        UIPanGestureRecognizer *browsingBarMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
        //browsingBarMoveRecognizer.delegate = self;
        [self.browsingBar addGestureRecognizer:browsingBarMoveRecognizer];
		
		
		LMGrabberView *browsingBarGrabberView = [LMGrabberView newAutoLayoutView];
		browsingBarGrabberView.backgroundColor = [LMColour semiTransparentLigniteRedColour];
		browsingBarGrabberView.layer.masksToBounds = YES;
		[self addSubview:browsingBarGrabberView];
		
		[browsingBarGrabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.browsingBar];
		[browsingBarGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
		[browsingBarGrabberView autoSetDimension:ALDimensionHeight toSize:LMNavigationBarGrabberHeight];
		[browsingBarGrabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];

		
		UIPanGestureRecognizer *browsingBarGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
		browsingBarGrabberMoveRecognizer.delegate = self;
		[browsingBarGrabberView addGestureRecognizer:browsingBarGrabberMoveRecognizer];
		
        
        [self insertSubview:self.browsingBar aboveSubview:browsingBarGrabberView];
		
		
//		self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		// ^ has already been created
        self.miniPlayerCoreView.rootViewController = self.rootViewController;
		[self addSubview:self.miniPlayerCoreView];
		
		
		LMGrabberView *miniPlayerGrabberView = [LMGrabberView newAutoLayoutView];
		miniPlayerGrabberView.backgroundColor = [LMColour semiTransparentLigniteRedColour];
		miniPlayerGrabberView.layer.masksToBounds = YES;
		miniPlayerGrabberView.grabberIcon = [LMAppIcon imageForIcon:LMIconUpArrow];
		[self addSubview:miniPlayerGrabberView];
		
		[miniPlayerGrabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.miniPlayerCoreView];
		[miniPlayerGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
		[miniPlayerGrabberView autoSetDimension:ALDimensionHeight toSize:LMNavigationBarGrabberHeight];
		[miniPlayerGrabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		
		
		UIPanGestureRecognizer *miniPlayerGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
		miniPlayerGrabberMoveRecognizer.delegate = self;
		[miniPlayerGrabberView addGestureRecognizer:miniPlayerGrabberMoveRecognizer];
		
		
		
		self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
		self.sourceSelector.backgroundColor = [UIColor redColor];
		self.sourceSelector.sources = self.sourcesForSourceSelector;
		self.sourceSelector.delegate = self;
		[self addSubview:self.sourceSelector];
		
		
		
		self.buttonBar = [LMButtonBar newAutoLayoutView];
		self.buttonBar.amountOfButtons = 3;
		self.buttonBar.buttonIconsArray = @[ @(LMIconBrowse), @(LMIconMiniplayer), @(LMIconSource) ];
		self.buttonBar.buttonScaleFactorsArray = @[ @(1.0/2.0), @(1.0/2.0), @(1.0/2.0) ];
		self.buttonBar.buttonIconsToInvertArray = @[ @(LMNavigationTabBrowse), @(LMNavigationTabView) ];
		self.buttonBar.delegate = self;
		self.buttonBar.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.buttonBar];
		
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		self.buttonBarBottomConstraint = [self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.buttonBar autoSetDimension:ALDimensionHeight toSize:LMNavigationBarTabHeight];
		
		
		UIPanGestureRecognizer *buttonBarGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
		buttonBarGrabberMoveRecognizer.delegate = self;
		[self.buttonBar addGestureRecognizer:buttonBarGrabberMoveRecognizer];
		
		
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
		
		
		UIPanGestureRecognizer *buttonBarSourceWarningGrabberMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
		buttonBarSourceWarningGrabberMoveRecognizer.delegate = self;
		[self.buttonBarSourceSelectorWarningLabel addGestureRecognizer:buttonBarSourceWarningGrabberMoveRecognizer];
		
		
		LMGrabberView *buttonBarGrabberView = [LMGrabberView newAutoLayoutView];
		buttonBarGrabberView.backgroundColor = [LMColour semiTransparentLigniteRedColour];
		buttonBarGrabberView.layer.masksToBounds = YES;
		buttonBarGrabberView.userInteractionEnabled = YES;
		[self addSubview:buttonBarGrabberView];
		
		[buttonBarGrabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.buttonBarSourceSelectorWarningLabel];
		[buttonBarGrabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
		[buttonBarGrabberView autoSetDimension:ALDimensionHeight toSize:LMNavigationBarGrabberHeight];
		[buttonBarGrabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		
		UIPanGestureRecognizer *buttonBarGrabberViewMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self
																											action:@selector(handlePan:)];
		buttonBarGrabberViewMoveRecognizer.delegate = self;
		[buttonBarGrabberView addGestureRecognizer:buttonBarGrabberViewMoveRecognizer];
		
		[self sendSubviewToBack:self.buttonBarSourceSelectorWarningLabel];
		[self sendSubviewToBack:buttonBarGrabberView];
		
		
		
		self.buttonBarBottomWhitespaceView = [LMView newAutoLayoutView];
		self.buttonBarBottomWhitespaceView.backgroundColor = [UIColor whiteColor];
		[self.buttonBar addSubview:self.buttonBarBottomWhitespaceView];
		
		[self.buttonBarBottomWhitespaceView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonBar];
		[self.buttonBarBottomWhitespaceView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.buttonBarBottomWhitespaceView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.buttonBarBottomWhitespaceView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/3.0];
		
		
		[self.miniPlayerCoreView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:LMNavigationBarGrabberHeight*3];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.miniPlayerCoreView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.miniPlayerCoreView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/5.0];
		
//		[self.miniPlayerView setup];
		
		self.miniPlayerCoreView.backgroundColor = [UIColor whiteColor];
		self.miniPlayerCoreView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.miniPlayerCoreView.layer.shadowOpacity = 0.25f;
		self.miniPlayerCoreView.layer.shadowOffset = CGSizeMake(0, 0);
		self.miniPlayerCoreView.layer.masksToBounds = NO;
		self.miniPlayerCoreView.layer.shadowRadius = 5;
//		self.miniPlayerView.hidden = YES;
		
		UIPanGestureRecognizer *miniPlayerViewMoveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self
																											action:@selector(handlePan:)];
		miniPlayerViewMoveRecognizer.delegate = self;
		[self.miniPlayerCoreView addGestureRecognizer:miniPlayerViewMoveRecognizer];
		
		

		[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.browsingBar autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/15.0];
//		self.browsingBar.hidden = YES;
		
		
		
		[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:20];
		[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height-LMNavigationBarTabHeight];
		
		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];
		
		
		
		[self setSelectedTab:LMNavigationTabBrowse];
		
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
