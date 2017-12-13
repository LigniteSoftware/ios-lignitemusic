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
	else if([key isEqualToString:LMThemeKeyRoyallyBlued]){
		return LMThemeRoyallyBlued;
	}
	else if([key isEqualToString:LMThemeKeyBombasticBlue]){
		return LMThemeBombasticBlue;
	}
	else if([key isEqualToString:LMThemeKeyMorpheus]){
		return LMThemeMorpheus;
	}
	else if([key isEqualToString:LMThemeKeyBackgroundNoise]){
		return LMThemeBackgroundNoise;
	}
	else if([key isEqualToString:LMThemeKeyBritishRacingGreen]){
		return LMThemeBritishRacingGreen;
	}
	
	return LMThemeDefault;
}

- (NSString*)keyForTheme:(LMTheme)theme {
	switch(theme){
		case LMThemeDefault:
			return LMThemeKeyDefault;
		case LMThemeRoyallyBlued:
			return LMThemeKeyRoyallyBlued;
		case LMThemeBombasticBlue:
			return LMThemeKeyBombasticBlue;
		case LMThemeMorpheus:
			return LMThemeKeyMorpheus;
		case LMThemeBackgroundNoise:
			return LMThemeKeyBackgroundNoise;
		case LMThemeBritishRacingGreen:
			return LMThemeKeyBritishRacingGreen;
	}
}

+ (NSString*)mainColourHexStringForTheme:(LMTheme)theme {
	switch(theme){
		case LMThemeDefault:
			return @"E82824";
		case LMThemeRoyallyBlued:
			return @"4169E1";
		case LMThemeBombasticBlue:
			return @"001DBD";
		case LMThemeMorpheus:
			return @"27911A";
		case LMThemeBackgroundNoise:
			return @"399DC6";
		case LMThemeBritishRacingGreen:
			return @"004225";
	}
}

+ (LMColour*)mainColourForTheme:(LMTheme)theme {
	return [LMColour colourWithHexString:[LMThemeEngine mainColourHexStringForTheme:theme]];
}

+ (LMTheme)currentTheme {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	LMTheme userTheme = LMThemeDefault;
	
	NSString *savedThemeKey = [userDefaults objectForKey:LMThemeEngineUserThemeKey];
	if(savedThemeKey){
		userTheme = [self themeForKey:savedThemeKey];
	}
	
	return userTheme;
}

+ (LMColour*)mainColour {
	LMTheme theme = [LMThemeEngine currentTheme];

	return [LMColour colourWithHexString:[LMThemeEngine mainColourHexStringForTheme:theme]];
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
