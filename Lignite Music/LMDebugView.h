//
//  LMDebugView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMScrollView.h"

@interface LMDebugView : LMScrollView

/**
 The app debug info.

 @return App debug info.
 */
+ (NSString*)appDebugInfoString;

/**
 Gets the current version string of the app.

 @return The current version string.
 */
+ (NSString*)currentAppVersion;

@end
