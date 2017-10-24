//
//  LMSourceSelector.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMSource.h"
#import "LMView.h"

@interface LMSourceSelectorView : LMView

/**
 The array of sources to expose to the user.
 */
@property NSArray<LMSource*> *sources;

/**
 Whether or not this source selector is the main one which goes in the button bar. Default is NO. If YES, the source selector will save to storage and remember its place for future use.
 */
@property BOOL mainSourceSelector;

/**
 Setup the source selector and its constraints.
 */
- (void)setup;

/**
 Set the currently selected source at a selected index.

 @param index The index to set.
 */
- (void)setCurrentSourceWithIndex:(NSInteger)index;

@end
