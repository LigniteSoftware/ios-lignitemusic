//
//  LMProgressSlider.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

@protocol LMProgressSliderDelegate <NSObject>

/**
 The value of the progress slider changed.

 @param newValue The new value of the slider.
 @param isFinal Whether or not the change is final (if so, things like song placement should be changed).
 */
- (void)progressSliderValueChanged:(CGFloat)newValue isFinal:(BOOL)isFinal;

@end

@interface LMProgressSlider : LMView

/**
 The background to the slider.
 */
@property UIView *sliderBackgroundView;

/**
 The text that goes on the left.
 */
@property NSString *leftText;

/**
 The text that goes on the right.
 */
@property NSString *rightText;

/**
 Whether or not the text should be in a light theme (light theme is black on the bottom and white on top of the sliderBackgroundView).
 */
@property BOOL lightTheme;

/**
 The current value the slider should have.
 */
@property CGFloat value;

/**
 The final value of the slider.
 */
@property CGFloat finalValue;

/**
 Whether or not the user is interacting with the slider.
 */
@property BOOL userIsInteracting;

/**
 The delegate for this view which will get updates on progress slider changes.
 */
@property id<LMProgressSliderDelegate> delegate;

/**
 Resets the progress slider to 0.
 */
- (void)reset;

@end
