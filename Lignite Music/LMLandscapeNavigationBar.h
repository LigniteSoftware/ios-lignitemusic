//
//  LMLandscapeNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 4/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"

@class LMLandscapeNavigationBar;

@protocol LMLandscapeNavigationBarDelegate <NSObject>

/**
 A button was tapped on the landscape navigation bar.

 @param backButtonPressed Whether or not the back button was pressed.
 */
- (void)buttonTappedOnLandscapeNavigationBar:(BOOL)backButtonPressed;

@end

@interface LMLandscapeNavigationBar : LMView

typedef NS_ENUM(NSInteger, LMLandscapeNavigationBarMode) {
	LMLandscapeNavigationBarModeOnlyLogo = 0,
	LMLandscapeNavigationBarModeWithBackButton
};

/**
 The current mode.
 */
@property LMLandscapeNavigationBarMode mode;

/**
 The delegate for the button press events.
 */
@property id<LMLandscapeNavigationBarDelegate> delegate;

@end
