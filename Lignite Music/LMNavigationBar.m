//
//  LMNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSourceSelectorView.h"
#import "LMMiniPlayerView.h"
#import "LMNavigationBar.h"
#import "LMMusicPlayer.h"
#import "LMButtonBar.h"
#import "LMAppIcon.h"
#import "LMButton.h"
#import "LMLabel.h"

@interface LMNavigationBar()<LMButtonBarDelegate, LMButtonDelegate, LMSearchBarDelegate, LMSourceSelectorDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The button bar for controlling the view's currently chosen displayed subview.
 */
@property LMButtonBar *buttonBar;

/**
 The constraint which pins the button bar to the bottom of the view.
 */
@property NSLayoutConstraint *buttonBarBottomConstraint;

/**
 The view which is attached to the top of the button bar.
 */
@property (nonatomic) UIView *viewAttachedToButtonBar;

/**
 The miniplayer.
 */
@property LMMiniPlayerView *miniPlayerView;

/**
 The source selector.
 */
@property LMSourceSelectorView *sourceSelector;

@property UIView *currentSourceBackgroundView;
@property LMLabel *currentSourceLabel;
@property LMLabel *currentSourceDetailLabel;
@property LMButton *currentSourceButton;

@end

@implementation LMNavigationBar

- (void)setButtonBarBottomConstraintConstant:(NSInteger)constant {
	[self layoutIfNeeded];
	
	self.buttonBarBottomConstraint.constant = constant;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:nil];
}

- (NSLayoutConstraint*)topConstrantForView:(UIView*)view {
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeTop && constraint.firstItem == view) {
			return constraint;
		}
	}
	return nil;
}

- (void)setViewAttachedToButtonBar:(UIView *)viewAttachedToButtonBar {
	UIView *previouslyAttachedView = self.viewAttachedToButtonBar;
	
	BOOL isDecreasing = viewAttachedToButtonBar.frame.size.height < previouslyAttachedView.frame.size.height;
	
	_viewAttachedToButtonBar = viewAttachedToButtonBar;
	
	NSLayoutConstraint *previousViewTopConstraint = [self topConstrantForView:previouslyAttachedView];
	NSLayoutConstraint *currentViewTopConstraint = [self topConstrantForView:viewAttachedToButtonBar];
	
	[self layoutIfNeeded];
	
	previousViewTopConstraint.constant = 25;
	currentViewTopConstraint.constant = -viewAttachedToButtonBar.frame.size.height;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.delegate requiredHeightForNavigationBarChangedTo:self.buttonBar.frame.size.height + (viewAttachedToButtonBar.frame.size.height)
										 withAnimationDuration:isDecreasing ? 0.10 : 0.50];
	}];
		
	[self.delegate requiredHeightForNavigationBarChangedTo:0.0 withAnimationDuration:0.10];
}

- (void)minimize {
	[self setButtonBarBottomConstraintConstant:self.buttonBar.frame.size.height + self.viewAttachedToButtonBar.frame.size.height];
}

- (void)maximize {
	[self setButtonBarBottomConstraintConstant:0];
}

- (void)sourceTitleChangedTo:(NSString *)title {
	self.currentSourceLabel.text = title;
}

- (void)sourceSubtitleChangedTo:(NSString *)subtitle {
	self.currentSourceDetailLabel.text = subtitle;
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
		case LMNavigationTabView:
			[self setViewAttachedToButtonBar:self.sourceSelector];
			break;
		case LMNavigationTabMiniplayer:
			[self setViewAttachedToButtonBar:self.miniPlayerView];
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
	
	[self.currentSourceButton setImage:icon];
}

- (void)clickedButton:(LMButton *)button {
//	NSLog(@"Spoooooked");
//	self.openedSourceSelectorFromShortcut = YES;
//	[self open];
//	[self selectSource:LMBrowsingAssistantTabView];
//	[self openSourceSelector];
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
		
		
//		self.backgroundColor = [UIColor cyanColor];
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		
		self.currentSourceBackgroundView = [UIView newAutoLayoutView];
		self.currentSourceBackgroundView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.currentSourceBackgroundView];
		
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.currentSourceBackgroundView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/14.0];
		
		self.currentSourceBackgroundView.backgroundColor = [UIColor whiteColor];
		self.currentSourceBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.currentSourceBackgroundView.layer.shadowOpacity = 0.25f;
		self.currentSourceBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
		self.currentSourceBackgroundView.layer.masksToBounds = NO;
		self.currentSourceBackgroundView.layer.shadowRadius = 5;
		
		
		
		self.currentSourceButton = [LMButton newAutoLayoutView];
		self.currentSourceButton.delegate = self;
		[self.currentSourceBackgroundView addSubview:self.currentSourceButton];
		
		[self.currentSourceButton autoCenterInSuperview];
		[self.currentSourceButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:0.8];
		[self.currentSourceButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:0.8];
		
		[self.currentSourceButton setupWithImageMultiplier:0.525];
		
		[self.currentSourceButton setImage:[LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlaylists]]];
		
		
		
		self.currentSourceLabel = [LMLabel newAutoLayoutView];
		self.currentSourceLabel.text = @"Text post please ignore";
		[self.currentSourceBackgroundView addSubview:self.currentSourceLabel];
		
		[self.currentSourceLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
		[self.currentSourceLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.currentSourceButton withOffset:-10];
		[self.currentSourceLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/2.0)];
		[self.currentSourceLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		self.currentSourceDetailLabel = [LMLabel newAutoLayoutView];
		self.currentSourceDetailLabel.text = @"You didn't ignore it";
		self.currentSourceDetailLabel.textAlignment = NSTextAlignmentRight;
		[self.currentSourceBackgroundView addSubview:self.currentSourceDetailLabel];
		
		[self.currentSourceDetailLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
		[self.currentSourceDetailLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.currentSourceButton withOffset:10];
		[self.currentSourceDetailLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/2.0)];
		[self.currentSourceDetailLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		
		UISwipeGestureRecognizer *swipeUpOnCurrentSourceGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(maximize)];
		swipeUpOnCurrentSourceGesture.direction = UISwipeGestureRecognizerDirectionUp;
		[self.currentSourceBackgroundView addGestureRecognizer:swipeUpOnCurrentSourceGesture];
		
		UITapGestureRecognizer *tapOnCurrentSourceGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(maximize)];
		[self.currentSourceBackgroundView addGestureRecognizer:tapOnCurrentSourceGesture];
		
		
		//Setup the order of the views first then later impose constraints 
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		[self addSubview:self.browsingBar];
		
		
		
		self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		[self addSubview:self.miniPlayerView];
		
		
		
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
		
		
		
		[self.miniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar withOffset:25];
		[self.miniPlayerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.miniPlayerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.miniPlayerView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/5.0];
		
		[self.miniPlayerView setup];
		
		self.miniPlayerView.backgroundColor = [UIColor whiteColor];
		self.miniPlayerView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.miniPlayerView.layer.shadowOpacity = 0.25f;
		self.miniPlayerView.layer.shadowOffset = CGSizeMake(0, 0);
		self.miniPlayerView.layer.masksToBounds = NO;
		self.miniPlayerView.layer.shadowRadius = 5;
//		self.miniPlayerView.hidden = YES;
		
		

		[self.browsingBar autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.browsingBar autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/15.0];
//		self.browsingBar.hidden = YES;
		
		
		
		[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.buttonBar];
		[self.sourceSelector autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height-LMNavigationBarTabHeight];
		
		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];
		
		
		
		[self setSelectedTab:LMNavigationTabBrowse];
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
