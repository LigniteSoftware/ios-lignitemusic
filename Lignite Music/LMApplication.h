//
//  LMApplication.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/5/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"

@protocol LMApplicationIdleDelegate <NSObject>

/**
 The application is now idle, due to the user's lack of activity.
 */
- (void)userInteractionBecameIdle;

@end

@interface LMApplication : UIApplication

/**
 The app's core view controller.
 */
@property LMCoreViewController *coreViewController;

/**
 Removes a delegate from the application's list of delegates.
 
 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMApplicationIdleDelegate>)delegate;

/**
 Removes a delegate from the application's list of delegates.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMApplicationIdleDelegate>)delegate;

@end
