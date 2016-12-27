//
//  LMNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMBrowsingBar.h"
#import "LMSource.h"
#import "LMView.h"

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
 Set the tab that's selected.

 @param tab The tab that should be selected.
 */
- (void)setSelectedTab:(LMNavigationTab)tab;

@end
