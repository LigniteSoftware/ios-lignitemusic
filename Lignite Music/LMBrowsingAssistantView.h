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

@interface LMBrowsingAssistantView : UIView

@property LMCoreViewController *coreViewController;
@property NSLayoutConstraint *textBackgroundConstraint;

@property NSArray<LMSource*>* sourcesForSourceSelector;

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

@end
