//
//  LMLandscapeNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 4/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"

@class LMLandscapeNavigationBar;

typedef NS_ENUM(NSInteger, LMLandscapeNavigationBarButton) {
	LMLandscapeNavigationBarButtonLogo = 0,
	LMLandscapeNavigationBarButtonBack,
	LMLandscapeNavigationBarButtonWarning
};

@protocol LMLandscapeNavigationBarDelegate <NSObject>

/**
 A button was tapped on the landscape navigation bar.

 @param backButtonPressed Whether or not the back button was pressed.
 */
- (void)buttonTappedOnLandscapeNavigationBar:(LMLandscapeNavigationBarButton)buttonPressed;

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

/**
 Shows the warning button. If YES, a warning button will be displayed at the top of the bar if mode is LMLandscapeNavigationBarModeOnlyLogo, or in the middle if the mode is LMLandscapeNavigationBarModeWithBackButton.
 */
@property BOOL showWarningButton;

@end
