//
//  LMBrowsingAssistantView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMCoreViewController.h"

@interface LMBrowsingAssistantView : UIView

@property LMCoreViewController *coreViewController;
@property LMMusicPlayer *musicPlayer;
@property NSLayoutConstraint *textBackgroundConstraint;

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

@end
