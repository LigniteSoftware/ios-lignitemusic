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

- (void)openNowPlayingView;
- (void)closeNowPlayingView;
- (void)openBrowsingAssistant;
- (void)closeBrowsingAssistant;
- (void)prepareToLoadView;
- (void)setStatusBarBlurHidden:(BOOL)hidden;


@end
