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
 Whether to hide the box when it's first being layed out or not.
 */
@property BOOL hideOnLayout;

/**
 Hide the warning view.
 */
- (void)hide;

/**
 Shows the warning view.
 */
- (void)show;

@end
