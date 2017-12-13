//
//  LMThemeEngine.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMThemeEngine.h"

@interface LMThemeEngine()

/**
 The array of theme engine delegates.
 */
@property NSMutableArray *delegates;

@end

@implementation LMThemeEngine

- (void)selectTheme:(LMTheme)theme {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString *themeKey = [self keyForTheme:theme];
	[userDefaults setObject:themeKey forKey:LMThemeEngineUserThemeKey];

	for(id<LMThemeEngineDelegate> delegate in self.delegates){
		if([delegate respondsToSelector:@selector(themeChanged:)]){
			[delegate themeChanged:theme];
		}
	}
}

- (void)addDelegate:(id<LMThemeEngineDelegate> _Nonnull)delegate {
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<LMThemeEngineDelegate> _Nonnull)delegate {
	[self.delegates removeObject:delegate];
}

+ (LMTheme)themeForKey:(NSString*)key {
	if([key isEqualToString:LMThemeKeyDefault]){
		return LMThemeDefault;
	}
	else if([key isEqualToString:LMThemeKeyEdwinOrange]){
		return LMThemeEdwinOrange;
	}
	
	return LMThemeDefault;
}

- (NSString*)keyForTheme:(LMTheme)theme {
	switch(theme){
		case LMThemeDefault:
			return LMThemeKeyDefault;
		case LMThemeEdwinOrange:
			return LMThemeKeyEdwinOrange;
	}
}

+ (LMTheme)currentTheme {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	LMTheme userTheme = LMThemeEdwinOrange;
	
	NSString *savedThemeKey = [userDefaults objectForKey:LMThemeEngineUserThemeKey];
	if(savedThemeKey){
		userTheme = [self themeForKey:savedThemeKey];
	}
	
	return userTheme;
}

+ (LMColour*)mainColour {
	LMTheme theme = [LMThemeEngine currentTheme];

	switch(theme){
		case LMThemeDefault:
			return [LMColour colourWithRed:0.69 green:0.16 blue:0.15 alpha:1.0];
		case LMThemeEdwinOrange:
			return (LMColour*)[UIColor orangeColor];
	}
}

+ (LMThemeEngine * _Nonnull)sharedThemeEngine {
	static LMThemeEngine *sharedThemeEngine;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedThemeEngine = [self new];
		sharedThemeEngine.delegates = [NSMutableArray new];
	});
	return sharedThemeEngine;
}

@end
