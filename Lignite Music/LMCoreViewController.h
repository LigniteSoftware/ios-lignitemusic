//
//  LMCoreViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCompactBrowsingView.h"
#import "LMButtonNavigationBar.h"
#import "LMLandscapeNavigationBar.h"
#import "LMCoreNavigationController.h"
#import "LMPlaylistEditorViewController.h"

typedef NS_ENUM(NSInteger, LMCoreViewControllerRestorationState){
	LMCoreViewControllerRestorationStateNotRestored = 0,
	LMCoreViewControllerRestorationStateBrowsing,
	LMCoreViewControllerRestorationStateNowPlaying,
	LMCoreViewControllerRestorationStateOutOfView
};

@interface LMCoreViewController : UIViewController

/**
 Handles the logic for the gesture associated with the now playing view.

 @param recognizer The gesture recognizer.
 */
- (void)panNowPlayingUp:(UIPanGestureRecognizer *)recognizer;

/**
 Prepares the core view controller for loading.
 */
- (void)prepareToLoadView;

/**
 The navigation bar that goes at the bottom.
 */
@property LMButtonNavigationBar *buttonNavigationBar;

/**
 The landscape navigation bar for landscape mode.
 */
@property LMLandscapeNavigationBar *landscapeNavigationBar;

/**
 The compact/main browsing view.
 */
@property LMCompactBrowsingView *compactView;

/**
 If state restoration contains a playlist editor, that playlist editor will sit here pending for an attachment to compactView (which will have to be created).
 */
@property LMPlaylistEditorViewController *pendingStateRestoredPlaylistEditor;

@end
