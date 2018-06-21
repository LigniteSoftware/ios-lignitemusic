//
//  LMNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMiniPlayerCoreView.h"
#import "LMBrowsingBar.h"
#import "LMSource.h"
#import "LMExtras.h"
#import "LMView.h"

#define LMNavigationBarTabHeight (WINDOW_FRAME.size.height/8.0)
#define LMNavigationBarTabWidth (WINDOW_FRAME.size.width/8.0)

/**
 The bottom tabs of the navigation bar which control.
 */
typedef NS_ENUM(NSUInteger, LMNavigationTab) {
	LMNavigationTabBrowse = 0, //The browse tab for letter tabs and search.
	LMNavigationTabMiniPlayer, //The mini player.
	LMNavigationTabView //The current view.
};

@protocol LMButtonNavigationBarDelegate <NSObject>

/**
 The height for the navigation bar changed needs to be a specific height. The delegate, which should be its superview, should now animate the browsing view to the requested size.
 
 @param requiredHeight The new height required.
 @param animationDuration The duration of the animation which should be used, in seconds.
 */
- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration;

/**
 The button navigation bar finished initialising.
 */
- (void)buttonNavigationBarFinishedInitialising;

@optional

/**
 The user selected a button on the navigation bar.

 @param navigationTab The tab that was selected.
 */
- (void)buttonNavigationBarSelectedNavigationTab:(LMNavigationTab)navigationTab;

@end

@interface LMButtonNavigationBar : LMView

/**
 The currently selected tab.
 */
@property LMNavigationTab currentlySelectedTab;

/**
 The root view controller.
 */
@property id rootViewController;

/**
 The sources for the source selector (ie. Albums, Titles, etc.)
 */
@property NSArray<LMSource*>* sourcesForSourceSelector;

/**
 The search bar delegate.
 */
@property id<LMSearchBarDelegate> searchBarDelegate;

/**
 The letter tab bar delegate.
 */
@property id<LMLetterTabDelegate> letterTabBarDelegate;

/**
 The browsing bar.
 */
@property LMBrowsingBar *browsingBar;

/**
 The core view of the miniplayer, which controls all 3 in queue.
 */
@property LMMiniPlayerCoreView *miniPlayerCoreView;

/**
 The delegate.
 */
@property id<LMButtonNavigationBarDelegate> delegate;

/**
 The view which is attached to the top of the button bar.
 */
@property UIView *viewAttachedToButtonBar;

/**
 Whether or not the navigation bar is in its minimized format.
 */
@property BOOL isMinimised;
@property BOOL isCompletelyHidden;
@property BOOL currentlyScrolling;
@property BOOL userMaximisedDuringScrollDeceleration;

/**
 Completely hide the navigation button bar from the view. Minimize or maximize will need to be called to bring it back.
 */
- (void)completelyHide;

/**
 Minimise the navigation bar down to its small size.

 @param automatic Whether or not the minimise is being done automatically and not manually.
 */
- (void)minimise:(BOOL)automatic;

/**
 Maximise the navigation bar to its full size.

 @param automatic Whether or not the maximise is being done automatically and not manually.
 */
- (void)maximise:(BOOL)automatic;

/**
 Set the tab that's selected.

 @param tab The tab that should be selected.
 */
- (void)setSelectedTab:(LMNavigationTab)tab;

/**
 Set the icon for the current source.

 @param icon The new icon.
 */
- (void)setCurrentSourceIcon:(LMIcon)icon;

/**
 Reloads the layout of itself.
 */
- (void)reloadLayout;

@end
