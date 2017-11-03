//
//  LMBoxWarningView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/31/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"

@interface LMBoxWarningView : LMView

/**
 The constraint which pins this box warning view to the top of something else. Used for hiding the warning view.
 */
@property NSLayoutConstraint *topToSuperviewConstraint;

/**
 The title's label.
 */
@property UILabel *titleLabel;

/**
 The subtitle's label.
 */
@property UILabel *subtitleLabel;

/**
 Whether or not the warning view is showing.
 */
@property BOOL showing;

/**
 Hide the warning view.
 */
- (void)hide;

/**
 Shows the warning view.
 */
- (void)show;

@end
