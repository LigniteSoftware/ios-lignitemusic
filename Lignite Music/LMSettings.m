//
//  LMSettings.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/17/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSettings.h"

@implementation LMSettings

+ (BOOL)settingForKey:(NSString*)key defaultValue:(BOOL)defaultValue {
	BOOL settingEnabled = defaultValue;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:key]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] integerForKey:key];
	}
	
	return settingEnabled;
}

+ (BOOL)shouldShowStatusBar {
	return YES;
}

+ (BOOL)userHasOptedOutOfTracking {
	return [self settingForKey:LMSettingsKeyOptOutOfTracking defaultValue:NO];
}

+ (BOOL)scrollingText {
	return [self settingForKey:LMSettingsKeyScrollingText defaultValue:YES];
}

+ (BOOL)screenShouldTimeoutWhenNowPlayingIsOpen {
	return [self settingForKey:LMSettingsKeyDisableScreenTimeoutOnNowPlaying defaultValue:YES];
}

+ (BOOL)debugInitialisationSounds {
	return [self settingForKey:LMSettingsKeyInitialisationSounds defaultValue:YES];
}

+ (BOOL)quickLoad {
	return [self settingForKey:LMSettingsKeyQuickLoad defaultValue:NO];
}

@end
