//
//  LMDebugViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMDebugViewController : UIViewController

/**
 The current app version.

 @return The app version string.
 */
+ (NSString*)currentAppVersion;

/**
 Gets the current app build number.

 @return The build number.
 */
+ (NSString*)buildNumberString;

/**
 The debug string for the app's internal info.

 @return The debug string.
 */
+ (NSString*)appDebugInfoString;

@end
