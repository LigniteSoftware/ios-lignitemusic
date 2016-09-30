//
//  LMAdaptiveScrollView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMAdaptiveScrollView;

@protocol LMAdaptiveScrollViewDelegate <NSObject>
@required


/**
 Is called when a subview has been prepared internally by the LMAdaptiveScrollView. Usually this delegate function is used to handle any other rendering or constraint management which would need to occur for the subview.

 @param subview   The subview to prepare.
 @param index     The index of that subview relative to the scroll view's collection of subviews.
 @param hasLoaded Whether or not this subview has been loaded upon by the scroll view before.
 */
- (void)prepareSubview:(id)subview forIndex:(NSUInteger)index subviewPreviouslyLoaded:(BOOL)hasLoaded;


/**
 Gets the sizing factorial of an item in the scroll view relative to the window. The scroll view will handle the rest of the calculations.

 @param scrollView The scroll view which requires the factorial.

 @return The factorial.
 */
- (float)sizingFactorialRelativeToWindowForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView height:(BOOL)height;


/**
 Gets the amount of spacing the scroll view should add to the top of of the subviews.

 @param scrollView The scroll view which wants the padding.

 @return The padding.
 */
- (float)topSpacingForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView;


/**
 Whether or not the system should add a divider at the bottom of the scroll view.

 @param scrollView The scroll view in question.

 @return Whether or not a divider should be added.
 */
- (BOOL)dividerForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView;

@end

@interface LMAdaptiveScrollView : UIScrollView

@property NSArray *subviewArray;
@property id subviewDelegate;

- (void)reloadContentSizeWithIndex:(NSUInteger)index;

@end
