//
//  LMThemeEngine.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMColour.h"


#define LMThemeEngineUserThemeKey @"LMThemeEngineUserThemeKey"


typedef NS_ENUM(NSInteger, LMTheme) {
	LMThemeDefault = 0, //Classic "Lignite Red".
	LMThemeRoyallyBlued = 1, //A dark blue colour by peddledave@gmail.com.
	LMThemeBombasticBlue = 2, //A dark shade of blue by nbomba@nycap.rr.com.
	LMThemeMorpheus = 3, //An "in the middle" shade of green from The Matrix by regester8@hotmail.com.
	LMThemeBackgroundNoise = 4, //A shade of teal by amslerd@sympatico.ca.
	LMThemeBritishRacingGreen = 5 //A dark shade of green by thomas.kupper@gmail.com.
};

#define LMThemeKeyDefault @"LMThemeKeyDefault"
#define LMThemeKeyRoyallyBlued @"LMThemeKeyRoyallyBlued"
#define LMThemeKeyBombasticBlue @"LMThemeKeyBombasticBlue"
#define LMThemeKeyMorpheus @"LMThemeKeyMorpheus"
#define LMThemeKeyBackgroundNoise @"LMThemeKeyBackgroundNoise"
#define LMThemeKeyBritishRacingGreen @"LMThemeKeyBritishRacingGreen"


@protocol LMThemeEngineDelegate <NSObject>

/**
 The user changed their theme.

 @param theme The new theme.
 */
- (void)themeChanged:(LMTheme)theme;

@end


@interface LMThemeEngine : NSObject

/**
 Gets the current theme selected by the user. Default is LMThemeDefault (Lignite Red).

 @return The theme.
 */
+ (LMTheme)currentTheme;

/**
 Gets the main colour of the theme. This should only be called from within LMColour.

 @return The theme's main colour.
 */
+ (LMColour * _Nonnull)mainColour;

/**
 Adds a delegate to the theme engines's list of delegates.
 
 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMThemeEngineDelegate> _Nonnull)delegate;

/**
 Removes a delegate from the theme engines's list of delegates.
 
 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMThemeEngineDelegate> _Nonnull)delegate;

/**
 The theme engine which is shared across the app.
 
 @return The theme engine.
 */
+ (LMThemeEngine * _Nonnull)sharedThemeEngine;


@end
