//
//  LMNavigationBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMNavigationBar.h"
#import "LMButtonBar.h"
#import "LMAppIcon.h"
#import "LMExtras.h"
#import "LMLabel.h"
#import "LMButton.h"

@interface LMNavigationBar()<LMButtonBarDelegate, LMButtonDelegate>

/**
 The button bar for controlling the view's currently chosen displayed subview.
 */
@property LMButtonBar *buttonBar;

@property UIView *currentSourceBackgroundView;
@property LMLabel *currentSourceLabel;
@property LMLabel *currentSourceDetailLabel;
@property LMButton *currentSourceButton;

@end

@implementation LMNavigationBar

- (void)sourceTitleChangedTo:(NSString *)title {
	self.currentSourceLabel.text = title;
}

- (void)sourceSubtitleChangedTo:(NSString *)subtitle {
	self.currentSourceDetailLabel.text = subtitle;
}

- (void)tappedBrowseTab:(BOOL)highlighted wasPreviouslyHighlighted:(BOOL)wasPreviouslyHighlighted {
	
}

- (BOOL)tappedButtonBarButtonAtIndex:(NSUInteger)index forButtonBar:(LMButtonBar *)buttonBar {
	NSLog(@"Tapped %d", (int)index);

	[self.buttonBar setButtonAtIndex:LMNavigationTabBrowse highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabView highlighted:NO];
	[self.buttonBar setButtonAtIndex:LMNavigationTabMiniplayer highlighted:NO];
	
	LMNavigationTab navigationTab = (LMNavigationTab)index;
	switch(navigationTab){
		case LMNavigationTabBrowse:
			break;
		case LMNavigationTabView:
			break;
		case LMNavigationTabMiniplayer:
			break;
	}
	
	return YES;
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor orangeColor];
		
		NSLog(@"Did layout constraints!");
		
		
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
		
		[self.currentSourceButton setImage:[LMAppIcon imageForIcon:LMIconPlaylists]];
		
		
		
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
		
		
		
		UISwipeGestureRecognizer *swipeUpOnCurrentSourceGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(open)];
		swipeUpOnCurrentSourceGesture.direction = UISwipeGestureRecognizerDirectionUp;
		[self.currentSourceBackgroundView addGestureRecognizer:swipeUpOnCurrentSourceGesture];
		
		UITapGestureRecognizer *tapOnCurrentSourceGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(open)];
		[self.currentSourceBackgroundView addGestureRecognizer:tapOnCurrentSourceGesture];
		
		
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
		[self.buttonBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.buttonBar autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/8.0];
		
		self.buttonBar.hidden = YES;
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
