//
//  LMControlBarView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

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
 @param wasJustTapped Whether or not when this function was called is right after the button was tapped. If NO, the control bar is simply asking whether or not it should mark itself highlighted for UI purposes.
 @param controlBar The control bar which had its button tapped.
 @return Whether or not the button that was tapped should mark itself as highlighted.
 */
- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView*)controlBar;

@end

@interface LMControlBarView : LMView

/**
 The delegate for this control bar.
 */
@property id<LMControlBarViewDelegate> delegate;

@property BOOL verticalMode;

@property NSInteger index;

/**
 Reload the highlighted buttons statuses.
 */
- (void)reloadHighlightedButtons;

/**
 Simulate a tap at a certain index.

 @param index The index to simulate the tap of.
 */
- (void)simulateTapAtIndex:(uint8_t)index;

@end
