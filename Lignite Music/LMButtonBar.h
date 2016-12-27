//
//  LMButtonBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@class LMButtonBar;

@protocol LMButtonBarDelegate <NSObject>

/**
 A button was tapped on the button bar with a certain index. The index starts at 0 on the left and increments by 1 for each button.

 @param index The index which was tapped.
 @param buttonBar The button bar which the button was tapped for.
 */
- (void)tappedButtonBarButtonAtIndex:(NSUInteger)index forButtonBar:(LMButtonBar*)buttonBar;

@end

@interface LMButtonBar : LMView

/**
 The amount of buttons for this view.
 */
@property NSUInteger amountOfButtons;

/**
 The array of button icon resources (LMIcon types).
 */
@property NSArray<NSNumber*> *buttonIconsArray;

/**
 The array of button scale factors to use.
 */
@property NSArray<NSNumber*> *buttonScaleFactorsArray;

/**
 The array of button icon indexes to invert the icons for on load.
 */
@property NSArray<NSNumber*> *buttonIconsToInvertArray;

/**
 The delegate for button tap events.
 */
@property id<LMButtonBarDelegate> delegate;

/**
 Gets the view of a background of a button for a certain index.

 @param index The index of the background to get.
 @return The background view.
 */
- (UIView*)backgroundViewForIndex:(NSInteger)index;

/**
 Sets a button at a certain index as inverted.

 @param index The index of the button to apply the inverting on.
 @param highlighted Whether or not to highlight. YES is a white background colour.
 */
- (void)setButtonAtIndex:(NSInteger)index highlighted:(BOOL)highlight;

@end
