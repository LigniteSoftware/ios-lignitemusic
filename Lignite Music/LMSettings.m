//
//  LMSettings.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/17/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSettings.h"

@implementation LMSettings

+ (BOOL)shouldShowStatusBar {
	return YES;
	
	BOOL settingEnabled = YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyStatusBar]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] integerForKey:LMSettingsKeyStatusBar];
	}
	
	return settingEnabled;
}

+ (BOOL)userHasOptedOutOfTracking {
	BOOL settingEnabled = NO;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyOptOutOfTracking]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] integerForKey:LMSettingsKeyOptOutOfTracking];
	}
	
	return settingEnabled;
}

+ (BOOL)scrollingText {
	BOOL settingEnabled = YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyScrollingText]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyScrollingText];
	}
	
	return settingEnabled;
}

+ (BOOL)screenShouldTimeoutWhenNowPlayingIsOpen {
	BOOL settingEnabled = NO;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyDisableScreenTimeoutOnNowPlaying]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:LMSettingsKeyDisableScreenTimeoutOnNowPlaying];
	}
	
	return !settingEnabled;
}

@end
