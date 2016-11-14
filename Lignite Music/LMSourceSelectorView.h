//
//  LMSourceSelector.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMSource.h"

@interface LMSourceSelectorView : UIView

/**
 The array of sources to expose to the user.
 */
@property NSArray<LMSource*> *sources;

/**
 Setup the source selector and its constraints.
 */
- (void)setup;

/**
 Set the source selector's title, which is the bottom left (bolder) text.

 @param title The new title to set.
 */
- (void)setSourceTitle:(NSString*)title;

/**
 Set the source selector's subtitle, which is the bottom right (less bold) text.

 @param subtitle The new subtitle to set.
 */
- (void)setSourceSubtitle:(NSString*)subtitle;

/**
 Set the currently selected source at a selected index.

 @param index The index to set.
 */
- (void)setCurrentSourceWithIndex:(NSInteger)index;

@end
