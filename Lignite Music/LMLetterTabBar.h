//
//  LMLetterTabView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@protocol LMLetterTabDelegate <NSObject>

/**
 A letter was selected.

 @param letter The letter selected.
 @param index The index of the letter within the current view's subview array, relative to the music collection.
 */
- (void)letterSelected:(NSString*)letter atIndex:(NSUInteger)index;

@optional

/**
 The swipe down gesture happened.
 */
- (void)swipeDownGestureOccurredOnLetterTabBar DEPRECATED_ATTRIBUTE;

@end

typedef enum {
	LMLetterTabLiftAnimationStyleNoLift,
	LMLetterTabLiftAnimationStyleLiftUp,
	LMLetterTabLiftAnimationStyleBounce
} LMLetterTabLiftAnimationStyle;

@interface LMLetterTabBar : LMView

/**
 The letters which should be available for browsing along with their indexes.
 */
@property NSDictionary *lettersDictionary;

/**
 The delegate for this view.
 */
@property id<LMLetterTabDelegate> delegate;

/**
 Reloads the layout.
 */
- (void)reloadLayout;

@end
