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
	BOOL settingEnabled = YES;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults objectForKey:LMSettingsKeyStatusBar]){
		settingEnabled = [[NSUserDefaults standardUserDefaults] integerForKey:LMSettingsKeyStatusBar];
	}
	
	return settingEnabled;
}

@end
