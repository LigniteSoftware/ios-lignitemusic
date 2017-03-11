//
//  LMColour.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/8/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMColour : NSObject

/**
 The classic "Lignite Red" colour. It's a slightly darker red, just the right amount. Not harsh on the eyes and not evil :)

 @return The Lignite Red colour.
 */
+ (UIColor*)ligniteRedColour;

/**
 The classic "Lignite Red" colour, though half transparent.

 @return The semi transparent Lignite Red colour.
 */
+ (UIColor*)semiTransparentLigniteRedColour;

/**
 Dark Lignite Red colour is basically a brown colour. It should be used for denying related tasks.

 @return The dark Lignite Red colour.
 */
+ (UIColor*)darkLigniteRedColour;

/**
 A super duper light gray colour. Used in section table views.

 @return The super light gray.
 */
+ (UIColor*)superLightGrayColour;

/**
 A 35% transparent white which is the background to the circular cover art, for example.

 @return The 35% transparent white.
 */
+ (UIColor*)fadedColour;

/**
 The light gray background colour that is used in the LMControlBarView.

 @return The light gray.
 */
+ (UIColor*)lightGrayBackgroundColour;

/**
 The dark gray colour currently used within the search bar.

 @return The dark gray.
 */
+ (UIColor*)darkGrayColour;

/**
 The super dark gray colour currently used within the rewritten control bar.
 
 @return The super dark gray.
 */
+ (UIColor*)superDarkGrayColour;

/**
 Generate a completely random colour. Used for testing purposes.

 @return The random colour.
 */
+ (UIColor*)randomColour;

@end
