//
//  LMBrowsingAssistantView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMSource.h"
#import "LMView.h"
#import "LMBrowsingBar.h"
#import "LMExtras.h"

//#define TAB_HEIGHT 0
#define TAB_HEIGHT (((WINDOW_FRAME.size.height/25.0)/4.0)*4.0)

/**
 Dynamic height for the browsing assistant where the height is being actively changed by the user through the view's pan gesture. Views should adjust to show the whole view to prevent being shown as cut off.

 @return A value below 0, indicating a dynamic height is required.
 */
#define LMBrowsingAssistantViewDynamicHeight -1.0

@class LMBrowsingAssistantView;

@protocol LMBrowsingAssistantDelegate <NSObject>

/**
 The height for the browsing view changed to a specific height. The delegate, which should be its superview, should now animate the browsing view down to the requested size.

 @param heightRequired The new height required.
 @param browsingView The browsing view which is notifying of the height requirement.
 */
- (void)heightRequiredChangedTo:(CGFloat)heightRequired forBrowsingView:(LMBrowsingAssistantView*)browsingView;

@end

typedef enum {
	LMBrowsingAssistantTabBrowse = 0,
	LMBrowsingAssistantTabMiniplayer,
	LMBrowsingAssistantTabView
} LMBrowsingAssistantTab;

@interface LMBrowsingAssistantView : LMView

@property id<LMBrowsingAssistantDelegate> delegate;

/**
 The view controller which controls this browsing assistant view.
 */
@property LMCoreViewController *coreViewController;

/**
 The text background constraint.
 */
@property NSLayoutConstraint *textBackgroundConstraint;

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
 Close the browsing assistant.
 
 @return If it was automatically closed. NO if it was already closed.
 */
- (BOOL)close;

/**
 Open the browsing assistant.
 
 @return If it was automatically opened. NO if it was already open.
 */
- (BOOL)open;

/**
 Close the source selector.
 
 @param openPreviousTab Whether or not to open the previous tab.
 */
- (void)closeSourceSelectorAndOpenPreviousTab:(BOOL)openPreviousTab;

/**
 Open the source selector.
 */
- (void)openSourceSelector;

/**
 Set the icon of the current source.

 @param icon The icon of the current
 */
- (void)setCurrentSourceIcon:(UIImage*)icon;

/**
 Select a source.

 @param sourceSelectedIndex The source to select.
 */
- (void)selectSource:(LMBrowsingAssistantTab)sourceSelectedIndex;

@end
