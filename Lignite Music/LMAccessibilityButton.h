//
//  LMAccessibilityButton.h
//  Lignite Music
//
//  Created by Edwin Finch on 3/16/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"

@class LMAccessibilityButton;

@protocol LMAccessibilityButtonDelegate <NSObject>
@required

/**
 An accessibility button was tapped upon.

 @param accessibilityButton The accessibility button that was tapped.
 */
- (void)accessibilityButtonTapped:(LMAccessibilityButton*)accessibilityButton;

@end

@interface LMAccessibilityButton : LMView

/**
 The button's delegate.
 */
@property id<LMAccessibilityButtonDelegate> delegate;

/**
 The icon that goes on the button itself.
 */
@property UIImage *icon;

@end
