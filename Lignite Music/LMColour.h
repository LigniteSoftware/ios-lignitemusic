//
//  LMColour.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/8/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LMColour : UIColor

/**
 The main theme colour, selected by the user. See LMThemeEngine for more details.

 @return The main theme colour.
 */
+ (UIColor*)mainColour;

/**
 The main theme colour with brightness reduced.
 
 @return The darkened main theme colour.
 */
+ (UIColor*)mainColourDark;

/**
 Gets a colour from a HEX string of 3, 4, 6 or 8 characters. Throws an exception if an invalid string is inputted.

 @param hexString The HEX string to get the colour from.
 @return The colour.
 */
+ (LMColour*)colourWithHexString:(NSString*)hexString;

/**
 A darker green colour idicating success or action of positivity.

 @return Success green colour.
 */
+ (UIColor*)successGreenColour;

/**
 A super duper light gray colour. Used in section table views.

 @return The super light gray.
 */
+ (UIColor*)superLightGreyColour;

/**
 The light gray for the control bar in detail view.
 
 @return The light gray.
 */
+ (UIColor*)controlBarGreyColour;

/**
 The vertical control bar gray colour for when the control bar is used in landscape phone mode. God I hate all of these special views.

 @return The darker control bar gray colour.
 */
+ (UIColor*)verticalControlBarGreyColour;

/**
 A 35% transparent white which is the background to the circular cover art, for example.

 @return The 35% transparent white.
 */
+ (UIColor*)fadedColour;

/**
 The light gray background colour that is used in the LMControlBarView.

 @return The light gray.
 */
+ (UIColor*)lightGreyBackgroundColour;

/**
 The dark gray colour currently used within the search bar.

 @return The dark gray.
 */
+ (UIColor*)darkGreyColour;

/**
 The super dark gray colour currently used within the rewritten control bar.
 
 @return The super dark gray.
 */
+ (UIColor*)superDarkGreyColour;

/**
 Generate a completely random colour. Used for testing purposes.

 @return The random colour.
 */
+ (UIColor*)randomColour;

/**
 #FFFFFF.

 @return White.
 */
+ (LMColour*)whiteColour;

/**
 #000000.
 
 @return Black.
 */
+ (LMColour*)blackColour;

/**
 Clear colour, 100% transparency. In both ways unlike Ajit Pai.

 @return The clear colour.
 */
+ (LMColour*)clearColour;

/**
 Fetches a colour with different RGBA values.

 @param red Red value, from 0.0 to 1.0.
 @param green Green value, from 0.0 to 1.0.
 @param blue Blue value, from 0.0 to 1.0.
 @param alpha Alpha/transparency value, from 0.0 to 1.0.
 @return The colour.
 */
+ (LMColour*)colourWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

@end
