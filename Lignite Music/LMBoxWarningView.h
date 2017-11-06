//
//  LMBoxWarningView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/31/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"

@class LMBoxWarningView;

@protocol LMBoxWarningViewDelegate<NSObject>

/**
 The user tapped the X on the box warning view, force closing it.

 @param boxWarningView The box warning view that was forced close.
 */
- (void)boxWarningViewWasForceClosed:(LMBoxWarningView*)boxWarningView;

@end

@interface LMBoxWarningView : LMView

/**
 The delegate.
 */
@property id<LMBoxWarningViewDelegate> delegate;

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
