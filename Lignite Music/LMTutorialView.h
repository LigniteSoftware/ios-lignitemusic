//
//  LMTutorialView.h
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-27.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"

#define LMTutorialKeyBottomNavigation @"LMTutorialKeyBottomNavigation"
#define LMTutorialKeyMiniPlayer @"LMTutorialKeyMiniPlayer"
#define LMTutorialKeyTopBar @"LMTutorialKeyTopBar"
#define LMTutorialKeyNowPlaying @"LMTutorialKeyNowPlaying"

@interface LMTutorialView : LMView

typedef enum {
    LMTutorialViewAlignmentTop = 0,
    LMTutorialViewAlignmentCenter,
    LMTutorialViewAlignmentBottom
} LMTutorialContentViewAlignment;

/**
 Initialize a tutorial view with default values of centered boxAlignment and arrowAlignment, a nil icon, and a function-set title and description.

 @param title The title to set.
 @param description The description to set.
 @return The initialized tutorial view.
 */
- (instancetype)initForAutoLayoutWithTitle:(NSString*)title description:(NSString*)description;

/**
 Returns whether or not a part of the tutorial should run for a certain key. Will always return NO if the user completely disables tutorials, for example.

 @param tutorialKey The key of the tutorial part to check.
 @return Whether or not to attach that tutorial to a view and run it.
 */
- (BOOL)tutorialShouldRunForKey:(NSString*)tutorialKey;

/**
 The alignment of the actual content box.
 */
@property LMTutorialContentViewAlignment boxAlignment;

/**
 The alignment of the arrow to go on the top or bottom of the content box. Default is center, which displays no arrows. Unless we figure out a way to turn a 2D space 3D.
 */
@property LMTutorialContentViewAlignment arrowAlignment;

/**
 The image for the icon to display, if an icon is wanted. Otherwise, the view will auto adapt without an icon.
 */
@property UIImage *icon;

@end
