//
//  LMWarningManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMWarningBarView.h"
#import "LMWarning.h"

@interface LMWarningManager : NSObject

/**
 The warning bar which displays the actual contents of the warnings.
 */
@property LMWarningBarView *warningBar;

/**
 Reloads the warning bar. This must be called after a warning's property is changed.
 */
- (void)reloadWarningBar;

/**
 Adds a warning to the warning manager. The warning manager may not display it right away, the priority of the warning is all that matters. If there's more than one severe warning (which I hope to god is never the case), the first added severe warning will be prioritized.

 @param warning The warning to add to the warning manager.
 */
- (void)addWarning:(LMWarning*)warning;

/**
 Removes a warning from the warning manager. The warning manager will take it out of the warnings queue, and if no more warnings are left, will automatically dismiss the warning bar.

 @param warning The warning to remove.
 */
- (void)removeWarning:(LMWarning*)warning;

/**
 Returns a singleton warning manager instance.

 @return The warning manager.
 */
+ (instancetype)sharedWarningManager;

@end
