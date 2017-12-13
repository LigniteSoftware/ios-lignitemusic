//
//  LMThemeView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/13/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMThemeEngine.h"

@class LMThemeView;

@protocol LMThemeViewDelegate <NSObject>

/**
 The theme view was tapped. The controller should now set the user's theme accordingly.

 @param themeView The theme view that was tapped.
 @param theme The new theme that has been selected.
 */
- (void)themeView:(LMThemeView*)themeView selectedTheme:(LMTheme)theme;

@end

@interface LMThemeView : LMView

/**
 The theme that theme view is displaying.
 */
@property LMTheme theme;

/**
 The key associated with this view's theme.
 */
@property (readonly) NSString *themeKey;

/**
 The delegate for when the theme view is tapped.
 */
@property id<LMThemeViewDelegate> delegate;

@end
