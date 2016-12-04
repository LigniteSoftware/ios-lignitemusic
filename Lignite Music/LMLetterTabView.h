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
 */
- (void)letterSelected:(NSString*)letter;

@end

typedef enum {
	LMLetterTabLiftAnimationStyleNoLift,
	LMLetterTabLiftAnimationStyleLiftUp,
	LMLetterTabLiftAnimationStyleBounce
} LMLetterTabLiftAnimationStyle;

@interface LMLetterTabView : LMView

/**
 The letters which should be available for browsing.
 */
@property NSArray *lettersArray;

/**
 The delegate for this view.
 */
@property id<LMLetterTabDelegate> delegate;

@end
