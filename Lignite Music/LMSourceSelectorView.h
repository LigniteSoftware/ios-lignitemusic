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
 The constraint which associates this view with the bottom of the screen. Used for animating.
 */
@property NSLayoutConstraint *bottomConstraint;

- (void)setup;

@end
