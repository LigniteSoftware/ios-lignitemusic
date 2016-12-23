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

@interface LMNavigationBar()<LMButtonBarDelegate>

/**
 The button bar for controlling the view's currently chosen displayed subview.
 */
@property LMButtonBar *buttonBar;

@end

@implementation LMNavigationBar

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
