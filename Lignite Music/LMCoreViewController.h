//
//  LMCoreViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LMBrowsingDetailViewController;

@interface LMCoreViewController : UIViewController

@property LMBrowsingDetailViewController *currentDetailViewController;

@property UINavigationBar *navigationBar;

- (void)prepareToLoadView;

/**
 Set the status bar blur as hidden or not.

 @param hidden Whether or not to hide the status bar blur.
 */
- (void)setStatusBarBlurHidden:(BOOL)hidden;

/**
 Pushes an item onto the navigation bar with a certain title.

 @param title The title that will be pushed.
 @param nowPlayingButton Whether or not the now playing button should display.
 */
- (void)pushItemOntoNavigationBarWithTitle:(NSString*)title withNowPlayingButton:(BOOL)nowPlayingButton;

@end
