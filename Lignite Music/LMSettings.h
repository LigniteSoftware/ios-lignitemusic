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
#define LMSettingsKeyOptOutOfTracking @"LMSettingsKeyOptOutOfTracking"

#define LMFeedbackKeyName @"LMFeedbackKeyName"
#define LMFeedbackKeyEmail @"LMFeedbackKeyEmail"
#define LMFeedbackKeyQuickSummary @"LMFeedbackKeyQuickSummary"
#define LMFeedbackKeyDetailedReport @"LMFeedbackKeyDetailedReport"

/**
 Whether or not the app should show the status bar.

 @return Whether or not to show it.
 */
+ (BOOL)shouldShowStatusBar;

/**
 Whether or not the user has opted out of analytics tracking.

 @return Whether or not the user has opted out.
 */
+ (BOOL)userHasOptedOutOfTracking;

@end
