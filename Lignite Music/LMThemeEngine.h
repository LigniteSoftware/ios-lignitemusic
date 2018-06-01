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
	LMThemeBritishRacingGreen = 5, //A dark shade of green by thomas.kupper@gmail.com.,
	LMThemeDVaPink = 6 //A nice pink based on the Overwatch character, by Josh Arnott.
};

#define LMThemeKeyDefault @"LMThemeKeyDefault"
#define LMThemeKeyRoyallyBlued @"LMThemeKeyRoyallyBlued"
#define LMThemeKeyBombasticBlue @"LMThemeKeyBombasticBlue"
#define LMThemeKeyMorpheus @"LMThemeKeyMorpheus"
#define LMThemeKeyBackgroundNoise @"LMThemeKeyBackgroundNoise"
#define LMThemeKeyBritishRacingGreen @"LMThemeKeyBritishRacingGreen"
#define LMThemeKeyDVaPink @"LMThemeKeyDVaPink"

@protocol LMThemeEngineDelegate <NSObject>
@optional

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
 Selects the user's current theme & notifys delegates of the change.

 @param theme The new theme to select.
 */
- (void)selectTheme:(LMTheme)theme;

/**
 Gets the main colour of the theme. This should only be called from within LMColour.

 @return The theme's main colour.
 */
+ (LMColour * _Nonnull)mainColour;

/**
 Gets a main colour for a certain theme.

 @param theme The theme to get the main colour for.
 @return The colour.
 */
+ (LMColour * _Nonnull)mainColourForTheme:(LMTheme)theme;

/**
 Returns the hex string associated with a certain theme's main colour. String does not contain a hashtag.

 @param theme The theme to get the hex string for.
 @return The hex string, without a hashtag.
 */
+ (NSString * _Nonnull)mainColourHexStringForTheme:(LMTheme)theme;

/**
 Gets a key for a theme. The key is used for identifiers such as images or strings.

 @param theme The theme to get the key for.
 @return The key.
 */
- (NSString * _Nonnull)keyForTheme:(LMTheme)theme;

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
