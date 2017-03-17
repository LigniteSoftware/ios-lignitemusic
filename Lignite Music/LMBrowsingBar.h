//
//  LMBrowsingBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMLetterTabBar.h"
#import "LMSearchBar.h"

@interface LMBrowsingBar : LMView

/**
 The delegate for the letter tab bar.
 */
@property id<LMLetterTabDelegate> letterTabDelegate;

/**
 The delegate for the search bar.
 */
@property id<LMSearchBarDelegate> searchBarDelegate;

/**
 The letter tab bar for browsing through letters.
 */
@property LMLetterTabBar *letterTabBar;

/**
 Whether or not the browsing bar is in search mode.
 */
@property BOOL isInSearchMode;

/**
 Whether or not the keyboard is currently showing.
 */
@property BOOL keyboardIsShowing;

/**
 Whether or not the letter tabs are showing. If NO, they will be covered by the search bar.
 */
@property BOOL showingLetterTabs;

@end
