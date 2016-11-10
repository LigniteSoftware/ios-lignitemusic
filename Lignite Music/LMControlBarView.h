//
//  LMControlBarView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMControlBarView;

@protocol LMControlBarViewDelegate <NSObject>

/**
 Return the amount of buttons which are required for this control bar.

 @param controlBar The control bar which is asking for the amount.
 @return The amount of buttons that should be applied to this control bar.
 */
- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView*)controlBar;

/**
 Return the image associated with a certain index for a button within the given control bar.

 @param index The index of the image which is being asked for relative to the button in the control bar.
 @param controlBar The control bar which is asking for the image.
 @return The image.
 */
- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar;

/**
 A button at a certain index was tapped on the control bar.

 @param index The index of the button which was tapped, relative to the control bar.
 @param controlBar The control bar which had its button tapped.
 @return Whether or not the button that was tapped should mark itself as highlighted.
 */
- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView*)controlBar;

@optional //Optional because delegates of delegates will not implement this function. The first layer should always implement so as to not run into errors.

/**
 The size of the control bar view changed. This means it either expanded or shrunk.

 @param newSize The new size of the control bar in pixels.
 @param controlBar The control bar which changed.
 */
- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView*)controlBar;

@end

@interface LMControlBarView : UIView

/**
 The delegate for this control bar.
 */
@property id<LMControlBarViewDelegate> delegate;

@property NSInteger index;

+ (float)heightWhenIsOpened:(BOOL)isOpened;

/**
 Whether or not the control bar is open.
 */
@property BOOL isOpen;

/**
 Open the control bar. Increases the height to one eighth the window's height.
 
 @param animated Whether or not to animate the change. NO should be entered if view is off-screen.
 */
- (void)open:(BOOL)animated;

/**
 Close the control bar. Decreases the height to 0.
 
 @param animated Whether or not to animate the change. NO should be entered if view is off-screen.
 */
- (void)close:(BOOL)animated;

/**
 Invert the state of the control bar automatically. If opened, will close. If closed, will open.
 
 @param animated Whether or not to animate the change. NO should be entered if view is off-screen.
 */
- (void)invert:(BOOL)animated;

/**
 Setup the control bar view.
 */
- (void)setup;

@end
