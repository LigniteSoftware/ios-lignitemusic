//
//  LMSettings.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/17/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMSettings : NSUserDefaults

#define LMSettingsKeyLastOpenedSource @"LMSettingsKeyLastOpenedSource"
#define LMSettingsKeyOnboardingComplete @"LMSettingsKeyOnboardingComplete"
#define LMSettingsKeyStatusBar @"LMSettingsKeyStatusBar"
#define LMSettingsKeyHighQualityImages @"LMSettingsKeyHighQualityImages"

/**
 Whether or not the app should show the status bar.

 @return The BOOL of whether or not to show it.
 */
+ (BOOL)shouldShowStatusBar;

@end
