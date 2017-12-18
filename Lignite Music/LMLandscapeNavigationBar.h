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
	LMLandscapeNavigationBarButtonCreate,
	LMLandscapeNavigationBarButtonEdit
};

@protocol LMLandscapeNavigationBarDelegate <NSObject>

/**
 A button was tapped on the landscape navigation bar.

 @param backButtonPressed Whether or not the back button was pressed.
 */
- (void)buttonTappedOnLandscapeNavigationBar:(LMLandscapeNavigationBarButton)buttonPressed;

@end

@interface LMLandscapeNavigationBar : LMView

/**
 The navigation bar mode, which affects the layout of the navigation bar.

 - LMLandscapeNavigationBarModeOnlyLogo: Only the logo in the center of the nav bar.
 - LMLandscapeNavigationBarModeWithBackButton: Places a back button on the top of the bar, with the now playing Lignite button going to the bottom.
 - LMLandscapeNavigationBarModePlaylistView: A + button for create at the top, an edit button below that, and the Lignite icon at the bottom.
 */
typedef NS_ENUM(NSInteger, LMLandscapeNavigationBarMode) {
	LMLandscapeNavigationBarModeOnlyLogo = 0,
	LMLandscapeNavigationBarModeWithBackButton,
	LMLandscapeNavigationBarModePlaylistView
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
 Sets editing button and shit.

 @param editing Editing or not.
 */
- (void)setEditing:(BOOL)editing;

@end
