//
//  LMNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMBrowsingBar.h"
#import "LMSource.h"
#import "LMExtras.h"
#import "LMView.h"

#define LMNavigationBarTabHeight (WINDOW_FRAME.size.height/8.0)

@protocol LMNavigationBarDelegate <NSObject>

/**
 The height for the navigation bar changed needs to be a specific height. The delegate, which should be its superview, should now animate the browsing view to the requested size.
 
 @param requiredHeight The new height required.
 @param animationDuration The duration of the animation which should be used, in seconds.
 */
- (void)requiredHeightForNavigationBarChangedTo:(CGFloat)requiredHeight withAnimationDuration:(CGFloat)animationDuration;

@end

@interface LMNavigationBar : LMView

/**
 The bottom tabs of the navigation bar which control.
 */
typedef NS_ENUM(NSUInteger, LMNavigationTab) {
	LMNavigationTabBrowse = 0, //The browse tab for letter tabs and search.
	LMNavigationTabMiniplayer, //The mini player.
	LMNavigationTabView //The current view.
};

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
 The delegate.
 */
@property id<LMNavigationBarDelegate> delegate;

/**
 Minimize the navigation bar down to its small size.
 */
- (void)minimize;

/**
 Maximize the navigation bar to its full size.
 */
- (void)maximize;

/**
 Set the tab that's selected.

 @param tab The tab that should be selected.
 */
- (void)setSelectedTab:(LMNavigationTab)tab;

@end
