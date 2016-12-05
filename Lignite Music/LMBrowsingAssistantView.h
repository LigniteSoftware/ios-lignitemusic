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

@class LMBrowsingAssistantView;

@protocol LMBrowsingAssistantDelegate <NSObject>

/**
 The height for the browsing view changed to a specific height. The delegate, which should be its superview, should now animate the browsing view down to the requested size.

 @param heightRequired The new height required.
 @param browsingView The browsing view which is notifying of the height requirement.
 */
- (void)heightRequiredChangedTo:(float)heightRequired forBrowsingView:(LMBrowsingAssistantView*)browsingView;

@end

typedef enum {
	LMBrowsingAssistantTabBrowse = 0,
	LMBrowsingAssistantTabMiniplayer,
	LMBrowsingAssistantTabView
} LMBrowsingAssistantTab;

@interface LMBrowsingAssistantView : UIView

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
 Setup the browsing assistant.
 */
- (void)setup;

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
 */
- (void)closeSourceSelector;

/**
 Open the source selector.
 */
- (void)openSourceSelector;

/**
 Set the icon of the current source.

 @param icon The icon of the current
 */
- (void)setCurrentSourceIcon:(UIImage*)icon;

@end
