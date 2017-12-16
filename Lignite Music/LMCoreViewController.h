//
//  LMCoreViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "LMButtonNavigationBar.h"
#import "LMLandscapeNavigationBar.h"
#import "LMCoreNavigationController.h"

@interface LMCoreViewController : UIViewController

@property LMLandscapeNavigationBar *landscapeNavigationBar;

@property MBProgressHUD *loadingProgressHUD;

@property UINavigationItem *itemPopped;


/**
 The state preserved had the settings already open. Completely hide navigation bar and push settings navigation bar item onto stack when view loads if YES.
 */
@property BOOL statePreservedSettingsAlreadyOpen;

- (void)prepareForOpenSettings;

- (void)panNowPlayingUp:(UIPanGestureRecognizer *)recognizer;

/**
 The navigation bar that goes at the bottom.
 */
@property LMButtonNavigationBar *buttonNavigationBar;

- (void)prepareToLoadView;

@end
