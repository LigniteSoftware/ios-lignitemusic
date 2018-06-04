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
#define LMSettingsKeyScrollingText @"LMSettingsKeyScrollingText"
#define LMSettingsKeyDisableScreenTimeoutOnNowPlaying @"LMSettingsKeyDisableScreenTimeoutOnNowPlaying"
#define LMSettingsKeyDemoMode @"LMSettingsKeyDemoMode"
#define LMSettingsKeyArtistsFilteredForDemo @"LMSettingsKeyArtistsFilteredForDemo"
#define LMSettingsKeyInitialisationSounds @"LMSettingsKeyInitialisationSounds"
#define LMSettingsKeyQuickLoad @"LMSettingsKeyQuickLoad"

#define LMFeedbackKeyName @"LMFeedbackKeyName"
#define LMFeedbackKeyEmail @"LMFeedbackKeyEmail"
#define LMFeedbackKeyQuickSummary @"LMFeedbackKeyQuickSummary"
#define LMFeedbackKeyDetailedReport @"LMFeedbackKeyDetailedReport"

#define LMQuickLoadQueueLimit 25

/**
 Gets a boolean setting based on a certain setting key.

 @param key The setting key to get the setting for.
 @param defaultValue The default value of the setting, in case the user hasn't yet set it up.
 @return The setting's boolean value.
 */
+ (BOOL)settingForKey:(NSString*)key defaultValue:(BOOL)defaultValue;

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

/**
 Whether or not to allow scrolling text for longer pieces of text in now playing or mini player.

 @return YES for scrolling text, NO to disable.
 */
+ (BOOL)scrollingText;

/**
 Whether or not the device should let the system timeout the screen (as per their system setting) when the now playing screen is open. Default is NO, the screen should NOT timeout, the screen should stay on when now playing is open.

 @return YES if the screen should timeout, NO if it should stay awake for as long as now playing is open.
 */
+ (BOOL)screenShouldTimeoutWhenNowPlayingIsOpen;

/**
 Play sounds upon the initialisation of some elements.

 @return Whether or not to play sounds upon some elements initialisations.
 */
+ (BOOL)debugInitialisationSounds;

/**
 Whether or not to optimise the app's load for quick speeds. If YES, the queue will be truncated to 25 songs on each end to save some loading time. Other optimisations may be made as well.

 @return Whether or not to optimise the app for quick speeds.
 */
+ (BOOL)quickLoad;

@end
